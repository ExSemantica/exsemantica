defmodule ExsemanticaPhxWeb.Components.PageDialog do
  use ExsemanticaPhxWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @show do %>
      <div phx-click="go_away" class="fixed top-0 left-0 w-screen h-screen bg-gray-100 opacity-75"></div>
      <div class="fixed top-0 left-0 flex align-center justify-center w-screen h-screen pointer-events-none">
        <div class="bg-purple-400 w-1/2 md:w-1/3 xl:w-1/4 h-auto m-auto p-4 rounded-xl shadow-xl pointer-events-auto">
          <div id="motd" class="text-center rounded-lg m-auto p-1 mb-3 shadow-xl w-full bg-gray-500 invisible"></div>
          <.form let={f} for={@login_form} id="login" method="get">
            <%= submit f, disabled: true, class: "hidden" %>
            <%= label f, :username, "Username", class: "m-2" %><br>
            <%= text_input f, :username, id: "username", class: "w-full rounded-full shadow-lg p-2 bg-blue-100" %><br>
            <%= error_tag f, :username %><br>
            </.form>
            <%= button "Log in",
                  method: "get",
                  to: "/",
                  class: "w-full rounded-full shadow-lg p-4 bg-indigo-400 hover:bg-indigo-500",
                  "@click": "await window.clientValidateLogin($event)" %>
        </div>
      </div>
    <% end %>
    """
  end
end
