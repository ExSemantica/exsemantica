defmodule ExsemanticaPhxWeb.ApiV0.Plug do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    ExsemanticaApi.Unimplemented.fire(ExsemanticaApi.Endpoint.Unimplemented, self(), conn.remote_ip)

    {status, response} = receive do
      {_, reply} -> reply 
    after 250 ->
      {:ok, json} = Jason.encode(%{error: true, message: "The API gateway timed out."})
      {504, json}
    end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, response)
  end
end
