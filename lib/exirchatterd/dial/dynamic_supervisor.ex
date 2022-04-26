defmodule Exirchatterd.Dial.DynamicSupervisor do
  require Logger
  use DynamicSupervisor

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    Logger.info("seeding IRC connector pool")
    DynamicSupervisor.init(max_children: 500, strategy: :one_for_one)
  end

  def spawn_connection(listen, ssl: false) do
    Logger.info("spawning an IRC connection by plain (6667)")

    DynamicSupervisor.start_child(__MODULE__, {
      Exirchatterd.Dial.Listener,
      listener: listen, ssl: false
    })
  end
  def spawn_connection(listen, ssl: true) do
    Logger.info("spawning an IRC connection by TLS (6697)")

    DynamicSupervisor.start_child(__MODULE__, {
      Exirchatterd.Dial.Listener,
      listener: listen, ssl: true
    })
  end
end
