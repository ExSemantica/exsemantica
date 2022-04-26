defmodule Exirchatterd.Dial.Listener do
  @moduledoc """
  The core of the IRC daemon is the listener.
  """
  require Logger
  use GenServer

  @poll_interval 100
  @ping_interval 120_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(listener: listener, ssl: ssl?) do
    {:ok,
     if ssl? do
       %{
         ssl?: true,
         nick?: false,
         user?: false,
         acceptor: Process.send_after(self(), {:poll, :ssl, listener}, @poll_interval),
         data: %{}
       }
     else
       %{
         ssl?: false,
         nick?: false,
         user?: false,
         acceptor: Process.send_after(self(), {:poll, :tcp, listener}, @poll_interval),
         data: %{}
       }
     end}
  end

  # === HANDLE PLAIN CONNECTIONS ===============================================
  @impl true
  def handle_info({:poll, :tcp, tsocket}, state) do
    acceptor = Process.send_after(self(), {:poll, :tcp, tsocket}, @poll_interval)

    case :gen_tcp.accept(tsocket, @poll_interval) do
      {:ok, tclient} ->
        {:ok, {ip, _}} = :inet.peername(tclient)
        {:ok, {:hostent, hostname, _, _, _, _}} = :inet.gethostbyaddr(ip)

        Logger.debug("with ok #{inspect(tclient)}")

        Process.send_after(self(), {:chkping, tclient}, @ping_interval)

        {:noreply,
         %{state | acceptor: acceptor}
         |> put_in(~w(client)a, tclient)
         |> put_in(~w(data hostname)a, hostname)
         |> put_in(~w(data ping_t0)a, DateTime.utc_now())}

      _err ->
        {:noreply, %{state | acceptor: acceptor}}
    end
  end

  @impl true
  def handle_info({:tcp, socket, data}, state) do
    data |> Exirchatterd.IRCPacket.encode() |> Exirchatterd.ProtoRX.route(socket, state)
  end

  # === HANDLE TLS CONNECTIONS =================================================
  @impl true
  def handle_info({:poll, :ssl, ssocket}, state) do
    acceptor = Process.send_after(self(), {:poll, :ssl, ssocket}, @poll_interval)

    case :ssl.transport_accept(ssocket, @poll_interval) do
      {:ok, sclient} ->
        {:ok, {ip, _}} = :ssl.peername(sclient)
        {:ok, {:hostent, hostname, _, _, _, _}} = :inet.gethostbyaddr(ip)

        Logger.debug("with secure pre #{inspect(sclient)}")

        case :ssl.handshake(sclient, @poll_interval) do
          {:ok, shandclient, sext} ->
            Logger.debug(
              "with secure handshook ok #{inspect(shandclient)}, exts #{inspect(sext)}"
            )

            Process.send_after(self(), {:chkping, shandclient}, @ping_interval)

            {:noreply,
             %{state | acceptor: acceptor}
             |> put_in(~w(client)a, shandclient)
             |> put_in(~w(data hostname)a, hostname)
             |> put_in(~w(data ping_t0)a, DateTime.utc_now())}

          {:ok, shandclient} ->
            Logger.debug("with secure handshook ok #{inspect(shandclient)}")

            Process.send_after(self(), {:chkping, shandclient}, @ping_interval)

            {:noreply,
             %{state | acceptor: acceptor}
             |> put_in(~w(client)a, shandclient)
             |> put_in(~w(data hostname)a, hostname)
             |> put_in(~w(data ping_t0)a, DateTime.utc_now())}

          err ->
            Logger.warning("with secure handshook fail #{inspect(sclient)}, #{inspect(err)}")
            {:noreply, state}
        end

      _err ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:ssl, socket, data}, state) do
    {:noreply, data |> Exirchatterd.IRCPacket.encode() |> Exirchatterd.ProtoRX.route(socket, state)}
  end

  @impl true
  def handle_info({:chkping, socket}, state) do
    hosts = ExsemanticaWeb.Endpoint.struct_url()
    host = hosts.host

    {:noreply, state
    |> Exirchatterd.ProtoTX.send(socket, %Exirchatterd.IRCPacket{
      prefix: nil,
      command: :ping,
      args_head: [host],
      args_tail: nil
    })
    |> put_in(~w(data ping_kill)a, Process.send_after(self(), {:dieping, socket}, 15_000))}
  end

  @impl true
  def handle_info({:dieping, socket}, state) do
    t1 = DateTime.utc_now() |> DateTime.to_unix()
    t0 = state |> get_in(~w(data ping_t0)a) |> DateTime.to_unix()

    {:stop, :normal,
     state
     |> Exirchatterd.ProtoTX.send(socket, %Exirchatterd.IRCPacket{
       prefix: nil,
       command: :error,
       args_head: [],
       args_tail: "Ping timeout (#{t1 - t0} seconds)"
     })
     |> Exirchatterd.ProtoTX.close(socket)}
  end

  def ping_interval, do: @ping_interval
end
