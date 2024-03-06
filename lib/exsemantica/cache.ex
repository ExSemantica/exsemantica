defmodule Exsemantica.Cache do
  @moduledoc """
  The Mnesia-based cache resides in this namespace.

  Some things need to be cached because loading massive amounts of PostgreSQL
  associations can get inefficient.
  """

  require Logger
  use GenServer

  alias __MODULE__.Votes

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  @doc """
  Starts the cache pool.
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec adjust_vote({:comment | :post, integer()}, integer()) :: {:ok, integer()}
  @doc """
  Adjusts the cached vote count for a specific post or comment.
  """
  def adjust_vote(otype_id, amount) do
    GenServer.call(__MODULE__, {:adjust_vote, otype_id, amount})
  end

  @spec fetch_vote({:comment | :post, integer()}) :: {:ok, integer()}
  @doc """
  Fetches a cached vote count for a specific post or comment.
  """
  def fetch_vote(otype_id) do
    GenServer.call(__MODULE__, {:fetch_vote, otype_id})
  end

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(_args) do
    Logger.info("Preparing cache pool")

    :ok =
      case :mnesia.create_schema([Node.self()]) do
        {:error, {_node0, {:already_exists, _node1}}} -> :ok
        :ok -> :ok
      end

    :mnesia.start()

    # === VOTES ===
    # otype_id -> {otype, id}
    # otype = post or comment
    # id = the post or comment's ID within the database
    {:atomic, :ok} = :mnesia.create_table(Exsemantica.Cache.Vote, attributes: [:otype_id, :count])

    {:ok, %{}}
  end

  @impl true
  def handle_call({:fetch_vote, otype_id}, _from, state) do
    {:reply, Votes.load(otype_id), state}
  end

  @impl true
  def handle_call({:adjust_vote, otype_id, amount}, _from, state) do
    {:reply, Votes.modify({otype_id, amount}), state}
  end
end
