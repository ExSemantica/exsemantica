defmodule Exsemantica.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :contents, :text
      add :type, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :aggregate_id, references(:aggregates, on_delete: :nothing)

      timestamps()
    end

    create index(:posts, [:user_id, :aggregate_id])
  end
end
