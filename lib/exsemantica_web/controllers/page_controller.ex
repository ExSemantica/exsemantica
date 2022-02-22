defmodule ExsemanticaWeb.PageController do
  use ExsemanticaWeb, :controller
  import Phoenix.LiveView.Controller

  def index(conn, session) do
    live_render(conn, ExsemanticaWeb.LayoutLive, session: session)
  end
end
