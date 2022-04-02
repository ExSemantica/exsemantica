defmodule Exirchatterd.Dial.TcpListener do
  require Logger
  use GenServer

  @ping_thresh 120_000
  @regex_user ~r"[Uu][Ss][Ee][Rr]\ ([[:alnum:]]+)\ [^ ]+ \*\ (\:[[:alnum:][:space:]]+)"

  def start_link(listen) do
    GenServer.start_link(__MODULE__, listen)
  end

  @impl true
  def init(listen) do
    Process.send(self(), :poll, [])

    {:ok,
     %{
       tcp_listen: listen,
       irc_stateword: {:login, :nick},
       irc_statedata: %{nick: nil, ident: nil, real_name: nil},
       ping_timer: nil,
       ping_killer: nil
     }}
  end

  @impl true
  def handle_info(:poll, state) do
    Process.send(self(), :poll, [])

    case :gen_tcp.accept(state.tcp_listen, 100) do
      {:ok, sock} ->
        {:ok, {uaddr, _uport}} = :inet.peername(sock)

        host =
          case :inet.gethostbyaddr(uaddr) do
            {:ok, hostname} ->
              {:hostent, hname, _haliases, _haddrtype, _hlength, _haddrlist} = hostname
              to_string(hname)

            _ ->
              :inet.ntoa(uaddr)
          end

        Process.send_after(self(), {:init_kill, sock}, 15_000)
        Logger.debug("Peer connected [#{inspect(sock)} -> #{inspect(host)}]")
        Exirchatterd.Dial.DynamicSupervisor.spawn_connection(state.tcp_listen)
        {:noreply, %{state | irc_statedata: %{hostent: host}}}

      {:error, :timeout} ->
        {:noreply, state}

      reason ->
        Logger.warning("UNIMPLEMENTED TCP error #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:tcp, accept, data}, state) do
    handle_irc(accept, data, state)
  end

  @impl true
  def handle_info({:tcp_closed, _accept}, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({{:error, reason}, sock}, state) do
    case state.irc_stateword do
      :ready ->
        {:noreply, state}

      _ when reason === :login ->
        Logger.debug("Peer killed for not logging in on time [#{inspect(sock)}]")

        :gen_tcp.send(
          sock,
          "ERROR :You did not log in on time\r\n"
        )

        :gen_tcp.close(sock)

        {:stop, :normal, state}

      _ when reason === :ping ->
        Logger.debug("Peer killed for ping timeout [#{inspect(sock)}]")

        :gen_tcp.send(
          sock,
          "ERROR :Ping timeout\r\n"
        )

        :gen_tcp.close(sock)

        {:stop, :normal, state}
    end
  end

  @impl true
  def handle_info({:ping, sock}, state) do
    :gen_tcp.send(sock, "PING :" <> ExsemanticaWeb.Endpoint.struct_url()[:host])
    timer = Process.send_after(self(), {:ping, sock}, @ping_thresh)
    tkill = Process.send_after(self(), {{:error, :ping}, sock}, @ping_thresh + 15000)
    {:noreply, %{state | ping_timer: timer, ping_killer: tkill}}
  end

  defp handle_irc(sock, data, state) do
    irc_parse = IO.inspect(Exirchatterd.IRCPacket.encode(data))

    root = irc_parse.command

    case state.irc_stateword do
      :ready ->
        host = String.downcase(irc_parse.stem)
        this = String.downcase(ExsemanticaWeb.Endpoint.struct_url()[:host])

        case root do
          :pong when host == this ->
            case Process.read_timer(state.ping_killer) do
              false -> nil
              _ -> Process.cancel_timer(state.ping_killer)
            end

            case Process.read_timer(state.ping_timer) do
              false -> nil
              _ -> Process.cancel_timer(state.ping_timer)
            end

            Process.send(self(), {:ping, sock}, [])

          :ping when host == this ->
            :gen_tcp.send(
              sock,
              "PONG :#{this}\r\n"
            )
        end

      {:login, step} ->
        case step do
          :nick ->
            {:noreply,
             %{
               state
               | irc_statedata: %{state.irc_statedata | nick: hd(irc_parse.args_head)},
                 irc_stateword: {:login, :user}
             }}

          :user ->
            # Parsing the USER is a corner case, just use Regex.
            case Regex.run(@regex_user, data) do
              [_root, ident, real_name] ->
                state_data = %{state.irc_statedata | ident: ident, real_name: real_name}

                # Send 001 [RPL_WELCOME]
                :gen_tcp.send(
                  sock,
                  state_data
                  |> Exirchatterd.CannedReplies.reply(1)
                  |> Exirchatterd.IRCPacket.decode()
                )

                # then 002 [RPL_YOURHOST]
                :gen_tcp.send(
                  sock,
                  state_data
                  |> Exirchatterd.CannedReplies.reply(2)
                  |> Exirchatterd.IRCPacket.decode()
                )

                :gen_tcp.send(
                  sock,
                  state_data
                  |> Exirchatterd.CannedReplies.reply(375)
                  |> Exirchatterd.IRCPacket.decode()
                )

                for line <- Exirchatterd.MOTD.motd() |> String.split("\n") do
                  :gen_tcp.send(
                    sock,
                    state_data
                    |> Exirchatterd.CannedReplies.reply({372, line})
                    |> Exirchatterd.IRCPacket.decode()
                  )
                end

                :gen_tcp.send(
                  sock,
                  state_data
                  |> Exirchatterd.CannedReplies.reply(376)
                  |> Exirchatterd.IRCPacket.decode()
                )

                Process.send(self(), {:ping, sock}, [])

                {:noreply, %{state | irc_statedata: state_data, irc_stateword: :ready}}
            end

          _ ->
            {:noreply, state}
        end
    end
  end
end
