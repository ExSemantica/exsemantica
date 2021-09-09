defmodule ExsemanticaPhxWeb.Components.PageDialog do
  use ExsemanticaPhxWeb, :live_component

  @impl true
  def render(assigns) do 
    ~L"""
    <%= if @show do %>
      <div phx-click="go_away" class="absolute top-0 left-0 w-screen h-screen bg-gray-100 opacity-75"></div>
        <div class="absolute top-0 left-0 flex align-center justify-center w-screen h-screen pointer-events-none">
          <div class="bg-purple-400 w-1/2 h-auto m-auto p-4 rounded-xl shadow-xl pointer-events-auto">
          <%= @login_response %>
          <%= f = form_for @login_form, "#", [phx_submit: :do_login] %>
          <%= label f, :username, "Username", class: "m-2" %><br>
          <%= text_input f, :username, class: "w-full rounded-full shadow-lg p-2 bg-blue-100" %><br><br>
          <%= submit "Log in", class: "w-full rounded-full shadow-lg p-4 bg-indigo-400 hover:bg-indigo-500" %>
          </form>
        </div>
      </div>
    <% end %>
    """
  end
end
