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

  def handle_params(%{"aggregate" => aggregate}, _uri, socket) do
    {:noreply,
     socket
     |> start_async(:load_aggregate, fn ->
       Exsemantica.Task.CheckUserName.run(%{guess: aggregate})
     end)}
  end

  # ===========================================================================
  # Asynchronous event handling
  # ===========================================================================
  # ===== Load /u/___ =====
  def handle_async(:load_user, {:ok, %{name: name, identical?: false}}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/u/#{name}")}
  end

  def handle_async(:load_user, {:ok, %{id: id, name: name, identical?: true}}, socket) do
    {:noreply,
     socket
     |> assign(
       otype: :user,
       loading: false,
       delay: get_ms() - socket.assigns.t0,
       ident: name,
       data: Exsemantica.Task.LoadUserPage.run(%{id: id, load_by: :newest, page: 0})
     )}
  end

  def handle_async(:load_aggregate, {:ok, :not_found}, socket) do
    {:noreply,
     socket
     |> push_patch(to: ~p"/s/all")
     |> put_flash(:error, gettext("That aggregate does not exist"))}
  end

  # ===== Load /s/___ ======
  def handle_async(:load_aggregate, {:ok, %{name: name, identical?: false}}, socket) do
    {:noreply, socket |> redirect(to: ~p"/s/#{name}")}
  end

  def handle_async(:load_aggregate, {:ok, %{id: id, name: name, identical?: true}}, socket) do
    {:noreply,
     socket
     |> assign(
       otype: :aggregate,
       loading: false,
       delay: get_ms() - socket.assigns.t0,
       ident: name,
       data: Exsemantica.Task.LoadAggregatePage.run(%{id: id, load_by: :newest, page: 0})
     )}
  end

  def handle_async(:load_user, {:ok, :not_found}, socket) do
    {:noreply,
     socket
     |> push_patch(to: ~p"/s/all")
     |> put_flash(:error, gettext("That user does not exist"))}
  end

  # ===== Load /s/all =====
  def handle_async(:load_all, _async_fn_result, socket) do
    {:noreply,
     socket
     |> assign(
       otype: :aggregate,
       loading: false,
       delay: get_ms() - socket.assigns.t0,
       ident: nil
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
          <.live_body_all />
          <.live_footer time={assigns.delay} />
          """

        :aggregate ->
          ~H"""
          <.live_header myuser={assigns.myuser} />
          <.live_body_aggregate aggregate={assigns.ident} />
          <.live_footer time={assigns.delay} />
          """

        :user ->
          ~H"""
          <.live_header myuser={assigns.myuser} />
          <.live_body_user />
          <.live_footer time={assigns.delay} />
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

  defp get_ms, do: DateTime.utc_now() |> DateTime.to_unix(:millisecond)
end
