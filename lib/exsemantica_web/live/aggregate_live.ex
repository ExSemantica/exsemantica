defmodule ExsemanticaWeb.AggregateLive do
  use ExsemanticaWeb, :live_view
  require Logger

  embed_templates "layouts/*"

  # ===========================================================================
  # Mount
  # ===========================================================================
  def mount(_params, session, socket) do
    socket = socket |> assign(user_handle: session["user_handle"], user_id: session["user_id"])

    {:ok,
     case session["user_auth"] do
       :token_expired -> socket |> put_flash(:error, gettext("Your session has expired."))
       _ -> socket
     end
     |> assign(loading: true, t0: DateTime.utc_now() |> DateTime.to_unix(:millisecond))}
  end

  # ===========================================================================
  # Handle parameters
  # ===========================================================================
  def handle_params(%{"aggregate" => aggregate}, _uri, socket) do
    {:noreply,
     socket
     |> start_async(:load, fn ->
       Exsemantica.Task.CheckAggregateName.run(%{guess: aggregate})
     end)}
  end

  # ===========================================================================
  # Handle asynchronous events
  # ===========================================================================
  # NOT identical, redirect
  def handle_async(:load, {:ok, %{name: name, identical?: false}}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/s/#{name}")}
  end

  # IS identical, let's load our page then
  def handle_async(:load, {:ok, %{id: id, name: name, identical?: true}}, socket) do
    ExsemanticaWeb.Endpoint.subscribe("aggregate:#{id}")

    {:noreply,
     socket
     |> assign(
       loading: false,
       delay: (DateTime.utc_now() |> DateTime.to_unix(:millisecond)) - socket.assigns.t0,
       id: id,
       name: name,
       page: 0,
       data:
         Exsemantica.Task.LoadAggregatePage.run(%{
           id: id,
           load_by: :newest,
           page: 0,
           fetch?: ~w(posts tags moderators)a,
           options: %{}
         }),
       page_title: "Viewing /s/#{name}"
     )}
  end

  # Nonexistant
  def handle_async(:load, {:ok, :not_found}, socket) do
    {:noreply,
     socket
     |> redirect(to: ~p"/s/all")
     |> put_flash(:error, gettext("That aggregate does not exist"))}
  end

  # ===========================================================================
  # Handle general events
  # ===========================================================================
  # Infinite scrolling
  # TODO: we really need to make a "reload" indicator
  # POSSIBLE IMPLEMENTATION: check load timestamp vs. last SQL table modification
  def handle_event("load-more", _unsigned_params, socket) do
    data =
      Exsemantica.Task.LoadAggregatePage.run(%{
        id: socket.assigns.id,
        load_by: :newest,
        page: socket.assigns.page + 1,
        fetch?: ~w(posts)a,
        options: %{preloads: ~w(votes)a}
      })

    old_info = socket.assigns.data.info

    new_info = %{
      old_info
      | posts: %{
          old_info.posts
          | contents: List.flatten(old_info.posts.contents, data.info.posts.contents),
            votes: Map.merge(old_info.posts.votes, data.info.posts.votes),
            pages_began?: data.info.posts.pages_began?,
            pages_total: data.info.posts.pages_total,
            pages_ended?: data.info.posts.pages_ended?
        }
    }

    {:noreply,
     socket
     |> assign(
       data: %{socket.assigns.data | info: new_info},
       page: socket.assigns.page + 1
     )}
  end

  # ===========================================================================
  # Handle process message events
  # ===========================================================================
  # Update my votes
  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: topic,
          event: "recounted_votes",
          payload: %{id: post_id, vote_count: vote_count}
        },
        socket
      ) do
    if topic == "aggregate:#{socket.assigns.id}" do
      old_data = socket.assigns.data
      path = ~w(info posts votes)a

      new_data =
        if Map.has_key?(get_in(old_data, path), post_id) do
          # TODO: Is this efficient or is there another way?
          old_data |> put_in(path ++ [post_id], vote_count)
        else
          old_data
        end

      {:noreply, socket |> assign(data: new_data)}
    else
      {:noreply, socket}
    end
  end

  # ===========================================================================
  # Render
  # ===========================================================================
  def render(assigns) do
    if assigns.loading do
      ~H"""
      <.live_loader />
      """
    else
      ~H"""
      <.live_header myuser={assigns.user_handle} />
      <div id="aggregate" phx-viewport-bottom={!assigns.data.info.posts.pages_ended? && "load-more"}>
        <.live_body_aggregate user_id={assigns.user_id} data={assigns.data} />
      </div>
      <.live_footer time={assigns.delay} />
      """
    end
  end
end
