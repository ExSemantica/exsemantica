defmodule Exsemantica.Repo.Migrations.CreateAggregates do
  use Ecto.Migration

  def change do
    create table(:aggregates) do
      add :hidden, :boolean, default: false, null: false
      add :name, :string
      add :description, :text
      add :posts, {:array, :id}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:aggregates, [:name])
  end
end
