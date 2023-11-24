defmodule Exsemantica.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :hidden, :boolean, default: false, null: false
      add :type, :string
      add :title, :string
      add :contents, :text
      add :user_id, :id
      add :aggregate_id, :id
      add :votes, {:array, :id}

      timestamps(type: :utc_datetime)
    end
  end
end
