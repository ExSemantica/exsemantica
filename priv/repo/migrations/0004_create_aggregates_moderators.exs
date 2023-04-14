defmodule Exsemantica.Repo.Migrations.CreateAggregatesModerators do
  use Ecto.Migration

  def change do
    create table(:aggregates_moderators) do
      add :aggregate_id, references(:aggregates)
      add :user_id, references(:users)
    end

    create unique_index(:aggregates_moderators, [:aggregate_id, :user_id])
  end
end
