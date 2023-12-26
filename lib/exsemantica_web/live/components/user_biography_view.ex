defmodule ExsemanticaWeb.Components.UserBiographyView do
  use ExsemanticaWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-bold">Biography</h2>
      <p class="text-md"><%= assigns.biography %></p>
    </div>
    """
  end
end
