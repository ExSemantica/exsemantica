defmodule Exirchatterd.Dial.TcpListener do
  require Logger
  use GenServer
  @ircd_password "s3cr3t salad"

  def start_link(listen) do
    GenServer.start_link(__MODULE__, listen)
  end

  @impl true
  def init(listen) do
    Process.send(self(), :poll, [])
    {:ok, %{tcp_listen: listen, tcp_accept: nil}}
  end

  @impl true
  def handle_info(:poll, state) do
    {:noreply,
     %{
       state
       | tcp_accept:
           case :gen_tcp.accept(state.tcp_listen, 100) do
             {:ok, accept} ->
               Logger.info("Peer connected")

               {:ok, _next} =
                 Exirchatterd.Dial.DynamicSupervisor.spawn_connection(state.tcp_listen)

               Process.send(self(), :poll, [])
               accept

             {:error, :timeout} ->
               Process.send(self(), :poll, [])
               state.tcp_accept

             reason ->
               Logger.warning("UNIMPLEMENTED TCP error #{inspect(reason)}")
               state.tcp_accept
           end
     }}
  end
  @impl true
  def handle_info({:tcp, accept, data}, state) do
    :gen_tcp.send(accept, "Testing 123?\r\n")
    {:noreply, state}
  end
  @impl true
  def handle_info({:tcp_closed, _accept}, state) do
    Logger.info("goodbye IRC conn")
    {:stop, :normal, state}
  end
end
