defmodule Exsemantica.Cache do
  @moduledoc """
  The Mnesia-based cache resides in this namespace
  """
  require Logger
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(_args) do
    Logger.info("Preparing Mnesia")
    # :ok = :net_kernel.monitor_nodes(true)

    :ok =
      case :mnesia.create_schema([Node.self()]) do
        {:error, {_node0, {:already_exists, _node1}}} -> :ok
        :ok -> :ok
      end

    :mnesia.start()

    {:ok, %{}}
  end

  @impl true
  def handle_info({:nodeup, joining_node}, state) do
    nodes = Node.list()
    Logger.debug("Node #{inspect(joining_node)} joins other nodes #{inspect(nodes)}")

    {:ok, _nodes} = :mnesia.change_config(:extra_db_nodes, nodes)

    {:ok, %{}}
  end

  # ===========================================================================
  # Private functions
  # ===========================================================================
  defp votes_initialize do
    # otype_id -> {otype, id}
    # otype = post or comment
    # id = the post or comment's ID within the database
    :mnesia.create_table(Exsemantica.Cache.Votes, attributes: [:otype_id, :count])
end

  defp votes_load(otype_id) do
    Logger.debug("loading #{inspect(otype_id)} vote count")
    :unimplemented
  end

  defp votes_change(otype_id, kind) do
    if :mnesia.index_read(Exsemantica.Cache.Votes, otype_id, :otype_id) == [] do
      Logger.debug("lazy loading #{inspect(otype_id)} vote count")
      votes_load(otype_id)
    end
    case kind do
      :upvote -> :unimplemented
      :downvote -> :unimplemented
    end
  end
end
