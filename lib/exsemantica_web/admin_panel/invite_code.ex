defmodule ExsemanticaWeb.AdminPanel.InviteCode do
  @moduledoc false
  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_, _) do
    {:ok, "ExSemantica Invite Code"}
  end

  @impl true
  def render_page(_assigns) do
    card(title: "Current Invite Code", value: "UNIMPLEMENTED")
  end
end
