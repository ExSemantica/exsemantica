defmodule ExsemanticaWeb.InterestLive do
  use ExsemanticaWeb, :live_view

  require Exsemnesia.Handle128
  require Logger

  def mount(params, session, socket) do
    {:atomic, [recase]} =
      [
        Exsemnesia.Utils.get_recase(
          String.downcase(Exsemnesia.Handle128.serialize(params["interest"]), :ascii)
        )
      ]
      |> Exsemnesia.Database.transaction("downcase find interest")

    {header, body} =
      case recase.response do
        [] ->
          {"Interest not found", "The interest was either deleted or not created at all."}

        [{:lowercases, handle, _lowercase}] ->
          {:atomic, [entry]} =
            [
              Exsemnesia.Utils.get_by_handle(
                :interests,
                handle
              )
            ]
            |> Exsemnesia.Database.transaction("find handle for entry")

            # TODO: related to...
          [{:interests, _node, timestamp, _handle, title, content, _related_to}] = entry.response
          safe_title = Phoenix.HTML.html_escape(title) |> Phoenix.HTML.safe_to_string()
          safe_content = Phoenix.HTML.html_escape(content) |> Phoenix.HTML.safe_to_string()
          timestamp_8601 = timestamp |> DateTime.to_iso8601()

          {handle,
           """
           <h3 class="font-bold">#{safe_title}</h3>
           <br>
           #{safe_content}
           <br>
           <small>Submitted on #{timestamp_8601}</small>
           """}
      end

    {:ok,
     socket
     |> ExsemanticaWeb.LayoutLive.login(
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
         dyn_header: header,
         dyn_text: body,
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
    {:noreply, ExsemanticaWeb.LayoutLive.prequery(socket, entry)}
  end

  def handle_event("query_submit", %{"search" => %{"entry" => entry}}, socket) do
    {:noreply,
     socket
     |> push_redirect(to: Routes.live_path(socket, ExsemanticaWeb.SearchLive, query: entry))}
  end
end
