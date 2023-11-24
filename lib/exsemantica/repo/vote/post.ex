defmodule Exsemantica.Repo.Vote.Post do
  @moduledoc """
  Up/downvotes for `Exsemantica.Repo.Post`s
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "post_votes" do
    field :is_downvote, :boolean, default: false

    belongs_to :post, Exsemantica.Repo.Post, foreign_key: :post_id
    belongs_to :user, Exsemantica.Repo.User, foreign_key: :user_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:user, :post, :is_downvote])
    |> validate_required([:user, :post, :is_downvote])
    |> unique_constraint(:user_id)
  end
end
