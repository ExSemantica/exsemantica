defmodule ExsemanticaPhxWeb.ApiV0.Interests do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    {:ok, json} = Jason.encode(%{error: true, message: "Unimplemented."})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(501, json)
  end
end
