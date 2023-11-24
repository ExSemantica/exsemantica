defmodule Exsemantica.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :hidden, :boolean, default: false, null: false
      add :username, :string
      add :biography, :text
      add :email, :string
      add :password, :string
      add :posts, {:array, :id}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
  end
end
