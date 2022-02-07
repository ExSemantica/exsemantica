defmodule ExsemanticaWeb.EndpointApi do
  use Phoenix.Endpoint, otp_app: :exsemantica
  use Absinthe.Phoenix.Endpoint

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Absinthe.Plug,
    schema: ExsemanticaWeb.Schema
end
