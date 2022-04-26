defmodule ExsemanticaWeb.ExsemFeedChannel do
  use ExsemanticaWeb, :channel

  @impl true
  def join("exsem_feed:home", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:ok, socket}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("load_feed", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (exsem_feed:lobby).
  @impl true
  def handle_in(
        "cons_post",
        %{user: user, handle: handle, title: title, content: content},
        socket
      ) do
    Exsemnesia.Utils.put_post(handle, title, content, user)
    |> Exsemnesia.Database.transaction("finish off a post")

    broadcast(socket, "cons_post", %{
      user: user,
      handle: handle,
      title: title,
      content: content
    })

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(payload) do
    case payload do
      %{user: user, token: token} -> case Exsemnesia.Utils.check_user(user, token) do
        {:ok, _} -> true
        _ -> false
      end
      _ -> false
    end
  end
end
