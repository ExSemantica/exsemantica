defmodule ExsemanticaPhxWeb.Components.PageMainSearcher do
  use ExsemanticaPhxWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
    <h1 class="text-xl"><b>Search interests and users</b></h1>
    <br>
    <%= f = form_for @search_query, "#", [phx_change: :suggest, phx_submit: :search] %>
    <%= search_input f, :search_input, [class: "rounded-full shadow-lg p-2 bg-blue-200 w-full"] %>
    </form>
    <br>
    <%= @search_results %>
    <br>
    <br>
    <div class="grid grid-cols-1 gap-8 m-0">
      <%= @search_pagey %>
    </div>
    """
  end
end
