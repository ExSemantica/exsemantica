defmodule ExsemanticaPhxWeb.Components.PageMain do
  use ExsemanticaPhxWeb, :live_component

  @impl true
  def render(assigns) do 
    case assigns.banner do
      nil -> ~L"""
        <%= render_mainpage(assigns) %>
        """
      banner -> ~L"""
        <span class="col-start-1 col-span-3 text-center rounded-md shadow-lg bg-red-400 p-4"><%= banner %></span>
        <%= render_mainpage(assigns) %>   
        """
    end
  end

  def render_mainpage(assigns) when assigns.advertise do
    ~L"""
    <section class="col-start-1 col-span-2 mt-0 p-4 rounded-md bg-indigo-300 shadow-lg" role="search">
      <%= live_component ExsemanticaPhxWeb.Components.PageMainSearcher, id: :search, search_pagey: @search_pagey, search_results: @search_results, search_query: @search_query %>
    </section>
    <div class="col-start-3">
      <div class="p-4 rounded-md bg-indigo-300 shadow-lg">
        <b>Popular interests:</b><br>
          Nothing here yet...
      </div>
      <div class="text-center p-4" role="AD-banner-side">
        <img class="p-4 rounded-md bg-indigo-300 shadow-lg m-auto" src="images/bannerpls.png">
        Advertisement
      </div>
    </div>
    """
  end

  def render_mainpage(assigns) do
    ~L"""
    <section class="col-start-1 col-span-2 mt-0 p-4 rounded-md bg-indigo-300 shadow-lg" role="search">
      <%= live_component ExsemanticaPhxWeb.Components.PageMainSearcher, id: :search, search_pagey: @search_pagey, search_results: @search_results, search_query: @search_query %>
    </section>
    <div class="col-start-3">
      <div class="p-4 rounded-md bg-indigo-300 shadow-lg">
        <b>Popular interests:</b><br>
          Nothing here yet...
      </div>
    </div>
    """
  end
end
