defmodule Exsemantica.Chat.ChannelSupervisor do
  alias Exsemantica.Chat
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Allows for dynamic, lazy starting of aggregate channels.
  """
  def start_child(aggregate) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Chat.Channel, aggregate: aggregate}
    )
  end

  @impl true
  def init(init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [init_arg]
    )
  end
end
