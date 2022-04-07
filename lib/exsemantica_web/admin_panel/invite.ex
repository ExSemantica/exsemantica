defmodule ExsemanticaWeb.AdminPanel.InviteCode do
  @moduledoc false
  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_, _) do
    {:ok, "Current ExSemantica Invite Code"}
  end

  @impl true
  def render_page(_assigns) do
    card(
      title: "Current Invite Code",
      value: Base.url_encode64(:persistent_term.get(:exseminvite))
    )
  end
end
