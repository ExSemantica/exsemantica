defmodule ExsemanticaPhxWeb.ApiV0.Plug do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    {status, response} =
      case {conn.method, conn.path_info} do
        {"GET", ["registration"]} ->

          if uquery = ExsemanticaPhx.Protect.find_user(get_in(conn.query_params, ["user"])) do
            {:ok, json} = Jason.encode(%{
              complete: (uquery |> ExsemanticaPhx.Protect.find_contract) != nil
            })
            {200, json}
          else
            {:ok, json} = Jason.encode(%{e: encode_error(:no_user)})
            {404, json}
          end        

        {"GET", ["err_message"]} ->
          {code, _extra} = Integer.parse(get_in(conn.query_params, ["code"]))
          {:ok, eh_message} = Jason.encode(%{e_requested: code, message: extend_error(code)})
          {200, eh_message}

        _ ->
          {:ok, whoops} = Jason.encode(%{e: encode_error(:unimplemented)})
          {500, whoops}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, response)
  end

  def encode_error(:no_user), do: 0x0002
  def encode_error(_), do: 0x0001

  def extend_error(0x0002), do: "There is no user with that username."
  def extend_error(_), do: "This endpoint is currently unimplemented."
end
