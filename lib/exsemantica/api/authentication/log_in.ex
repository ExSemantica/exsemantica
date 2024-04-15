defmodule Exsemantica.API.Authentication.LogIn do
  import Exsemantica.Gettext

  use Plug.Builder

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    username = conn.body_params["username"]
    password = conn.body_params["password"]

    case Exsemantica.Authentication.check_user(username, password) do
      {:ok, user_struct} ->
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
end
