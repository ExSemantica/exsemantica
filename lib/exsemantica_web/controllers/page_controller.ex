defmodule ExsemanticaWeb.PageController do
  use ExsemanticaWeb, :controller

  def index(conn, args) do
    render(conn, "index.html", args)
  end
end
