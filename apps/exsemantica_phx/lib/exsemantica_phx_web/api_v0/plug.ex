defmodule ExsemanticaPhxWeb.ApiV0.Plug do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    {:ok, whoops} = Jason.encode(%{e: "unimplemented", msg: ~S"""
      The operation you are trying to perform is unimplemented.
      """
      })
    conn
    |> resp(401, whoops)
  end
end
