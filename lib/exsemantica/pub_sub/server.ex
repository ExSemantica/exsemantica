defmodule Exsemantica.PubSub.Server do
  @moduledoc """
  A PubSub target.
  """
  alias Exsemantica.PubSub
  require Logger
  use GenServer

  # ===========================================================================
  # Methods
  # ===========================================================================
  def start_link(_init_arg, subscriber: subscriber) do
    where = {:via, Registry, {PubSub.ServerRegistry, subscriber}}
    GenServer.start_link(__MODULE__, [subscriber: subscriber], name: where)
  end

  def topic_receive(pid, topic, message) do
    GenServer.cast(pid, {:receive, topic, message})
  end

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(subscriber: subscriber) do
    Logger.debug("#{inspect(subscriber)} starts a PubSub")
    {:ok, %{subscriber: subscriber, topics: MapSet.new()}}
  end

  @impl true
  def handle_call(:ping, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:receive, topic, message}, state) do
    if Process.alive?(state.subscriber) do
      if MapSet.member?(state.topics, topic) do
        send(state.subscriber, {:receive, topic, message})
      end

      {:noreply, state}
    else
      Logger.debug("#{inspect(state.subscriber)} is not alive, its PubSub will be terminated")

      {:stop, :normal, state}
    end
  end

  @impl true
  def handle_cast({:subscribe, topic}, state) do
    Logger.debug("#{inspect(state.subscriber)} subscribes to #{inspect(topic)}")
    {:noreply, %{state | topics: MapSet.put(state.topics, topic)}}
  end

  @impl true
  def handle_cast({:unsubscribe, topic}, state) do
    Logger.debug("#{inspect(state.subscriber)} unsubscribes from #{inspect(topic)}")
    {:noreply, %{state | topics: MapSet.delete(state.topics, topic)}}
  end
end
