defmodule ExsemanticaPhxWeb.ApiV0.Interests do
  import Ecto.Query
  import Plug.Conn

  @global_qmax 30
  @unix_time ~N[1970-01-01 00:00:00]

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    uquery = get_in(conn.query_params, ["q"]) || ""
    valid = ExsemanticaPhx.Sanitize.valid_interest?(uquery)

    {status, response} = if valid do
      case Integer.parse(get_in(conn.query_params, ["qmax"]) || "0") do
        {0, _} ->
          {:ok, json} =
            Jason.encode(%{e: false, n: ExsemanticaPhx.Search.interests("%#{uquery}%", [], :count)})

          {200, json}

        {qmax, _} ->
          result =
            ExsemanticaPhx.Search.interests(
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

  defp to_json([title, desc, inserted, edited, poster]) do
    poster_name =
      ExsemanticaPhx.Repo.one(
        from(user in ExsemanticaPhx.Site.User,
          where: user.node_corresponding == ^poster,
          select: user.username
        )
      )

    %{
      posted_by: poster_name,
      title: title,
      description: ExsemanticaPhx.Sanitize.truncate_string(desc, 256),
      inserted_on: inserted |> NaiveDateTime.diff(@unix_time),
      edited: edited |> NaiveDateTime.diff(@unix_time)
    }
  end
end
