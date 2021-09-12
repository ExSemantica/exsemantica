defmodule ExsemanticaPhxWeb.ApiV0.Users do
  @max_query 15
  @unix_time ~N[1970-01-01 00:00:00]

  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    ExsemanticaApi.Users.fire(ExsemanticaApi.Endpoint.Users, self(), conn.remote_ip)

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

              valid = ExsemanticaPhx.Sanitize.valid_username?(uquery)

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
                          ExsemanticaPhx.Search.users(
                            "%" <> uquery <> "%",
                            [],
                            :count
                          )
                      })

                    {200, json}

                  {qmax, _} ->
                    result =
                      ExsemanticaPhx.Search.users(
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

  defp to_json([user, biography, registered]) do
    %{
      user: user,
      bio: ExsemanticaPhx.Sanitize.truncate_string(biography, 256),
      registered: registered |> NaiveDateTime.diff(@unix_time)
    }
  end
end
