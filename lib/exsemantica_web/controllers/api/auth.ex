defmodule ExsemanticaWeb.API.Auth do
  @moduledoc """
  Authenticates user accounts (log in, log out)
  """
  use ExsemanticaWeb, :controller
  alias Exsemantica.Auth

  # Import gettext for instance translations
  import ExsemanticaWeb.Gettext

  @minutes_grace 10

  @spec log_in(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def log_in(conn, %{"username" => username, "password" => password}) do
    user_condition = Auth.check_user(username, password)

    case user_condition do
      {:ok, user_data} ->
        conn =
          conn
          |> fetch_session()
          |> Auth.Guardian.Plug.sign_in(user_data, %{typ: "access"},
            ttl: {@minutes_grace, :minutes}
          )

        conn
        |> put_status(200)
        |> json(%{
          is_error: false,
          message: gettext("Signed in as %{user}", user: user_data.username)
        })

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> json(%{is_error: true, message: gettext("User does not exist")})

      {:error, :unauthorized} ->
        conn
        |> put_status(401)
        |> json(%{is_error: true, message: gettext("Incorrect password")})
    end
  end

  @spec log_out(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def log_out(conn, _params) do
    # Don't need to send a response here
    conn
    |> fetch_session()
    |> Auth.Guardian.Plug.sign_out()
    |> send_resp(204, "")
  end
end
