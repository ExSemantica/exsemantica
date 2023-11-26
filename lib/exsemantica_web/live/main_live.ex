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
    {:ok, socket |> push_navigate(to: ~p"/s/all")}
  end

  def mount(params, session, socket) do
    {:ok,
     if socket |> connected? do
       socket =
         socket
         |> assign(loading: true, t0: DateTime.utc_now |> DateTime.to_unix(:millisecond))
         |> check_auth(session)

       socket =
         case params do
           %{"username" => username} ->
             socket
             |> assign(
               event: :check_user_name,
               task: Task.async(Exsemantica.Task.CheckUserName, :run, [%{guess: username}])
             )

           %{"aggregate" => "all"} ->
             socket
             |> assign(event: :load_all_page)

           %{"aggregate" => aggregate} ->
             socket
             |> assign(
               event: :check_aggregate_name,
               task: Task.async(Exsemantica.Task.CheckAggregateName, :run, [%{guess: aggregate}])
             )
         end

       case socket.assigns.event do
         :check_aggregate_name ->
           check_result = Task.await(socket.assigns.task)

           case check_result do
             {:ok, %{identical?: true, id: id, name: name}} ->
               socket =
                 socket
                 |> assign(
                   ident: name,
                   task:
                     Task.async(Exsemantica.Task.LoadAggregatePage, :run, [
                       %{id: id, load_by: :newest, page: 0}
                     ])
                 )

               {:ok, data} = Task.await(socket.assigns.task)

               socket
               |> assign(
                 otype: :aggregate,
                 data: data,
                 loading: false,
                 page_title: "/s/#{socket.assigns.ident}"
               )
               |> push_event("transition-loader", %{})

             {:ok, %{identical?: false, name: name}} ->
               socket |> push_navigate(to: ~p"/s/#{name}")

             {:error, :not_found} ->
               socket
               |> push_navigate(to: ~p"/s/all")
               |> put_flash(:error, gettext("That aggregate does not exist"))
           end

         :check_user_name ->
           check_result = Task.await(socket.assigns.task)

           case check_result do
             {:ok, %{identical?: true, id: id, name: name}} ->
               socket =
                 socket
                 |> assign(
                   ident: name,
                   task:
                     Task.async(Exsemantica.Task.LoadUserPage, :run, [
                       %{id: id, load_by: :newest, page: 0}
                     ])
                 )

               {:ok, data} = Task.await(socket.assigns.task)

               socket
               |> assign(
                 otype: :user,
                 data: data,
                 loading: false,
                 page_title: "/u/#{socket.assigns.ident}"
               )
               |> push_event("transition-loader", %{})

             {:ok, %{identical?: false, name: name}} ->
               socket |> push_navigate(to: ~p"/u/#{name}")

             {:error, :not_found} ->
               socket
               |> push_navigate(to: ~p"/s/all")
               |> put_flash(:error, gettext("That aggregate does not exist"))
           end

         :load_all_page ->
           socket
           |> assign(otype: :aggregate, ident: nil, loading: false, page_title: "/s/all")
           |> push_event("transition-loader", %{})
       end
     else
       socket |> assign(loading: true, page_title: "Loading")
     end}
  end

  # ===========================================================================
  # After mounting has finished
  # ===========================================================================
  # def post_mount(%{"username" => username}, _session, socket)
  #     when socket.assigns.live_action == :user do
  #   {:ok, socket |> assign(otype: :user, ident: username, page_title: "/u/" <> username)}
  # end

  # def post_mount(%{"aggregate" => "all"}, _session, socket)
  #     when socket.assigns.live_action == :aggregate do
  #   {:ok, socket |> assign(otype: :aggregate, ident: nil, page_title: "/s/all")}
  # end

  # def post_mount(%{"aggregate" => aggregate}, _session, socket)
  #     when socket.assigns.live_action == :aggregate do
  #   case result do
  #     {:error, :not_found} ->
  #       {:ok,
  #        socket
  #        |> push_navigate(to: ~p"/s/all")
  #        |> put_flash(:error, gettext("That aggregate does not exist"))}

  #     {:ok, name: name, identical?: false} ->
  #       {:ok, socket |> push_navigate(to: ~p"/s/#{name}")}

  #     {:ok, name: name, identical?: false} ->
  #       {:ok, socket |> push_navigate(to: ~p"/s/#{name}")}
  #   end
  # end

  # ===========================================================================
  # Render
  # ===========================================================================
  def render(assigns) do
    if assigns.loading do
      ~H"""
      <.live_loader />
      """
    else
      t1 = DateTime.utc_now |> DateTime.to_unix(:millisecond)
      case assigns.otype do
        :aggregate when is_nil(assigns.ident) ->
          ~H"""
          <.live_header myuser={assigns.myuser} />
          <.live_body_all />
          <.live_footer time={t1 - assigns.t0} />
          """

        :aggregate ->
          ~H"""
          <.live_header myuser={assigns.myuser} />
          <.live_body_aggregate aggregate={assigns.ident} />
          <.live_footer time={t1 - assigns.t0} />
          """

        :user ->
          ~H"""
          <.live_header myuser={assigns.myuser} />
          <.live_body_user />
          <.live_footer time={t1 - assigns.t0} />
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
