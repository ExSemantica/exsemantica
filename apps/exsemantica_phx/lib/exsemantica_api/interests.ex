defmodule ExsemanticaApi.Interests do
  require Logger
  import Ecto.Query
  use ExsemanticaApi.RateLimited

  @qmax_limit 30
  @unix_time ~N[1970-01-01 00:00:00]

  @impl true
  def handle_pressure(_agent, _idx, extra) do
    {qmax, _} = Integer.parse(get_in(extra, [:query_params, "qmax"]) || "0")

    cond do
      qmax > 0 -> %{global: 1, extra: extra}
      true -> %{global: 2, extra: extra}
    end
    |> put_in([:extra, :qmax], if(qmax > @qmax_limit, do: @qmax_limit, else: qmax))
  end

  @impl true
  def handle_use(_agent, context, _idx, %{:qmax => qmax} = extra) do
    query = get_in(extra, [:query_params, "q"]) || ""
    query_valid = ExsemanticaPhx.Sanitize.valid_interest?(query)

    {:reply, context,
     case extra.method do
       "GET" ->
         cond do
           qmax > 0 and query_valid ->
             result =
               ExsemanticaPhx.Search.interests("%" <> query <> "%", [limit: qmax], :query)
               |> Enum.map(&to_json/1)

             {:ok, json} = Jason.encode(%{d: result, n: length(result)})
             {200, json}

           query_valid ->
             result = ExsemanticaPhx.Search.interests("%" <> query <> "%", [], :count)
             {:ok, json} = Jason.encode(%{n: result})
             {200, json}

           true ->
             {:ok, json} = Jason.encode(%{error: true, message: "Malformed query."})
             {400, json}
         end

       _ ->
         {:ok, json} =
           Jason.encode(%{error: true, message: "This method is currently unimplemented."})

         {501, json}
     end}
  end

  @impl true
  def handle_local_throttle(agent, context, idx, _extra) do
    Logger.info("Agent #{agent} with ID #{inspect(idx)} rate limited.")
    {:ok, json} = Jason.encode(%{error: true, message: "You are being rate limited."})
    {:reply, context, {429, json}}
  end

  @impl true
  def handle_global_throttle(agent, context, idx, _extra) do
    Logger.warn("Agent #{agent} with ID #{inspect(idx)} is inducing a global throttle!")
    {:ok, json} = Jason.encode(%{error: true, message: "The server is being rate limited."})
    {:reply, context, {429, json}}
  end


  def to_json([title, desc, inserted, edited, poster]) do
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
