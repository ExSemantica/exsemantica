defmodule ExsemanticaPhxWeb.Components.PageMainSearcher do
  use ExsemanticaPhxWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <section class="col-start-1 col-span-2 mt-0" role="search">
    <h1 class="text-xl"><b>Search interests and users</b></h1>
    <br>
    <.form let={f} for={@search_query} method="get" phx-change="suggest" phx-submit="search">
      <%= search_input f, :search_input, [class: "rounded-full shadow-lg p-2 bg-blue-200 w-full"] %>
    </.form>
    <br>
    <%= @search_results %>
    <br>
    <br>
    <div class="grid grid-cols-1 gap-8 m-0">
      <%= @search_pagey %>
    </div>
    </section>
    """
  end
end
