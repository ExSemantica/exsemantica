defmodule Exsemantica.API.WellKnown.Application do
  @moduledoc """
  Application information

  Accessible by `/.well-known/exsemantica/application`
  """
  use Plug.Builder

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      200,
      Jason.encode!(%{
        provider: "ExSemantica",
        version: Exsemantica.ApplicationInfo.get_version(),
        api: %{current: 0, supported: [0]}
      })
    )
  end
end
