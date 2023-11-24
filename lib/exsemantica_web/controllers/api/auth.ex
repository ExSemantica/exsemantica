defmodule ExsemanticaWeb.API.Auth do
  use ExsemanticaWeb, :controller

  @spec log_in(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def log_in(conn, %{"username" => username, "password" => password}) do
    # TODO: Implement logins
    conn
    |> put_status(501)
    |> json(%{is_error: true, message: "Unimplemented"})
  end

  @spec log_out(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def log_out(conn, _parameters) do
    # TODO: Implement logouts
    conn
    |> put_status(501)
    |> json(%{is_error: true, message: "Unimplemented"})
  end
end
