defmodule ExsemanticaWeb.AdminPanel.Users do
  @moduledoc false
  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_, _) do
    {:ok, "ExSemantica Users"}
  end

  @impl true
  def render_page(_assigns) do
    table(
      id: :users,
      title: "Users",
      columns: [
        %{field: :id, sortable: :asc},
        %{field: :timestamp},
        %{field: :handle},
        %{field: :privmask},
        %{field: :paseto}
      ],
      row_fetcher: &fetch_rows/2
    )
  end
  # card(title: "Invite code", value: :persistent_term.get(:exsemantica_invite)),
  defp fetch_rows(_params, _node) do
    {:atomic, [reply]} = [%{operation: :dump, table: :users}] |> Exsemnesia.Database.transaction()
    %{operation: :dump, response: entries, table: :users} = reply

    {for {:users, idx, timestamp, handle, privmask} <- entries do
      <<idx_formatted::128>> = idx
       %{id: idx_formatted, timestamp: timestamp, handle: handle, privmask: Base.encode16(privmask)}
     end, length(entries)}
  end
end
