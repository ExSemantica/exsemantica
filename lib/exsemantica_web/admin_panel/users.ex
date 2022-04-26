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
        %{field: :id, sortable: :desc},
        %{field: :timestamp},
        %{field: :handle},
        %{field: :privmask}
      ],
      row_fetcher: &fetch_rows/2
    )
  end

  defp fetch_rows(params, _node) do
    {:atomic, [reply]} =
      [%{operation: :dump, table: :users}]
      |> Exsemnesia.Database.transaction("DUMPING all users in admin panel")

    %{operation: :dump, response: entries, table: :users} = reply

    unsorted =
      for {:users, idx, timestamp, handle, privmask} <- entries do
        <<idx_formatted::128>> = idx

        %{
          id: idx_formatted,
          timestamp: timestamp,
          handle: handle,
          privmask: Base.encode16(privmask)
        }
      end

    if params.sort_dir == :asc do
      {unsorted
       |> Enum.sort(fn a, b ->
         a.id < b.id
       end), length(entries)}
    else
      {unsorted
       |> Enum.sort(fn a, b ->
         a.id > b.id
       end), length(entries)}
    end
  end
end
