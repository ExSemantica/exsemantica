defmodule ExsemanticaPhxWeb.Components.PageHeader do
  use ExsemanticaPhxWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <button phx-click="menu" class="float-right text-center m-2 p-3 w-1/6 bg-indigo-100 rounded-full hover:bg-indigo-200">Login</button>
    """
  end
end
