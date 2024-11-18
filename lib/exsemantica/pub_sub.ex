defmodule Exsemantica.PubSub do
  @moduledoc """
  Handles publish/subscribe of Aggregates and Users
  """
  require Logger
  alias Exsemantica.PubSub
  use DynamicSupervisor

  @doc """
  Starts the PubSub supervisor
  """
  def start_link(init_arg) do
    Logger.info("PubSub supervisor started")
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Starts a PubSub dynamically, the subscriber should be a PID.
  """
  def start_child(subscriber) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {PubSub.Server, subscriber: subscriber}
    )
  end

  @doc """
  Publishes the message to all PubSub servers supervised by this supervisor.
  """
  def publish(topic, message) do
    Logger.debug("Published #{inspect message} to #{inspect topic}")

    children = DynamicSupervisor.which_children(__MODULE__)
    for {_, pid, _, [PubSub.Server]} <- children do
      pid |> PubSub.Server.topic_receive(topic, message)
    end

    :ok
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
