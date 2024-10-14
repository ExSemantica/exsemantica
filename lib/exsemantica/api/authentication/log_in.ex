defmodule Exsemantica.API.Authentication.LogIn do
  @errors_json %{
    user_not_found:
      :json.encode(%{
        e: "USER_NOT_FOUND"
      }),
    secret_incorrect:
      :json.encode(%{
        e: "SECRET_INCORRECT"
      })
  }

  use Plug.Builder

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
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
          :json.encode(%{
            e: "OK",
            token: token,
            username: user_struct.username
          })
        )

      {:error, :not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          @errors_json.user_not_found
        )

      {:error, :unauthorized} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          @errors_json.secret_incorrect
        )
    end
  end
end
