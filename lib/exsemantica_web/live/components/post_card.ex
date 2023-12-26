defmodule ExsemanticaWeb.Components.PostCard do
  @moduledoc """
  Shows a post title, along with whether it is a self or a link post.
  """
  use ExsemanticaWeb, :live_component

  @max_post_synopsis 64

  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 shadow-xl m-4 p-4">
      <%= case assigns.type do %>
        <% :link -> %>
          <.icon name="hero-link" class="float-left m-4 w-8 h-8" />
        <% :self -> %>
          <.icon name="hero-document" class="float-left m-4 w-8 h-8" />
      <% end %>
      <h2 class="text-xl font-bold"><%= assigns.title %></h2>
      <p>
        <%= assigns.contents |> String.split(["\r", "\n"]) |> List.first() |> make_synopsis %>
      </p>
      <%= case assigns.where do %>
        <% :aggregate -> %>
          <.link navigate={~p"/u/#{assigns.poster}"}>
            <i class="text-xs text-blue-900">
              <%= gettext("Posted by /u/%{poster}",
                poster: assigns.poster
              ) %>
            </i>
          </.link>
        <% :user -> %>
          <.link navigate={~p"/s/#{assigns.aggregate}"}>
            <i class="text-xs text-blue-900">
              <%= gettext("Posted in /s/%{aggregate}",
                aggregate: assigns.aggregate
              ) %>
            </i>
          </.link>
      <% end %>
    </div>
    """
  end

  defp make_synopsis(str) do
    if String.length(str) > @max_post_synopsis do
      (str |> String.slice(0..@max_post_synopsis)) <> "..."
    else
      str
    end
  end
end
