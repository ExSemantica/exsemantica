defmodule ExsemanticaPhxWeb.PageLive do
  use ExsemanticaPhxWeb, :live_view

  import Ecto.Query
  require ExTimeAgo

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, %{search_query: :search, search_results: "", search_pagey: "", user_advertisement: ~E"""
      <img class="p-4 rounded-md bg-indigo-300 shadow-lg max-w-full" src="images/bannerpls.png">
      """, page_title: "Home"})}
  end

  @impl true
  def handle_event("suggest", %{"search" => query}, socket) do
    case query do
      %{"search_input" => ""} -> {:noreply, assign(socket, %{search_results: ""})}

      %{"search_input" => nonblank} -> case String.first(nonblank) do
        "#" -> {:noreply, assign(socket, %{search_results: ~E"""
            <i>Query for interests containing <b>"<%= nonblank |> String.replace_prefix("#", "") %>"</b> returned <b><%= "%" <> String.replace_prefix(nonblank, "#", "") <> "%" |> ExsemanticaPhx.Search.interests([], :count) %></b> hits.<br>Press Enter/Return to show the results.</i>
            """})}
 
        "@" -> {:noreply, assign(socket, %{search_results: ~E"""
            <i>Query for usernames containing <b>"<%= nonblank |> String.replace_prefix("@", "") %>"</b> returned <b><%= "%" <> String.replace_prefix(nonblank, "@", "") <> "%" |> ExsemanticaPhx.Search.users([], :count) %></b> hits.<br>Press Enter/Return to show the results.</i>
            """})}

        _other -> {:noreply, assign(socket, %{search_results: ~E"""
            <i>Try using <b>@</b> or <b>#</b> before your query.</i>
            """})}
      end
    end
  end

  @impl true
  def handle_event("search", %{"search" => query}, socket) do
    case query do
      %{"search_input" => ""} -> {:noreply, assign(socket, %{search_results: ""})}

      %{"search_input" => nonblank} -> case String.first(nonblank) do
        "#" -> 
          prequery = "%" <> String.replace_prefix(nonblank, "#", "") <> "%"
          {:noreply, assign(socket, %{search_results: ~E"""
            <i>Query for interests containing <b>"<%= nonblank |> String.replace_prefix("#", "") %>"</b> returned <b><%= prequery |> ExsemanticaPhx.Search.interests([], :count) %></b> hits.<br>Results from <b><%= DateTime.utc_now |> DateTime.truncate(:second) %></b> shown.</i>
            """,
            search_pagey: prequery |> ExsemanticaPhx.Search.interests([], :query) |> Enum.take(15) |> handle_interest, page_title: "Interest Query: '#{nonblank}'"})}
             
        "@" ->
          prequery = "%" <> String.replace_prefix(nonblank, "@", "") <> "%"
          {:noreply, assign(socket, %{search_results: ~E"""
            <i>Query for usernames containing <b>"<%= nonblank |> String.replace_prefix("@", "") %>"</b> returned <b><%= prequery |> ExsemanticaPhx.Search.users([], :count) %></b> hits.<br>Results from <b><%= DateTime.utc_now |> DateTime.truncate(:second) %></b>.</i>
            """,
            search_pagey: prequery |> ExsemanticaPhx.Search.users([], :query) |> Enum.take(15) |> handle_user, page_title: "User Query: '#{nonblank}'"})}
        _other -> {:noreply, assign(socket, %{search_results: ~E"""
            <i>Try using <b>@</b> or <b>#</b> before your query.</i>
            """})}
      end
    end
  end

 # Interests
  defp handle_interest(pagey), do: handle_interest(pagey, "")

  defp handle_interest([pagey_head | pagey_tail], html) do
    [utitle, ucontent, dc, dm, poster] = pagey_head

    d1 = ExTimeAgo.now
    d0c = %{dt: {{dc.year, dc.month, dc.day}, {dc.hour, dc.minute, dc.second}}, ms: d1.ms}
    dspanc = ExTimeAgo.span!(d1, d0c) |> ExTimeAgo.string!()
    
    d0m = %{dt: {{dm.year, dm.month, dm.day}, {dm.hour, dm.minute, dm.second}}, ms: d1.ms}
    dspanm = ExTimeAgo.span!(d1, d0m) |> ExTimeAgo.string!()

    iuser = ExsemanticaPhx.Repo.one(from user in "site_users", where: user.node_corresponding == ^poster, select: user.username)

    ~E"""
    <div class="rounded-lg bg-green-300 hover:bg-green-400 shadow-lg w-full h-full p-4">
    <h1 class="text-sm"><b>#<%= utitle %></b></h1>
    <p class="text-xs"><%= ucontent %></p><br><br>
    <i><p class="text-xs">Last modified <%= dspanm %> ago</p></i>
    <i><p class="text-xs">Created <%= dspanc %> ago by @<%= iuser %></p></i>
    </div>
    <%= handle_interest(pagey_tail, html) %>
    """
  end

  defp handle_interest([], html), do: html

  # Usernames
  defp handle_user(pagey), do: handle_user(pagey, "")

  defp handle_user([], html), do: html
  
  
  defp handle_user([pagey_head | pagey_tail], html) do
    [uname, ubio, d] = pagey_head

    d1 = ExTimeAgo.now
    d0 = %{dt: {{d.year, d.month, d.day}, {d.hour, d.minute, d.second}}, ms: d1.ms}

    dspan = ExTimeAgo.span!(d1, d0) |> ExTimeAgo.string!()

    ~E"""
    <div class="rounded-lg bg-yellow-300 hover:bg-yellow-400 shadow-lg w-full h-full p-4">
    <h1 class="text-sm"><b>@<%= uname %></b></h1>
    <p class="text-xs"><%= ubio %></p><br><br>
    <i><p class="text-xs">Registered <%= dspan %> ago</p></i>
    </div>
    <%= handle_user(pagey_tail, html) %>
    """
  end


end
