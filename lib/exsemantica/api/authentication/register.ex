defmodule Exsemantica.API.Authentication.Register do
  import Exsemantica.Gettext

  use Plug.Builder

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    username = conn.body_params["username"]
    password = conn.body_params["password"]
    invite = conn.body_params["invite"]

    case invite do
      %{"method" => "code", "data" => code} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          501,
          Jason.encode!(%{
            e: "NOT_IMPLEMENTED",
            message: gettext("This endpoint is currently not implemented.")
          })
        )

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          Jason.encode!(%{
            e: "INVITE_INVALID",
            message: gettext("Invite is invalid or not authorized.")
          })
        )
    end
  end
end
