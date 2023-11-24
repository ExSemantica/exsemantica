defmodule Exsemantica.Repo.Migrations.CreateCommentVotes do
  use Ecto.Migration

  def change do
    create table(:comment_votes) do
      add :is_downvote, :boolean, default: false, null: false
      add :comment_id, :id
      add :user_id, :id

      timestamps(type: :utc_datetime)
    end
    create unique_index(:comment_votes, [:user_id])
  end
end
