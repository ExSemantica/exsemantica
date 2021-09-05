defmodule ExsemanticaPhxWeb.ApiV0.Plug do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    {status, response} =
      case {conn.method, conn.path_info} do
        {"GET", ["registration"]} ->
          {:ok, whoops} =
            Jason.encode(%{
              e: "test",
              msg: ~S"""
              Testing 123
              """
            })

          {401, whoops}

        _ ->
          {:ok, whoops} =
            Jason.encode(%{
              e: "unimplemented",
              msg: ~S"""
              The operation you are trying to perform is unimplemented.
              """
            })

          {500, whoops}
      end

    conn |> send_resp(status, response)
  end
end
