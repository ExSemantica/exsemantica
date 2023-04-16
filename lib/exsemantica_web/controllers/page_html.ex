defmodule ExsemanticaWeb.PageHTML do
  use ExsemanticaWeb, :html

  embed_templates "page_html/*"

  attr :moderators, :list

  def all_side(assigns) do
    ~H"""
    <h1 class="text-2xl p-4">Information</h1>
    <h2 class="text-xl pl-4">Trending</h2>
    <p class="bg-slate-100 m-4 p-4 shadow-xl">placeholder aside 1</p>
    <p class="bg-slate-100 m-4 p-4 shadow-xl">placeholder aside 2</p>
    """
  end

  def community_side(assigns) when assigns.moderators == [] do
    ~H"""
    <h1 class="text-2xl p-4">Information</h1>
    <h2 class="text-xl pl-4">Description</h2>
    <p class="bg-slate-100 m-4 p-4 shadow-xl"><%= @description %></p>
    <h2 class="text-xl pl-4">Moderators</h2>
    <p class="bg-slate-100 m-4 p-4 shadow-xl">None</p>
    """
  end

  def community_side(assigns) do
    ~H"""
    <h1 class="text-2xl p-4">Information</h1>
    <h2 class="text-xl pl-4">Description</h2>
    <p class="bg-slate-100 m-4 p-4 shadow-xl"><%= @description %></p>
    <h2 class="text-xl pl-4">Moderators</h2>
    <p class="bg-slate-100 m-4 p-4 shadow-xl"><%= @moderators |> Enum.map(&("/u/" <> &1.handle)) |> Enum.join(", ") %></p>
    """
  end
end
