defmodule ExsemanticaWeb.LayoutLive do
  use ExsemanticaWeb, :live_view

  def render(assigns) do
    ~H"This should never appear!!!"
  end

  def handle_event("query_preflight", %{"search" => %{"entry" => entry}}, socket) do
    IO.inspect "entry: #{entry}"
    {:noreply, socket}
  end
end
