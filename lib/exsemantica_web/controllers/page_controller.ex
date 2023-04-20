defmodule ExsemanticaWeb.PageController do
  use ExsemanticaWeb, :controller

  import Ecto.Query
  import ExsemanticaWeb.Gettext

  def home(conn, _params) do
    conn |> redirect(to: ~p"/s/all")
  end

  def aggregate(conn, %{"aggregate" => "all"} = params) do
    conn
    |> assign(:page_title, "/s/all")
    |> render(:aggregate, layout: false, community: nil, page: Access.get(params, "page", 0))
  end

  def aggregate(conn, %{"aggregate" => aggregate} = params) do
    query = from a in Exsemantica.Aggregate, where: ilike(a.name, ^aggregate), preload: [:posts, :moderators]

    case Exsemantica.Repo.one(query) do
      nil ->
        conn |> put_flash(:error, gettext("That community does not exist.")) |> redirect(to: ~p"/s/all")

      community ->
        conn
        |> assign(:page_title, "/s/" <> community.name)
        |> assign(:community, community)
        |> render(:aggregate, layout: false, page: Access.get(params, "page", 0))
    end
  end

  def user(conn, %{"username" => user} = params) do
    query = from u in Exsemantica.User, where: ilike(u.handle, ^user), preload: [:aggregates]

    case Exsemantica.Repo.one(query) do
      nil ->
        conn |> put_flash(:error, gettext("That user does not exist.")) |> redirect(to: ~p"/s/all")

      user ->
        conn
        |> assign(:page_title, "/u/" <> user.handle)
        |> assign(:user, user)
        |> render(:user, layout: false, page: Access.get(params, "page", 0))
    end
  end
end
