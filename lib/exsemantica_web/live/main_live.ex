defmodule ExsemanticaWeb.MainLive do
  @moduledoc """
  A live view that handles most logic in the site.
  """
  use ExsemanticaWeb, :live_view

  embed_templates "layouts/*"

  # ===========================================================================
  # Mount
  # ===========================================================================
  def mount(_params, _session, socket) when socket.assigns.live_action == :redirect_to_all do
    {:ok, socket |> push_redirect(to: ~p"/s/all")}
  end

  def mount(params, session, socket) do
    if socket |> connected? do
      socket =
        socket
        |> check_auth(session)
        |> assign(loading: false)
        |> push_event("transition-loader", %{})

      post_mount(params, session, socket)
    else
      {:ok, socket |> assign(loading: true, page_title: "Loading")}
    end
  end

  # ===========================================================================
  # After mounting has finished
  # ===========================================================================
  def post_mount(%{"username" => username}, _session, socket)
      when socket.assigns.live_action == :user do
    {:ok, socket |> assign(otype: :user, ident: username, page_title: "/u/" <> username)}
  end

  def post_mount(%{"aggregate" => "all"}, _session, socket)
      when socket.assigns.live_action == :aggregate do
    {:ok, socket |> assign(otype: :aggregate, ident: nil, page_title: "/s/all")}
  end

  def post_mount(%{"aggregate" => aggregate}, _session, socket)
      when socket.assigns.live_action == :aggregate do
    {:ok, socket |> assign(otype: :aggregate, ident: aggregate, page_title: "/s/" <> aggregate)}
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
          <.live_body_all />
          <.live_footer />
          """

        :aggregate ->
          ~H"""
          <.live_header myuser={assigns.myuser} />
          <.live_body_aggregate />
          <.live_footer />
          """

        :user ->
          ~H"""
          <.live_header myuser={assigns.myuser} />
          <.live_body_user />
          <.live_footer />
          """
      end
    end
  end

  # ===========================================================================
  # Private functions
  # ===========================================================================
  defp check_auth(socket, session) do
    case Exsemantica.Auth.check_token(session["guardian_default_token"]) do
      {:ok, myuser} ->
        socket |> assign(myuser: myuser.username)

      # TODO: I want to make an "expired session" message appear then clear.
      # I'm not quite sure how to clear it in LiveView cleanly.
      # Let's not implement this just yet
      {:error, _error} ->
        socket |> assign(myuser: nil)
    end
  end
end
