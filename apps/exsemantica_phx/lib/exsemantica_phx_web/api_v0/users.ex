defmodule ExsemanticaPhxWeb.ApiV0.Interests do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    ExsemanticaApi.Interests.fire(ExsemanticaApi.Endpoint.Interests, conn.remote_ip, %{
      method: conn.method,
      query_params: conn.query_params
    })
    {status, response} =
      receive do
        {:rate_limit_used, {s, r}, headers} -> {s, r}
        {:rate_global_stall, {s, r}} -> {s, r}
      after
        2000 ->
          {:ok, json} = Jason.encode(%{error: true, message: "The API gateway timed out."})
          {504, json}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, response)
  end
end
