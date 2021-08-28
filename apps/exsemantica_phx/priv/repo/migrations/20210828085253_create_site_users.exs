defmodule ExsemanticaPhx.Repo.Migrations.CreateSiteUsers do
  use Ecto.Migration

  def change do
    create table(:site_users) do
      add :node_corresponding, :integer
      add :username, :text
      add :password, :binary
      add :biography, :text

      timestamps()
    end

    create unique_index(:site_users, [:node_corresponding])
  end
end
