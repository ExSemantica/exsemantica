defmodule Exsemantica.Repo.Migrations.CreateSubscriptionsUsers do
  use Ecto.Migration

  def change do
    create table(:subscriptions_users, primary_key: false) do
      add(:subscription_id, references(:aggregates, on_delete: :delete_all), primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all), primary_key: true)

      timestamps(type: :utc_datetime)
    end

    create(index(:subscriptions_users, [:subscription_id]))
    create(index(:subscriptions_users, [:user_id]))
  end
end
