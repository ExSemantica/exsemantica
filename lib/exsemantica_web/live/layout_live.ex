defmodule ExsemanticaWeb.LayoutLive do
  use ExsemanticaWeb, :live_view

  require Exsemnesia.Handle128
  require Logger

  @max_search_entries 48
  @algorithm 0.707
  def mount(_params, _session, socket) do
    user = Exsemnesia.Utils.check_user(get_connect_params(socket)["handle"], get_connect_params(socket)["paseto"])
    socket = case user do
      {:ok, user} ->
        {:atomic, [remapped]} =
          [Exsemnesia.Utils.do_case(user.handle)]
          |> Exsemnesia.Database.transaction("redetermine case")

        [{:lowercases, upcased, _}] = remapped.response

        socket
        |> assign(
          login_who: upcased,
          login_prompt: "Log out",
          profile_picture:
            Routes.static_path(ExsemanticaWeb.Endpoint, "/images/unassigned_64x.webp")
        )

      {:error, err} ->
        Logger.warn(inspect(err))

        socket
        |> assign(
          login_who: "Not logged in",
          login_prompt: "Log in",
          profile_picture:
            Routes.static_path(ExsemanticaWeb.Endpoint, "/images/unassigned_64x.webp")
        )
    end

    {:ok,
     socket
     |> assign(
       [
         trend_search_status: "<i>Please enter your query.</i>",
         main_hello: "Welcome to ExSemantica",
         main_text: """
         <p><i>A free and open source microblogging and messaging platform for people who share interests.</i></p>
         <br>
         <p>Check the sidebar to see what's popular. Below is either a search results page or an interest feed.</p>
         """,
         dyn_header: "Search for interests",
         dyn_text: "Please search for something.",
         login_nag: "<i>Please enter a handle, a string with 16 characters or less.</i><br>"
       ]
       |> Enum.map(fn {k, v} ->
         {k, v |> Phoenix.HTML.raw()}
       end)
     )}
  end

  def render(assigns) do
    ~H"This should never appear."
  end

  def handle_event("query_preflight", %{"search" => %{"entry" => entry}}, socket) do
    {:noreply,
     cond do
       not Exsemnesia.Handle128.is_valid(entry) ->
         socket
         |> assign(
           :trend_search_status,
           "<i>Please enter in an alphanumeric string of <b>16 characters</b> or less.</i>"
           |> Phoenix.HTML.raw()
         )

       Exsemnesia.Handle128.serialize(entry) == :error ->
         socket
         |> assign(
           :trend_search_status,
           "<i>Please enter only alphanumeric characters.</i>"
           |> Phoenix.HTML.raw()
         )

       true ->
         {:ok, trends} =
           """
           query SearchTrends($cnt: Int, $fuzz: String) {
             trending(count: $cnt, fuzzy: $fuzz) {
               relevance
             }
           }
           """
           |> Absinthe.run(ExsemanticaWeb.Schema,
             variables: %{
               "cnt" => @max_search_entries,
               "fuzz" => Exsemnesia.Handle128.serialize(entry)
             }
           )

         socket
         |> assign(
           :trend_search_status,
           ExsemanticaWeb.Gettext.ngettext(
             "<i>Approximately <b>%{count}</b> trend found</i>",
             "<i>Approximately <b>%{count}</b> trends found</i>",
             get_in(trends, [:data, "trending"]) |> Enum.count(&(&1["relevance"] > @algorithm))
           )
           |> Phoenix.HTML.raw()
         )
     end}
  end

  def handle_event("query_submit", %{"search" => %{"entry" => entry}}, socket) do
    {:noreply,
     cond do
       not Exsemnesia.Handle128.is_valid(entry) ->
         socket

       Exsemnesia.Handle128.serialize(entry) == :error ->
         socket

       true ->
         {:ok, trends} =
           """
           query SearchTrends($cnt: Int, $fuzz: String) {
             trending(count: $cnt, fuzzy: $fuzz) {
               handle, type, relevance
             }
           }
           """
           |> Absinthe.run(ExsemanticaWeb.Schema,
             variables: %{
               "cnt" => @max_search_entries,
               "fuzz" => Exsemnesia.Handle128.serialize(entry)
             }
           )

         trends_filt =
           get_in(trends, [:data, "trending"]) |> Enum.sort_by(& &1["relevance"], :desc)

         socket
         |> assign(
           [
             dyn_header:
               ExsemanticaWeb.Gettext.ngettext(
                 "<i><b>%{count}</b> trend found</i>",
                 "<i><b>%{count}</b> trends found</i>",
                 length(trends_filt)
               ),
             dyn_text: trends_filt |> Enum.map(&show_search_result/1) |> Enum.join()
           ]
           |> Enum.map(fn {k, v} ->
             {k, v |> Phoenix.HTML.raw()}
           end)
         )
     end}
  end

  defp show_search_result(item) do
    case item["type"] do
      "users" ->
        """
        <div class="transition bg-amber-200 duration-0 hover:bg-amber-100 hover:duration-200 m-2 p-2 w-1/3 rounded-xl">
        <h2>#{item["handle"]}</h2>

        <br>
        <small><i>User</i> - r#{item["relevance"]}</small>
        </div>
        """

      "interests" ->
        """
        <div class="transition bg-lime-200 duration-0 hover:bg-lime-100 hover:duration-200 m-2 p-2 w-1/3 rounded-xl">
        <h2>#{item["handle"]}</h2>

        <br>
        <small><i>Interest</i> - r#{item["relevance"]}</small>
        </div>
        """

      "posts" ->
        """
        <div class="transition bg-cyan-200 duration-0 hover:bg-cyan-100 hover:duration-200 m-2 p-2 w-1/3 rounded-xl">
        <h2>#{item["handle"]}</h2>

        <br>
        <small><i>Post</i> - r#{item["relevance"]}</small>
        </div>
        """
    end
  end
end
