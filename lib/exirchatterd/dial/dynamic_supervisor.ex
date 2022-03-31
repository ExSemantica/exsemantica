defmodule Exirchatterd.Dial.DynamicSupervisor do
  require Logger
  use DynamicSupervisor

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    Logger.info("seeding IRC connector pool")
    DynamicSupervisor.init(max_children: 250, strategy: :one_for_one)
  end

  def spawn_connection(listen) do
    Logger.info("spawning an IRC connection")
    DynamicSupervisor.start_child(__MODULE__, {Exirchatterd.Dial.TcpListener, listen})
  end
end
