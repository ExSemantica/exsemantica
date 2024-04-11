defmodule Exsemantica.API.Authentication do
  @moduledoc """
  Handles authenticating users

  Operations include:
  - Login
  - Logout
  - Registration
  """
  import Exsemantica.Gettext

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  post "/log_in" do
    username = conn.body_params["username"]
    password = conn.body_params["password"]

    case Exsemantica.Authentication.check_user(username, password) do
      {:ok, user_struct} ->
        IO.inspect(user_struct)

        {:ok, token, _claims} =
          Exsemantica.Guardian.encode_and_sign(user_struct, %{typ: "access"},
            ttl: {Exsemantica.Authentication.get_minutes_grace(), :minutes}
          )

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(%{
            e: "OK",
            token: token,
            username: user_struct.username,
            message: gettext("Signed in as %{user}.", user: user_struct.username)
          })
        )

      {:error, :not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{
            e: "USER_NOT_FOUND",
            message: gettext("That user does not exist.")
          })
        )

      {:error, :unauthorized} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          Jason.encode!(%{
            e: "SECRET_INCORRECT",
            message: gettext("Incorrect username, password, or other secret.")
          })
        )
    end
  end

  post "/refresh" do
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
              Jason.encode!(%{
                e: "OK",
                token: new_token
              })
            )

          {:error, :token_expired} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              401,
              Jason.encode!(%{
                e: "TOKEN_EXPIRED",
                message: gettext("Your session has expired, please log in again.")
              })
            )
          {:error, _} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              400,
              Jason.encode!(%{
                e: "MALFORMED_AUTHORIZATION_TOKEN",
                message: gettext("Malformed authorization token.")
              })
            )

        end

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          Jason.encode!(%{
            e: "MALFORMED_AUTHORIZATION",
            message: gettext("Malformed request, or not logged in.")
          })
        )
    end
  end

  match(_, to: Exsemantica.API.ErrorHandler, init_opts: %{message: :endpoint_not_found})
end
