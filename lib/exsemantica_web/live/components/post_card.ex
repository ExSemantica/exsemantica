defmodule ExsemanticaWeb.Components.PostCard do
  use ExsemanticaWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-bold">/s/<%= assigns.title %></h2>
    </div>
    """
  end
end
