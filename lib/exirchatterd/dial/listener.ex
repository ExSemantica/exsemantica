defmodule Exirchatterd.Dial.Listener do
  @moduledoc """
  The core of the IRC daemon is the listener.
  """
  require Logger
  use GenServer

  @poll_interval 100

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

        {:noreply,
         %{state | acceptor: acceptor}
         |> put_in(~w(client)a, tclient)
         |> put_in(~w(data hostname)a, hostname)}

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

            {:noreply,
             %{state | acceptor: acceptor}
             |> put_in(~w(client)a, shandclient)
             |> put_in(~w(data hostname)a, hostname)}

          {:ok, shandclient} ->
            Logger.debug("with secure handshook ok #{inspect(shandclient)}")

            {:noreply,
             %{state | acceptor: acceptor}
             |> put_in(~w(client)a, shandclient)
             |> put_in(~w(data hostname)a, hostname)}

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
    data |> Exirchatterd.IRCPacket.encode() |> Exirchatterd.ProtoRX.route(socket, state)
  end
end
