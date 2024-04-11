defmodule Exsemantica.API do
  @moduledoc """
  Application Programming Interface root route
  """
  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:urlencoded, {:json, json_decoder: Jason}]
  )

  plug(:match)
  plug(:dispatch)

  forward("/.well-known/exsemantica/", to: __MODULE__.WellKnown)
  forward("/authentication/", to: __MODULE__.Authentication)

  match(_, to: Exsemantica.API.ErrorHandler, init_opts: %{message: :endpoint_not_found})
end
