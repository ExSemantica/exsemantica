defmodule ExsemanticaWeb.PageHTML do
  import Ecto.Query
  use ExsemanticaWeb, :html

  embed_templates "page_html/*"

  @fetch_limit 10
  # ===========================================================================
  # POST SUBRENDERING
  # ===========================================================================
  def agg_post(assigns) do
    assigns = assigns |> assign(:poster, Exsemantica.Repo.get(Exsemantica.User, assigns.result.id))
    case assigns.result.type do
      :self ->
        ~H"""
        <div class="bg-gray-100 m-4 p-4 shadow-xl">
          <span title="self post"><.icon name="hero-document" class="float-left m-2 p-3" /></span>
          <h2 class="text-xl m-1"><%= @result.title %></h2>
          <br>
          <p class="text-xs italic">self posted <%= @result.inserted_at %> by <.link class="text-blue-800" href={~p"/u/#{@poster.handle}"}>/u/<%= @poster.handle %></.link></p>
        </div>
        """
      :link ->
        ~H"""
        <div class="bg-gray-100 m-4 p-4 shadow-xl">
          <span title="link post"><.icon name="hero-link" class="float-left m-2 p-3" /></span>
          <h2 class="text-xl m-1"><%= @result.title %></h2>
          <br>
          <p class="text-xs italic">link posted <%= @result.inserted_at %> by <.link class="text-blue-800" href={~p"/u/#{@poster.handle}"}>/u/<%= @poster.handle %></.link></p>
        </div>
        """
    end
  end
  # ===========================================================================
  # MAIN ELEMENT
  # ===========================================================================
  @doc """
  Home page or /s/all main element
  """
  def all_main(assigns) do
    # count posts
    all_count = Exsemantica.Repo.aggregate(Exsemantica.Post, :count)
    # convert page number to ID offset
    multi_id = all_count - assigns.page * @fetch_limit
    # query
    results = Exsemantica.Repo.all(from p in Exsemantica.Post, order_by: [desc: p.id], where: p.id <= ^multi_id, limit: @fetch_limit)
    # assign our results
    assigns = assigns |> assign(:results, results)
    ~H"""
    <%= for result <- @results do %>
      <.agg_post result={result} />
    <% end %>
    """
  end

  @doc """
  Aggregate page (not /s/all) main element
  """
  def community_main(assigns) do
    ~H"""
    <div class="bg-gray-100 m-4 p-4 shadow-xl">
      <h2 class="text-xl font-medium">Placeholder</h2>
      <p>Community Main</p>
      <br>
      <p class="text-xs italic">Foot</p>
    </div>
    """
  end

  @doc """
  User page main element
  """
  def user_main(assigns) do
    ~H"""
    <div class="bg-gray-100 m-4 p-4 shadow-xl">
      <h2 class="text-xl font-medium">Placeholder</h2>
      <p>User Main</p>
      <br>
      <p class="text-xs italic">Foot</p>
    </div>
    """
  end
  # ===========================================================================
  # ASIDE ELEMENT
  # ===========================================================================
  @doc """
  Home page or /s/all aside element
  """
  def all_side(assigns) do
    ~H"""
    <h1 class="text-2xl p-4">Information</h1>
    <h2 class="text-xl pl-4">Trending</h2>
    <p class="bg-slate-100 m-4 p-4 shadow-xl">placeholder aside 1</p>
    <p class="bg-slate-100 m-4 p-4 shadow-xl">placeholder aside 2</p>
    """
  end

  @doc """
  Aggregate page (not /s/all) aside element
  """
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
    <p class="bg-slate-100 m-4 p-4 shadow-xl"><span :for={moderator <- @moderators}><.link class="text-blue-800" href={~p"/u/#{moderator.handle}"}>/u/<%= moderator.handle %></.link><br></span></p>
    """
  end

  @doc """
  User page aside element
  """
  def user_side(assigns) when is_nil(assigns.user.description) do
    ~H"""
    <h1 class="text-2xl p-4">Information</h1>
    <h2 class="text-xl pl-4">Moderates</h2>
    <p class="bg-slate-100 m-4 p-4 shadow-xl"><span :for={aggregate <- @user.aggregates}><.link class="text-blue-800" href={~p"/s/#{aggregate.name}"}>/s/<%= aggregate.name %></.link><br></span></p>
    """
  end

  def user_side(assigns) do
    ~H"""
    <h1 class="text-2xl p-4">Information</h1>
    <h2 class="text-xl pl-4">Description</h2>
    <p class="bg-slate-100 m-4 p-4 shadow-xl"><%= @user.description %></p>
    <h2 class="text-xl pl-4">Moderates</h2>
    <p class="bg-slate-100 m-4 p-4 shadow-xl"><span :for={aggregate <- @user.aggregates}><.link class="text-blue-800" href={~p"/s/#{aggregate.name}"}>/s/<%= aggregate.name %></.link><br></span></p>
    """
  end
end
