defmodule Exsemantica.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :handle, :string
      add :email, :string
      add :description, :text
      add :password, :binary
      add :status, :binary

      timestamps()
    end

    create unique_index(:users, [:handle, :email])
  end
end
