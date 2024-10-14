defmodule Exsemantica.API.Authentication.Register do
  @errors_json %{
    invite_invalid:
      :json.encode(%{
        e: "INVITE_INVALID",
      })
  }

  use Plug.Builder

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    username = conn.body_params["username"]
    password = conn.body_params["password"]
    invite = conn.body_params["invite"]

    case invite do
      %{"method" => "code", "data" => code} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          501,
          :json.encode(%{
            e: "NOT_IMPLEMENTED",
          })
        )

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          @errors_json.invite_invalid
        )
    end
  end
end
