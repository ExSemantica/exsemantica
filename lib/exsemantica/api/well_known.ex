defmodule Exsemantica.API.WellKnown do
  @moduledoc """
  Handles sending information about an ExSemantica implementation
  """
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  def init(opts) do
    opts
  end

  get "/application" do
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

  match(_, to: Exsemantica.API.ErrorHandler, init_opts: %{message: :endpoint_not_found})
end
