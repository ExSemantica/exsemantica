defmodule ExsemanticaPhxWeb.ApiV0.Interests do
  @max_query 15
  @unix_time ~N[1970-01-01 00:00:00]

  import Ecto.Query
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    ExsemanticaApi.Interests.fire(ExsemanticaApi.Endpoint.Interests, self(), conn.remote_ip)

    {status, response} =
      receive do
        :ok ->
          case conn.method do
            "GET" ->
              uquery =
                get_in(conn.query_params, [
                  "q"
                ]) ||
                  ""

              valid = ExsemanticaPhx.Sanitize.valid_interest?(uquery)

              if valid do
                case Integer.parse(
                       get_in(conn.query_params, [
                         "qmax"
                       ]) || "0"
                     ) do
                  {0, _} ->
                    {:ok, json} =
                      Jason.encode(%{
                        n:
                          ExsemanticaPhx.Search.interests(
                            "%" <> uquery <> "%",
                            [],
                            :count
                          )
                      })

                    {200, json}

                  {qmax, _} ->
                    result =
                      ExsemanticaPhx.Search.interests(
                        "%" <> uquery <> "%",
                        [
                          limit:
                            if(qmax > @max_query or qmax < 0,
                              do: @max_query,
                              else: qmax
                            )
                        ],
                        :query
                      )
                      |> Enum.map(&to_json/1)

                    {:ok, json} = Jason.encode(%{n: length(result), d: result})
                    {200, json}
                end
              end
          end

        {:halt, reply} ->
          reply
      after
        2000 ->
          {:ok, json} = Jason.encode(%{error: true, message: "The API gateway timed out."})
          {504, json}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, response)
  end

  defp to_json([title, desc, inserted, edited, poster]) do
    poster_name = ExsemanticaPhx.Repo.one(from user in ExsemanticaPhx.Site.User, where: user.node_corresponding == ^poster, select: user.username)
    %{
      posted_by: poster_name,
      title: title,
      desc: desc,
      inserted: inserted |> NaiveDateTime.diff(@unix_time),
      edited: edited |> NaiveDateTime.diff(@unix_time)
    }
  end
end
