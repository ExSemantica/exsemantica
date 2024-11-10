defmodule Exsemantica.Chat.UserSupervisor do
  @moduledoc """
  Allows for dynamic, lazy starting of users.
  """
  alias Exsemantica.Chat
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Starts a user state.
  """
  def start_child(handle) do
    DynamicSupervisor.start_child(__MODULE__, {Chat.User, handle: handle})
  end

  @impl true
  def init(init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [init_arg]
    )
  end
end
