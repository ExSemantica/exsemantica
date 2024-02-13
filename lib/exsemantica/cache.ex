defmodule Exsemantica.Cache do
  @moduledoc """
  The Mnesia-based cache resides in this namespace.

  Some things need to be cached because loading massive amounts of PostgreSQL
  associations can get inefficient.
  """
  @queue_after 50

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

  @spec adjust_vote({:comment | :post, integer()}, integer()) :: :ok
  @doc """
  Adjusts the cached vote count for a specific post or comment.
  """
  def adjust_vote(otype_id, amount) do
    GenServer.cast(__MODULE__, {:adjust_vote, otype_id, amount})
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
    :mnesia.create_table(Exsemantica.Cache.Vote, attributes: [:otype_id, :count])
    :mnesia.add_table_index(Exsemantica.Cache.Vote, :otype_id)

    {:ok, %{pending_votes: %{}, timer: nil}}
  end

  @impl true
  def handle_call({:fetch_vote, otype_id}, _from, state) do
    {:reply, Votes.load(otype_id), state}
  end

  @impl true
  def handle_cast({:adjust_vote, otype_id, amount}, state) do
    Logger.debug("Adjust vote pending in #{inspect(otype_id)} by #{inspect(amount)}")

    # really weird method to force a nil value to be zero then adjust it
    new_votes = state |> update_in([:pending_votes, otype_id], &((&1 || 0) + amount))

    if is_nil(state.timer) do
      {:noreply,
       %{
         state
         | timer: Process.send_after(self(), :handle_queue, @queue_after),
           pending_votes: new_votes
       }}
    else
      {:noreply, %{state | pending_votes: new_votes}}
    end
  end

  @impl true
  def handle_info(:handle_queue, %{pending_votes: votes}) do
    if votes |> Enum.map(&Votes.modify/1) |> Enum.any?(&(:ok !== &1)) do
      Logger.warning("Pending cacheable vote(s) wasn't okay!")
    end

    {:noreply, %{timer: nil, pending_votes: %{}}}
  end
end
