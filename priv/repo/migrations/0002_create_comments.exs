defmodule Exsemantica.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :contents, :text
      add :posted_by, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:comments, [:posted_by])
  end
end
