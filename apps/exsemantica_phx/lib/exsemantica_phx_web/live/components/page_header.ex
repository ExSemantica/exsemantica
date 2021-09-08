defmodule ExsemanticaPhxWeb.Components.PageHeader do
  use ExsemanticaPhxWeb, :live_component

  @impl true
  def render(assigns) do 
    ~L"""
    <%= if @users_mutable do %>
      <button class="float-right text-center m-2 p-3 w-1/6 bg-indigo-100 rounded-full">Log in</button>
    <%= end %>
    """
  end
end
