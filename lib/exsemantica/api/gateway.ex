defmodule Exsemantica.API.Gateway do
  use Plug.Builder

  def init(type: type, target: target) do
    {:ok, [type: type, target: target]}
  end

  def call(conn, opts) do
    conn
    |> WebSockAdapter.upgrade(__MODULE__.Socket, opts, timeout: 1_000)
    |> halt
  end
end
