defmodule ExsemanticaWeb.Auth.Check do
  @moduledoc """
  A middleman Plug that checks authentication, optionally adds user information.
  """

  use Plug.Builder

  def call(conn, _opts) do
    token = conn |> get_session("guardian_default_token")

    case Exsemantica.Auth.check_token(token) do
      {:ok, myuser} ->
        conn
        |> put_session("user_handle", myuser.username)
        |> put_session("user_id", myuser.id)
        |> put_session("user_auth", :ok)

      # TODO: I want to make an "expired session" message appear then clear.
      # I'm not quite sure how to clear it in LiveView cleanly.
      # Let's not implement this just yet
      {:error, error} ->
        conn
        |> put_session("user_handle", nil)
        |> put_session("user_id", nil)
        |> put_session("user_auth", error)
        |> put_session("guardian_default_token", nil)
    end
  end
end
