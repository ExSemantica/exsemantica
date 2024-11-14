defmodule Exsemantica.API.Gateway.Socket do
  @moduledoc """
  Dispatches incoming updates from Aggregates and Users to clients via
  WebSockets
  """

  def init(args) do
    {:ok, []}
  end

  # TODO: Aggregates/Users PubSub with handle_info
end
