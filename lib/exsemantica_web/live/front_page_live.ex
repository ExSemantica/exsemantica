defmodule ExsemanticaWeb.FrontPageLive do
  use ExsemanticaWeb, :live_view
  require Logger

  embed_templates "layouts/*"

  # ===========================================================================
  # Mount
  # ===========================================================================
  def mount(_params, _session, socket) when socket.assigns.live_action == :redirect do
    {:ok, socket |> push_patch(to: ~p"/s/all")}
  end

  def mount(_params, session, socket) do
    socket = socket |> assign(user_handle: session["user_handle"], user_id: session["user_id"])

    {:ok,
     case session["user_auth"] do
       :token_expired -> socket |> put_flash(:error, gettext("Your session has expired."))
       _ -> socket
     end
     |> assign(loading: true, t0: DateTime.utc_now() |> DateTime.to_unix(:millisecond))
     |> start_async(:load, fn ->
       # TODO: make front page
       :unimplemented
     end)}
  end

  # ===========================================================================
  # Handle asynchronous events
  # ===========================================================================
  def handle_async(:load, {:ok, :unimplemented}, socket) do
    {:noreply,
     socket
     |> assign(
       loading: false,
       delay: (DateTime.utc_now() |> DateTime.to_unix(:millisecond)) - socket.assigns.t0
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
      ~H"""
      <.live_header myuser={assigns.user_handle} />
      <.live_body_all user_id={assigns.user_id} />
      <.live_footer time={assigns.delay} />
      """
    end
  end
end
