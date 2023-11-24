defmodule Exsemantica.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :contents, :text
      add :hidden, :boolean, default: false, null: false
      add :author, references(:users, on_delete: :nothing)
      add :parent_id, :integer
      add :replies, {:array, :integer}

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:author])
  end
end
