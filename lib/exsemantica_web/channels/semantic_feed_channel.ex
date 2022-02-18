defmodule ExsemanticaWeb.SemanticFeedChannel do
  use ExsemanticaWeb, :channel

  @queries %{
    trending: """
    {
      trending(count: 5) {
        type, name
      }
    }
    """
  }

  @impl true
  def join("semantic_feed:home", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("check", payload, socket) do
    {:reply,
     payload
     |> Enum.uniq()
     |> Map.new(fn sub ->
       case sub do
         "trending" ->
           {:ok, raw} = @queries[:trending] |> Absinthe.run(ExsemanticaWeb.Schema)
           {:trending, raw |> get_in([:data, "trending"])}

         "server_time" ->
           {:server_time,
            DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()}
       end
     end)
     |> Jason.encode(), socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (semantic_feed:lobby).
  # @impl true
  # def handle_in("shout", payload, socket) do
  #   broadcast(socket, "shout", payload)
  #   {:noreply, socket}
  # end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
