defmodule ExsemanticaWeb.TrendController do
  use ExsemanticaWeb, :controller
  use Absinthe.Phoenix.Controller, schema: Exsemantica.Schema, action: [mode: :internal]

  @graphql """
  trending(count: 15) {
    type, name
  }
  """
  def show(conn, %{data: data}) do
    IO.inspect data
    live_render(c)
  end
end
