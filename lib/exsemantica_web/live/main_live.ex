defmodule ExsemanticaWeb.MainLive do
  @moduledoc """
  A live view that handles most logic in the site.
  """
  use ExsemanticaWeb, :live_view
  require Logger

  embed_templates "layouts/*"

  # ===========================================================================
  # Mount
  # ===========================================================================
  def mount(_params, _session, socket) when socket.assigns.live_action == :redirect_to_all do
    {:ok, socket |> push_navigate(to: ~p"/s/all")}
  end

  def mount(_params, session, socket) do
    {:ok,
     socket
     |> check_auth(session)
     |> assign(loading: true, t0: get_ms())}
  end

  # ===========================================================================
  # Handle parameters
  # ===========================================================================
  def handle_params(%{"username" => username}, _uri, socket) do
    {:noreply,
     socket
     |> start_async(:load_user, fn ->
       Exsemantica.Task.CheckUserName.run(%{guess: username})
     end)}
  end

  def handle_params(%{"aggregate" => "all"}, _uri, socket) do
    {:noreply, socket |> start_async(:load_all, fn -> :unimplemented end)}
  end

  def handle_params(%{"aggregate" => aggregate, "post" => post}, _uri, socket) do
    {:noreply,
     socket
     |> assign(post: post)
     |> start_async(:load_aggregate_post, fn ->
       Exsemantica.Task.CheckAggregateName.run(%{guess: aggregate})
     end)}
  end

  def handle_params(%{"aggregate" => aggregate}, _uri, socket) do
    {:noreply,
     socket
     |> start_async(:load_aggregate, fn ->
       Exsemantica.Task.CheckAggregateName.run(%{guess: aggregate})
     end)}
  end

  # ===========================================================================
  # Asynchronous event handling
  # ===========================================================================
  # ===== Load /u/___ =====
  def handle_async(:load_user, {:ok, %{name: name, identical?: false}}, socket) do
    {:noreply, socket |> redirect(to: ~p"/u/#{name}")}
  end

  def handle_async(
        :load_user,
        {:ok, %{id: id, name: name, identical?: true}},
        socket
      ) do
    ExsemanticaWeb.Endpoint.subscribe("post")

    {:noreply,
     socket
     |> assign(
       otype: :user,
       loading: false,
       delay: get_ms() - socket.assigns.t0,
       id: id,
       ident: name,
       page: 0,
       data:
         Exsemantica.Task.LoadUserPage.run(%{
           id: id,
           load_by: :newest,
           page: 0,
           fetch?: ~w(posts)a,
           options: %{preloads: ~w(votes)a}
         }),
       page_title: "Viewing /u/#{name}"
     )}
  end

  def handle_async(:load_user, {:ok, :not_found}, socket) do
    {:noreply,
     socket
     |> redirect(to: ~p"/s/all")
     |> put_flash(:error, gettext("That user does not exist"))}
  end

  # ===== Load /s/___ ======
  def handle_async(:load_aggregate, {:ok, %{name: name, identical?: false}}, socket) do
    {:noreply, socket |> redirect(to: ~p"/s/#{name}")}
  end

  def handle_async(:load_aggregate, {:ok, %{id: id, name: name, identical?: true}}, socket) do
    ExsemanticaWeb.Endpoint.subscribe("post")

    {:noreply,
     socket
     |> assign(
       otype: :aggregate,
       loading: false,
       delay: get_ms() - socket.assigns.t0,
       id: id,
       ident: name,
       page: 0,
       data:
         Exsemantica.Task.LoadAggregatePage.run(%{
           id: id,
           load_by: :newest,
           page: 0,
           fetch?: ~w(posts)a,
           options: %{preloads: ~w(votes)a}
         }),
       page_title: "Viewing /s/#{name}"
     )}
  end

  def handle_async(:load_aggregate, {:ok, :not_found}, socket) do
    {:noreply,
     socket
     |> push_patch(to: ~p"/s/all")
     |> put_flash(:error, gettext("That aggregate does not exist"))}
  end

  # ===== Load /s/___ post ======
  # Phase 1: find the aggregate
  def handle_async(:load_aggregate_post, {:ok, %{name: name, identical?: false}}, socket) do
    {:noreply, socket |> redirect(to: ~p"/s/#{name}")}
  end

  def handle_async(:load_aggregate_post, {:ok, %{id: id, name: name, identical?: true}}, socket) do
    {:noreply,
     socket
     |> assign(
       id: id,
       ident: name,
       page_title: "Viewing /s/#{name}"
     )
     |> start_async(:load_aggregate_post_contents, fn ->
       Exsemantica.Task.LoadPost.run(%{
         id: socket.assigns.post,
         aggregate_id: id,
         fetch?: ~w(contents)a,
         options: %{preloads: ~w(votes)a}
       })
     end)}
  end

  def handle_async(:load_aggregate_post, {:ok, :not_found}, socket) do
    {:noreply,
     socket
     |> push_patch(to: ~p"/s/all")
     |> put_flash(:error, gettext("That aggregate does not exist"))}
  end

  # Phase 2: Load the post
  def handle_async(:load_aggregate_post_contents, {:ok, %{post: post, info: info}}, socket) do
    {:noreply,
     socket
     |> assign(
       otype: :aggregate_post,
       loading: false,
       delay: get_ms() - socket.assigns.t0,
       data: post,
       comments: info
     )}
  end

  def handle_async(:load_aggregate_post_contents, {:ok, :not_found}, socket) do
    {:noreply,
     socket
     |> push_patch(to: ~p"/s/#{socket.assigns.ident}")
     |> put_flash(:error, gettext("That post does not exist"))}
  end

  def handle_async(:load_aggregate_post_contents, {:ok, :no_match}, socket) do
    {:noreply,
     socket
     |> push_patch(to: ~p"/s/all")
     |> put_flash(:error, gettext("That post does not belong to that aggregate"))}
  end

  # ===== Load /s/all =====
  def handle_async(:load_all, _async_fn_result, socket) do
    {:noreply,
     socket
     |> assign(
       otype: :aggregate,
       loading: false,
       delay: get_ms() - socket.assigns.t0,
       ident: nil,
       page_title: "Viewing /s/all"
     )}
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
      case assigns.otype do
        :aggregate when is_nil(assigns.ident) ->
          ~H"""
          <.live_header myuser={assigns.myuser} />
          <.live_body_all user_id={assigns.user_id} />
          <.live_footer time={assigns.delay} />
          """

        :aggregate ->
          ~H"""
          <.live_header myuser={assigns.myuser} />
          <div
            id="aggregate"
            phx-viewport-bottom={!assigns.data.info.posts.pages_ended? && "load-more-aggregate"}
          >
            <.live_body_aggregate user_id={assigns.user_id} data={assigns.data} />
          </div>
          <.live_footer time={assigns.delay} />
          """

        :user ->
          ~H"""
          <.live_header myuser={assigns.myuser} />
          <div id="user" phx-viewport-bottom={!assigns.data.info.posts.pages_ended? && "load-more-user"}>
            <.live_body_user user_id={assigns.user_id} data={assigns.data} />
          </div>
          <.live_footer time={assigns.delay} />
          """
      end
    end
  end

  # ===========================================================================
  # Handle info
  # ===========================================================================
    # On vote update
  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "post",
          event: "recounted_votes",
          payload: %{id: post_id, vote_count: vote_count}
        },
        socket
      ) do
    {:noreply,
     case socket.assigns.otype do
       :aggregate when is_nil(socket.assigns.ident) ->
         socket

       :aggregate ->
         old_data = socket.assigns.data
         path = [:info, :posts, :votes]

         new_data =
           if Map.has_key?(get_in(old_data, path), post_id) do
             old_data |> put_in(path ++ [post_id], vote_count)
           else
             old_data
           end

         socket |> assign(data: new_data)

       :user ->
         socket
     end}
  end

  # ===========================================================================
  # Handle infinite scrolling
  # ===========================================================================
  # TODO: we really need to make a "reload" indicator
  # POSSIBLE IMPLEMENTATION: check load timestamp vs. last SQL table modification
  def handle_event("load-more-aggregate", _unsigned_params, socket) do
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

  def handle_event("load-more-user", _unsigned_params, socket) do
    data =
      Exsemantica.Task.LoadUserPage.run(%{
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
  # Private functions
  # ===========================================================================
  defp check_auth(socket, session) do
    case Exsemantica.Auth.check_token(session["guardian_default_token"]) do
      {:ok, myuser} ->
        socket |> assign(myuser: myuser.username, user_id: myuser.id)

      # TODO: I want to make an "expired session" message appear then clear.
      # I'm not quite sure how to clear it in LiveView cleanly.
      # Let's not implement this just yet
      {:error, _error} ->
        socket |> assign(myuser: nil, user_id: nil)
    end
  end

  defp get_ms, do: DateTime.utc_now() |> DateTime.to_unix(:millisecond)
end
