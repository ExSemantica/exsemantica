defmodule ExsemanticaWeb.Components.AggregatePageView do
  use ExsemanticaWeb, :live_component

  def mount(socket) do
    {:ok, socket |> assign(page: 0)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-bold">/s/<%= assigns.aggregate %></h1>
    </div>
    """
  end
end
