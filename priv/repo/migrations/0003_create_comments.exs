defmodule Exsemantica.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :hidden, :boolean, default: false, null: false
      add :contents, :text
      add :user_id, :id
      add :parent_id, :id
      add :replies, {:array, :id}
      add :votes, {:array, :id}

      timestamps(type: :utc_datetime)
    end
  end
end
