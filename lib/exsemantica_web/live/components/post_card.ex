defmodule ExsemanticaWeb.Components.PostCard do
  @moduledoc """
  Shows a post title, along with whether it is a self or a link post.
  """
  use ExsemanticaWeb, :live_component

  @max_post_synopsis 80

  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 shadow-xl m-4 p-4 flex flex-row">
      <div class="w-full">
        <%= case assigns.entry.type do %>
          <% :link -> %>
            <.icon name="hero-link" class="float-left m-4 w-8 h-8" />
          <% :self -> %>
            <.icon name="hero-document" class="float-left m-4 w-8 h-8" />
        <% end %>
        <h2 class="text-xl font-bold"><%= assigns.entry.title %></h2>
        <p>
          <%= assigns.entry.contents |> String.split(["\r", "\n"]) |> List.first() |> make_synopsis %>
        </p>
        <%= case assigns.where do %>
          <% :aggregate -> %>
            <.link navigate={~p"/u/#{assigns.entry.user.username}"}>
              <i class="text-xs text-blue-900">
                <%= gettext("Posted by /u/%{poster}",
                  poster: assigns.entry.user.username
                ) %>
              </i>
            </.link>
          <% :user -> %>
            <.link navigate={~p"/s/#{assigns.entry.aggregate.name}"}>
              <i class="text-xs text-blue-900">
                <%= gettext("Posted in /s/%{aggregate}",
                  aggregate: assigns.entry.aggregate.name
                ) %>
              </i>
            </.link>
        <% end %>
      </div>
      <div class="text-center w-8">
        <p><.icon name="hero-arrow-up" /></p>
        <p class="text-2xl"><%= assigns.votes %></p>
        <p><.icon name="hero-arrow-down" /></p>
      </div>
    </div>
    """
  end

  defp make_synopsis(str) do
    if String.length(str) > @max_post_synopsis do
      (str |> String.slice(0..@max_post_synopsis) |> String.trim_trailing()) <> "..."
    else
      str
    end
  end
end
