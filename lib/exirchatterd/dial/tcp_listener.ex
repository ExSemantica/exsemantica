defmodule Exirchatterd.Dial.TcpListener do
  require Logger
  use GenServer

  @regex_nick ~r"[Nn][Ii][Cc][Kk]\ ([[:alnum:]]+)"
  @regex_user ~r"[Uu][Ss][Ee][Rr]\ ([[:alnum:]]+)\ [^ ]+ \*\ (\:[[:alnum:][:space:]]+)"
  @regex_quit ~r"[Qq][Uu][Ii][Tt]\ (:[[:alnum:][:space:]]+)"

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
       irc_statedata: []
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

        Logger.info("Peer connected [#{inspect(sock)} -> #{inspect(host)}]")
        Exirchatterd.Dial.DynamicSupervisor.spawn_connection(state.tcp_listen)
        {:noreply, %{state | irc_statedata: [hostent: host]}}

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

  # ============================================================================
  defp handle_irc(sock, data, state) do
    case state.irc_stateword do
      {:login, :nick} ->
        case Regex.run(@regex_nick, data) do
          [_root, nick] ->
            state_data = state.irc_statedata ++ [nick: nick]
            {:noreply, %{state | irc_statedata: state_data, irc_stateword: {:login, :user}}}

          _ ->
            {:noreply, state}
        end

      {:login, :user} ->
        case Regex.run(@regex_user, data) do
          [_root, ident, real_name] ->
            state_data = state.irc_statedata ++ [ident: ident, real_name: real_name]
            # Send 001 [RPL_WELCOME]
            :gen_tcp.send(
              sock,
              state_data
              |> Exirchatterd.CannedReplies.reply(1)
              |> Exirchatterd.IRCPacket.stringify()
            )

            # then 002 [RPL_YOURHOST]
            :gen_tcp.send(
              sock,
              state_data
              |> Exirchatterd.CannedReplies.reply(2)
              |> Exirchatterd.IRCPacket.stringify()
            )

            {:noreply, %{state | irc_statedata: state_data, irc_stateword: :ready}}

          _ ->
            {:noreply, state}
        end

      :ready ->
        case Regex.run(@regex_quit, data) do
          [_root, _reason] ->
            Logger.debug("IRC conn left due to client")
            {:stop, :normal, state}

          _ ->
            {:noreply, state}
        end
    end
  end
end
