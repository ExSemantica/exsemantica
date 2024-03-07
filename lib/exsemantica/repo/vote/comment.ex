defmodule Exsemantica.Repo.Vote.Comment do
  @moduledoc """
  Up/downvotes for `Exsemantica.Repo.Comment`s
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "comment_votes" do
    field :is_downvote, :boolean, default: false

    belongs_to :comment, Exsemantica.Repo.Comment, foreign_key: :comment_id
    belongs_to :user, Exsemantica.Repo.User, foreign_key: :user_id
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:user, :comment, :is_downvote])
    |> validate_required([:user, :comment, :is_downvote])
    |> unique_constraint(:user_id)
  end
end
