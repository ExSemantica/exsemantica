defmodule ExsemanticaWeb.PageController do
  use ExsemanticaWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
