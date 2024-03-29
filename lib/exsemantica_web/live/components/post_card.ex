defmodule ExsemanticaWeb.Components.PostCard do
  @moduledoc """
  Shows a post title, along with whether it is a self or a link post.
  """
  use ExsemanticaWeb, :live_component

  @max_post_synopsis 80

  def render(assigns) do
    ~H"""
    <div
      class="transition-opacity duration-500 opacity-0 bg-gray-100 shadow-xl m-4 p-4 flex flex-row"
      phx-mounted={JS.remove_class("opacity-0")}
    >
      <div class="w-full">
        <div class="float-left min-h-full">
          <%= case assigns.entry.type do %>
            <% :link -> %>
              <.icon name="hero-link" class="m-4 w-8 h-8" />
            <% :self -> %>
              <.icon name="hero-document" class="m-4 w-8 h-8" />
          <% end %>
        </div>
        <h2 class="text-xl font-bold"><%= assigns.entry.title %></h2>
        <p>
          <%= assigns.entry.contents |> String.split(["\r", "\n"]) |> List.first("") |> make_synopsis %>
        </p>
        <%= for tag <- assigns.entry.tags do %>
          <span class="text-sm rounded-full bg-slate-300 px-2">#<%= tag %></span>
        <% end %>
        <%= case assigns.where do %>
          <% :aggregate -> %>
            <p>
              <.link navigate={~p"/u/#{assigns.entry.user.username}"}>
                <i class="text-xs text-blue-900">
                  <%= gettext("Posted by /u/%{poster}",
                    poster: assigns.entry.user.username
                  ) %>
                </i>
              </.link>
            </p>
          <% :user -> %>
            <.link navigate={~p"/s/#{assigns.entry.aggregate.name}"}>
              <p>
                <i class="text-xs text-blue-900">
                  <%= gettext("Posted in /s/%{aggregate}",
                    aggregate: assigns.entry.aggregate.name
                  ) %>
                </i>
              </p>
            </.link>
        <% end %>
      </div>
      <div class="text-center w-8 m-auto">
        <%= if is_nil(assigns.user_id) do %>
          <p class="text-2xl"><%= assigns.votes %></p>
        <% else %>
          <p>
            <a href="#" phx-click="upvote" phx-target={assigns.myself}>
              <.icon name="hero-arrow-up" />
            </a>
          </p>
          <p class="text-2xl"><%= assigns.votes %></p>
          <p>
            <a href="#" phx-click="downvote" phx-target={assigns.myself}>
              <.icon name="hero-arrow-down" />
            </a>
          </p>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("upvote", _unsigned_params, socket) do
    {:ok, vote_count} =
      Exsemantica.Task.PerformVote.run(%{
        id: socket.assigns.entry.id,
        user_id: socket.assigns.user_id,
        type: :post,
        vote_type: :upvote
      })

    socket |> recount_broadcast(vote_count)

    {:noreply, socket}
  end

  def handle_event("downvote", _unsigned_params, socket) do
    {:ok, vote_count} =
      Exsemantica.Task.PerformVote.run(%{
        id: socket.assigns.entry.id,
        user_id: socket.assigns.user_id,
        type: :post,
        vote_type: :downvote
      })

    socket |> recount_broadcast(vote_count)

    {:noreply, socket}
  end

  defp make_synopsis(str) do
    if String.length(str) > @max_post_synopsis do
      (str |> String.slice(0..@max_post_synopsis) |> String.trim_trailing()) <> "..."
    else
      str
    end
  end

  defp recount_broadcast(socket, vote_count) do
    ExsemanticaWeb.Endpoint.broadcast(
      "aggregate:#{socket.assigns.entry.aggregate.id}",
      "recounted_votes",
      %{
        id: socket.assigns.entry.id,
        vote_count: vote_count
      }
    )

    ExsemanticaWeb.Endpoint.broadcast(
      "user:#{socket.assigns.entry.user.id}",
      "recounted_votes",
      %{
        id: socket.assigns.entry.id,
        vote_count: vote_count
      }
    )
  end
end
