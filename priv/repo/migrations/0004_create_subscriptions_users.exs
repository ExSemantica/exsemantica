defmodule Exsemantica.Repo.Migrations.CreateSubscriptionsUsers do
  use Ecto.Migration

  def change do
    create table(:subscriptions_users, primary_key: false) do
      add(:aggregate_id, references(:aggregates, on_delete: :delete_all), primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all), primary_key: true)
    end

    create(index(:subscriptions_users, [:aggregate_id]))
    create(index(:subscriptions_users, [:user_id]))
  end
end
