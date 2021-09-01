defmodule ExsemanticaPhx.Repo.Migrations.CreateSiteUsers do
  use Ecto.Migration

  def change do
    create table(:site_users) do
      add :node_corresponding, :integer
      add :username, :text
      add :biography, :text
      add :email, :text
      add :password, :binary
      add :contract, :binary

      timestamps()
    end

    create unique_index(:site_users, [:node_corresponding])
    create unique_index(:site_users, [:username])
    create unique_index(:site_users, [:email])
    create unique_index(:site_users, [:contract])
  end
end
