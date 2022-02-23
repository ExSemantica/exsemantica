defmodule ExsemanticaWeb.LayoutLive do
  use ExsemanticaWeb, :live_view

  require Exsemnesia.Handle128

  @max_search_entries 250

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       [
         trend_search_status: "<i>Please enter your query.</i>",
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
             get_in(trends, [:data, "trending"]) |> Enum.count(&(&1["relevance"] > 0.707))
           )
           |> Phoenix.HTML.raw()
         )
     end}
  end
end
