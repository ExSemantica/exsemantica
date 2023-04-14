defmodule ExsemanticaWeb.Layouts do
  use ExsemanticaWeb, :html

  embed_templates "layouts/*"

  def dropdown_menu(assigns) do
    ~H"""
    placeholder menu
    """
  end
end
