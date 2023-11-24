defmodule Exsemantica.Repo.Migrations.CreatePostVotes do
  use Ecto.Migration

  def change do
    create table(:post_votes) do
      add :is_downvote, :boolean, default: false, null: false
      add :post_id, :id
      add :user_id, :id

      timestamps(type: :utc_datetime)
    end

    create unique_index(:post_votes, [:user_id])
  end
end
