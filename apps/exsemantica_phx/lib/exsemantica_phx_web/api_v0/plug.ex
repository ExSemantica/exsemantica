defmodule ExsemanticaPhxWeb.ApiV0.Plug do
  @max_query 30
  @unix_time ~N[1970-01-01 00:00:00]

  import Ecto.Query
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    {status, response} =
      case {conn.method, conn.path_info} do
        {"GET", ["registration"]} ->
          if uquery = ExsemanticaPhx.Protect.find_user(get_in(conn.query_params, ["user"])) do
            {:ok, json} =
              Jason.encode(%{
                complete: uquery |> ExsemanticaPhx.Protect.find_contract() != nil
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

        {"GET", ["interest"]} ->
          uquery = get_in(conn.query_params, ["q"]) || ""

          valid = ExsemanticaPhx.Sanitize.valid_interest?(uquery)
          if valid do
            case Integer.parse(get_in(conn.query_params, ["qmax"]) || "0") do
              {0, _} ->
                {:ok, json} = Jason.encode(%{n: ExsemanticaPhx.Search.interests("%" <> uquery <> "%", [], :count) })
                {200, json}
              {qmax, _} ->
                result = ExsemanticaPhx.Search.interests("%" <> uquery <> "%", [limit: (if qmax > @max_query or qmax < 0, do: @max_query, else: qmax)], :query)
                |> Enum.map(&interest_to_json/1)
                {:ok, json} = Jason.encode(%{n: length(result), d: result})
                {200, json}
            end
          else
            {:ok, whoops} = Jason.encode(%{e: encode_error(:malformed_query)})
            {400, whoops}
          end

        {"GET", ["user"]} ->
          uquery = get_in(conn.query_params, ["q"]) || ""

          valid = ExsemanticaPhx.Sanitize.valid_username?(uquery)
          if valid do
            case Integer.parse(get_in(conn.query_params, ["qmax"]) || "0") do
              {0, _} ->
                {:ok, json} = Jason.encode(%{n: ExsemanticaPhx.Search.users("%" <> uquery <> "%", [], :count) })
                {200, json}
              {qmax, _} ->
                result = ExsemanticaPhx.Search.users("%" <> uquery <> "%", [limit: (if qmax > @max_query or qmax < 0, do: @max_query, else: qmax)], :query)
                |> Enum.map(&user_to_json/1)
                {:ok, json} = Jason.encode(%{n: length(result), d: result})
                {200, json}
            end
          else
            {:ok, whoops} = Jason.encode(%{e: encode_error(:malformed_query)})
            {400, whoops}
          end
        _ ->
          {:ok, whoops} = Jason.encode(%{e: encode_error(:unimplemented)})
          {501, whoops}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, response)
  end

  def encode_error(:malformed), do: 0x0003
  def encode_error(:no_user), do: 0x0002
  def encode_error(_), do: 0x0001

  def extend_error(0x0003), do: "Invalid search query"
  def extend_error(0x0002), do: "There is no user with that username"
  def extend_error(_), do: "This endpoint is currently unimplemented"

  defp interest_to_json([title, desc, inserted, edited, poster]) do
    poster_name = ExsemanticaPhx.Repo.one(from user in ExsemanticaPhx.Site.User, where: user.node_corresponding == ^poster, select: user.username)
    %{posted_by: poster_name, title: title, description: desc, inserted_on: inserted |> NaiveDateTime.diff(@unix_time), edited: edited |> NaiveDateTime.diff(@unix_time)}
  end

  defp user_to_json([user, biography, registered]) do
    %{username: user, biography: ExsemanticaPhx.Sanitize.truncate_string(biography, 256), registered_on: registered |> NaiveDateTime.diff(@unix_time)}
  end
end
