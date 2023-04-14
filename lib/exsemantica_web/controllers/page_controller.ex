defmodule ExsemanticaWeb.PageController do
  use ExsemanticaWeb, :controller

  import Ecto.Query
  import ExsemanticaWeb.Gettext

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    conn
    |> assign(:page_title, "Home")
    |> render(:aggregate, layout: false, community: nil)
  end

  def aggregate(conn, %{"aggregate" => aggregate}) do
    query = from a in Exsemantica.Aggregate, where: ilike(a.name, ^aggregate), preload: [:posts, :moderators]

    case Exsemantica.Repo.one(query) do
      nil ->
        conn |> put_flash(:error, gettext("That community does not exist.")) |> redirect(to: ~p"/")

      community ->
        conn
        |> assign(:page_title, "/s/" <> community.name)
        |> assign(:community, community)
        |> render(:aggregate, layout: false)
    end
  end
end
