defmodule Exirchatterd.Dial.TcpListener do
  require Logger
  use GenServer

  @ping_thresh 120_000

  def start_link(listen) do
    GenServer.start_link(__MODULE__, listen)
  end

  @impl true
  def init(listen) do
    Process.send(self(), :poll, [])

    {:ok,
     %{
       tcp_listen: listen,
       irc_state: %{}
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

        # Process.send_after(self(), {:init_kill, sock}, 15_000)
        Exirchatterd.Dial.DynamicSupervisor.spawn_connection(state.tcp_listen)
        Logger.debug("User #{inspect(sock)} [#{inspect(host)}] joins :)")

        {:noreply,
         state
         |> put_in(~w(irc_state hostname)a, host)}

      {:error, :timeout} ->
        {:noreply, state}

      reason ->
        Logger.warning("UNIMPLEMENTED TCP error #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:ping, accept}, state) do
    :gen_tcp.send(
      accept,
      %Exirchatterd.IRCPacket{
        prefix: nil,
        command: :ping,
        args_head: [],
        args_tail: nil
      }
      |> Exirchatterd.IRCPacket.decode()
    )

    {:noreply,
     state
     |> put_in(
       ~w(irc_state ping_kill)a,
       Process.send_after(self(), {:ping_kill, accept}, 30_000)
     )}
  end

  @impl true
  def handle_info({:ping_kill, accept}, state) do
    t1 = DateTime.utc_now() |> DateTime.to_unix()
    t0 = state |> get_in(~w(irc_state ping?)a)

    :gen_tcp.send(
      accept,
      %Exirchatterd.IRCPacket{
        prefix: nil,
        command: :error,
        args_head: [],
        args_tail: "Ping timeout (#{t1 - t0} seconds)"
      }
      |> Exirchatterd.IRCPacket.decode()
    )

    :gen_tcp.close(accept)

    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:tcp, accept, data}, state) do
    Exirchatterd.IRCPacket.encode(data) |> handle_irc(accept, state)
  end

  @impl true
  def handle_info({:tcp_closed, _accept}, state) do
    {:stop, :normal, state}
  end

  # ============================================================================
  # Give me a nick
  defp handle_irc(
         %Exirchatterd.IRCPacket{
           prefix: _origin,
           command: :nick,
           args_head: [nick],
           args_tail: _nothing
         },
         accept,
         state
       ) do
    host = state |> get_in(~w(irc_state hostname)a)
    Logger.debug("User #{inspect(accept)} [#{host}] assigns their nickname #{nick}")

    {:noreply, state |> put_in(~w(irc_state nick)a, nick) |> send_motd_if_possible(accept)}
  end

  # ============================================================================
  # Give me a user
  defp handle_irc(
         %Exirchatterd.IRCPacket{
           prefix: _origin,
           command: :user,
           args_head: [ident, _, _],
           args_tail: realname
         },
         accept,
         state
       ) do
    host = state |> get_in(~w(irc_state hostname)a)

    Logger.debug(
      "User #{inspect(accept)} [#{host}] assigns their ident #{ident} and realname #{realname}"
    )

    {:noreply,
     state
     |> put_in(~w(irc_state ident)a, ident)
     |> put_in(~w(irc_state real_name)a, realname)
     |> send_motd_if_possible(accept)}
  end

  # ============================================================================
  # Ping
  defp handle_irc(
         %Exirchatterd.IRCPacket{
           prefix: origin,
           command: :ping,
           args_head: nonsense,
           args_tail: _ignoretl
         },
         accept,
         state
       ) do
    host = state |> get_in(~w(irc_state hostname)a)
    uri = ExsemanticaWeb.Endpoint.struct_url()

    Logger.debug("User #{inspect(accept)} [#{host}] pings")
    nudge = state |> get_in(~w(irc_state ping_nudge)a)
    kill = state |> get_in(~w(irc_state ping_kill)a)

    unless is_nil(nudge),
      do: if(nudge |> Process.read_timer(), do: nudge |> Process.cancel_timer())

    unless is_nil(kill), do: if(kill |> Process.read_timer(), do: kill |> Process.cancel_timer())

    :gen_tcp.send(
      accept,
      %Exirchatterd.IRCPacket{
        prefix: origin,
        command: :pong,
        args_head: nonsense,
        args_tail: uri.host
      }
      |> Exirchatterd.IRCPacket.decode()
    )

    {:noreply,
     state
     |> put_in(~w(irc_state ping?)a, DateTime.utc_now() |> DateTime.to_unix())
     |> put_in(
       ~w(irc_state ping_nudge)a,
       Process.send_after(self(), {:ping, accept}, @ping_thresh)
     )}
  end

  # ============================================================================
  # Quit
  defp handle_irc(
         %Exirchatterd.IRCPacket{
           prefix: origin,
           command: :quit,
           args_head: head,
           args_tail: reason
         },
         accept,
         state
       ) do
    host = state |> get_in(~w(irc_state hostname)a)
    Logger.debug("User #{inspect(accept)} [#{inspect(host)}] quits")

    :gen_tcp.send(
      accept,
      %Exirchatterd.IRCPacket{
        prefix: origin,
        command: :error,
        args_head: head,
        args_tail: "Quit (#{reason})"
      }
      |> Exirchatterd.IRCPacket.decode()
    )

    :gen_tcp.close(accept)
    {:noreply, state}
  end

  # ============================================================================
  # Catchall
  defp handle_irc(catch_all, accept, state) do
    host = state |> get_in(~w(irc_state hostname)a)

    Logger.warning(
      "Unimplemented IRC data from #{inspect(accept)} [#{host}]: #{inspect(catch_all)}"
    )

    {:noreply, state}
  end

  # ============================================================================
  defp send_motd_if_possible(state, accept) do
    no_ident =
      is_nil(state |> get_in(~w(irc_state ident)a)) &&
        is_nil(state |> get_in(~w(irc_state ident)a))

    no_nick = is_nil(state |> get_in(~w(irc_state ident)a))

    unless no_ident || no_nick do
      state |> send_motd(accept)
    end

    state
  end

  defp send_motd(state, accept) do
    :gen_tcp.send(
      accept,
      state |> Exirchatterd.CannedReplies.reply(375) |> Exirchatterd.IRCPacket.decode()
    )

    for line <- Exirchatterd.MOTD.motd() |> String.split("\n") do
      :gen_tcp.send(
        accept,
        state
        |> Exirchatterd.CannedReplies.reply({372, line})
        |> Exirchatterd.IRCPacket.decode()
      )
    end

    :gen_tcp.send(
      accept,
      state |> Exirchatterd.CannedReplies.reply(376) |> Exirchatterd.IRCPacket.decode()
    )
  end
end
