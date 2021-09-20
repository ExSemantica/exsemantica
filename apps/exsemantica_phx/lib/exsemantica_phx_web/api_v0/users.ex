defmodule ExsemanticaPhxWeb.ApiV0.Users do
  import Plug.Conn

  @global_qmax 30
  @unix_time ~N[1970-01-01 00:00:00]

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    uquery = get_in(conn.query_params, ["q"]) || ""
    valid = ExsemanticaPhx.Sanitize.valid_username?(uquery)

    {status, response} =
      if valid do
        case Integer.parse(get_in(conn.query_params, ["qmax"]) || "0") do
          {0, _} ->
            {:ok, json} =
              Jason.encode(%{
                e: false,
                n: ExsemanticaPhx.Search.users("%#{uquery}%", [], :count)
              })

            {200, json}

          {qmax, _} ->
            result =
              ExsemanticaPhx.Search.users(
                "%#{uquery}%",
                [
                  limit: if(qmax > @global_qmax or qmax < 0, do: @global_qmax, else: qmax)
                ],
                :query
              )
              |> Enum.map(&to_json/1)

            {:ok, json} = Jason.encode(%{e: false, n: length(result), result: result})
            {200, json}
        end
      else
        {:ok, whoops} = Jason.encode(%{e: true, message: "The requested query was invalid."})
        {400, whoops}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, response)
  end

  defp to_json([user, biography, registered]) do
    %{
      username: user,
      biography: ExsemanticaPhx.Sanitize.truncate_string(biography, 256),
      registered_on: registered |> NaiveDateTime.diff(@unix_time)
    }
  end
end
