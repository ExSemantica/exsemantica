defmodule ExsemanticaWeb.AdminPage do
  @moduledoc false
  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_, _) do
    {:ok, "ExSemantica Admin"}
  end

  @impl true
  def render_page(_assigns) do
    card(title: "Invite code", value: :persistent_term.get(:exsemantica_invite))
  end
end
