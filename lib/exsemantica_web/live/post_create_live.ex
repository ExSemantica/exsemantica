defmodule ExsemanticaWeb.PostCreateLive do
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
       :ok ->
         socket

       :token_expired ->
         socket
         |> push_navigate(to: ~p"/s/all")
         |> put_flash(:error, gettext("Your session has expired."))

       _ ->
         socket
         |> push_navigate(to: ~p"/s/all")
         |> put_flash(:error, gettext("You're not logged in."))
     end
     |> assign(loading: true, t0: DateTime.utc_now() |> DateTime.to_unix(:millisecond))}
  end

  # ===========================================================================
  # Handle parameters
  # ==========================================================================

  def handle_params(%{"aggregate" => aggregate}, _uri, socket) do
    {:noreply,
     socket
     |> start_async(:load, fn ->
       Exsemantica.Task.CheckAggregateName.run(%{guess: aggregate})
     end)}
  end

  # ===========================================================================
  # Handle events
  # ===========================================================================
  def handle_event(
        "submit",
        %{
          "contents" => contents,
          "tags" => tags,
          "title" => title,
          "type" => type
        },
        socket
      ) do
    type_atom =
      case type do
        "self" -> :self
        "link" -> :link
      end

    {:noreply,
     socket
     |> start_async(:post, fn ->
       {:ok, post} =
         Exsemantica.Task.CreatePost.run(%{
           user_id: socket.assigns.user_id,
           aggregate_id: socket.assigns.id,
           post_data: %{
             type: type_atom,
             title: title,
             contents: contents,
             tags: tags |> String.split(" ", trim: true) |> Enum.uniq()
           }
         })

       post
     end)}
  end

  # ===========================================================================
  # Handle asynchronous events
  # ===========================================================================
  # NOT identical, redirect
  def handle_async(:load, {:ok, %{name: name, identical?: false}}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/s/#{name}/create")}
  end

  # IS identical, let's load our page then
  def handle_async(:load, {:ok, %{id: id, name: name, identical?: true}}, socket) do
    {:noreply,
     socket
     |> assign(
       loading: false,
       delay: (DateTime.utc_now() |> DateTime.to_unix(:millisecond)) - socket.assigns.t0,
       id: id,
       name: name,
       data:
         Exsemantica.Task.LoadAggregatePage.run(%{
           id: id,
           fetch?: ~w(tags moderators)a,
           options: %{}
         }),
       page_title: "Posting in /s/#{name}"
     )}
  end

  # Nonexistant
  def handle_async(:load, {:ok, :not_found}, socket) do
    {:noreply,
     socket
     |> push_navigate(to: ~p"/s/all")
     |> put_flash(:error, gettext("That aggregate does not exist"))}
  end

  def handle_async(:post, {:ok, _post}, socket) do
    {:noreply,
     socket
     |> push_navigate(to: ~p"/s/#{socket.assigns.name}")
          |> put_flash(:info, gettext("Posted successfully"))}
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
      <.live_body_post_create user_id={assigns.user_id} data={assigns.data} post={%{}} />
      <.live_footer time={assigns.delay} />
      """
    end
  end
end
