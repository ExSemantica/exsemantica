defmodule ExsemanticaWeb.LayoutLive do
  use ExsemanticaWeb, :live_view

  require Exsemnesia.Handle128
  require Logger

  @max_search_entries 48
  @algorithm 0.707

  def login(socket, user) do
    case user do
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
  end

  def prequery(socket, query) do
    cond do
      not Exsemnesia.Handle128.is_valid(query) ->
        socket
        |> assign(
          :trend_search_status,
          "<i>Please enter in an alphanumeric string of <b>16 characters</b> or less.</i>"
          |> Phoenix.HTML.raw()
        )

      Exsemnesia.Handle128.serialize(query) == :error ->
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
              "fuzz" => Exsemnesia.Handle128.serialize(query)
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
    end
  end

  def mount(_params, session, socket) do
    {:ok, socket} = ExsemanticaWeb.ExsemFeedChannel.join("exsem_feed:home", nil, socket)
    {:ok,
     socket
     |> login(
       Exsemnesia.Utils.check_user(session["exsemantica_handle"], session["exsemantica_paseto"])
     )
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
    {:noreply, prequery(socket, entry)}
  end

  def handle_event("query_submit", %{"search" => %{"entry" => entry}}, socket) do
    {:noreply,
     socket
     |> push_redirect(to: Routes.live_path(socket, ExsemanticaWeb.SearchLive, query: entry))}
  end
end
