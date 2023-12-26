defmodule ExsemanticaWeb.Components.UserPageView do
  @moduledoc """
  Shows a certain range of a user's post cards into a HEEx page.
  """
  use ExsemanticaWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-bold">/u/<%= assigns.username %></h1>
      <%= if assigns.page_info.contents == [] do %>
        <p><%= gettext("This user hasn't posted.") %></p>
      <% else %>
        <%= for entry <- assigns.page_info.contents do %>
          <.live_component module={ExsemanticaWeb.Components.PostCard} title="foo card" id={entry} />
        <% end %>
      <% end %>
    </div>
    """
  end
end
