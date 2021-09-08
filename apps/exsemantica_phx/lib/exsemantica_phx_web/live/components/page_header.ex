defmodule ExsemanticaPhxWeb.Components.PageHeader do
  use ExsemanticaPhxWeb, :live_component

  @impl true
  def render(assigns) do 
    case assigns.user_mutability do
      # TODO: Logins, contracts, yada.
      :login_open -> ~L"""
        <button class="float-right text-center m-2 p-3 w-1/6 bg-indigo-100 rounded-full">Log in</button>
        """

      # TODO: Registration too
      :registration_open -> ~L"""
        <button class="float-right text-center m-2 p-3 w-1/6 bg-indigo-100 rounded-full">Log in/Register</button>
        """

      # Nobody can login or register on this instance. Nothing.
      _ -> ~L""
    end
  end
end
