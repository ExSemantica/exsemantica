defmodule ExsemanticaWeb.Components.AggregatePageView do
  @moduledoc """
  Shows a certain range of an aggregate's post cards into a HEEx page.
  """
  use ExsemanticaWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <%= if assigns.info.posts.contents == [] do %>
        <p><%= gettext("This aggregate does not have any posts.") %></p>
      <% else %>
        <%= for entry <- assigns.info.posts.contents do %>
          <.live_component
            module={ExsemanticaWeb.Components.PostCard}
            where={:aggregate}
            entry={entry}
            votes={assigns.info.posts.votes[entry.id]}
            user_id={assigns.user_id}
            id={entry}
          />
        <% end %>
      <% end %>
    </div>
    """
  end
end
