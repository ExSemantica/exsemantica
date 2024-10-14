defmodule Exsemantica.API.Authentication.Refresh do
  @errors_json %{
    token_expired:
      :json.encode(%{
        e: "TOKEN_EXPIRED",
      }),
    malformed_token:
      :json.encode(%{
        e: "MALFORMED_TOKEN",
      }),
    malformed_authorization:
      :json.encode(%{
        e: "MALFORMED_AUTHORIZATION",
      })
  }

  use Plug.Builder

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    bearer =
      conn |> get_req_header("authorization") |> Exsemantica.Authentication.extract_bearer()

    case bearer do
      {:ok, old_token} ->
        # FIXME: Handle all of Guardian's errors.
        token_state =
          old_token
          |> Exsemantica.Guardian.refresh(
            ttl: {Exsemantica.Authentication.get_minutes_grace(), :minutes}
          )

        case token_state do
          {:ok, _old_token_and_claims, {new_token, _claims}} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              200,
              :json.encode(%{
                e: "OK",
                token: new_token
              })
            )

          {:error, :token_expired} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              401,
              @errors_json.token_expired
            )

          {:error, _} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              400,
              @errors_json.malformed_token
            )
        end

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          @errors_json.malformed_authorization
        )
    end
  end
end
