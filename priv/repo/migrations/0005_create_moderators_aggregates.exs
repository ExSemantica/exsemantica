defmodule Exsemantica.Repo.Migrations.CreateModeratorsAggregates do
  use Ecto.Migration

  def change do
    create table(:moderators_aggregates, primary_key: false) do
      add(:aggregate_id, references(:aggregates, on_delete: :delete_all), primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all), primary_key: true)
    end

    create(index(:moderators_aggregates, [:aggregate_id]))
    create(index(:moderators_aggregates, [:user_id]))
  end
end
