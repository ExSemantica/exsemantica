defmodule Exsemantica.Cache do
  @moduledoc """
  The Mnesia-based cache resides in this namespace
  """
  @queue_after 50

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

    {:ok, %{queue: :queue.new(), timer: nil}}
  end

  @impl true
  def handle_cast(message, state) do
    Logger.debug("Handle message #{inspect(message)}")

    if is_nil(state.timer) do
      {:noreply,
       %{
         state
         | timer: Process.send_after(self(), :handle_queue, @queue_after),
           queue: :queue.snoc(state.queue, message)
       }}
    else
      {:noreply, %{state | queue: :queue.snoc(state.queue, message)}}
    end
  end

  @impl true
  def handle_info(:handle_queue, state) do
    events = state.queue |> :queue.to_list()

    Logger.debug("Timer hit with #{length(events)}")
    events |> Enum.map(&timed_event/1)

    {:noreply, %{queue: :queue.new(), timer: nil}}
  end

  # ===========================================================================
  # Private functions
  # ===========================================================================
  defp timed_event(what = {:adjust_votes, from, otype_id, amount}) do
    Logger.debug("Adjusting votes: #{inspect(what)}")

    send(from, {:adjust_votes, __MODULE__.Votes.modify(otype_id, amount)})
  end
end
