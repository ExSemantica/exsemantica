defmodule Exsemantica.Repo.User do
  @moduledoc """
  Users can post and make comments
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:hidden, :boolean, default: false)
    field(:username, :string)
    field(:password, :string, redact: true)
    field(:biography, :string)
    field(:email, :string)

    has_many(:posts, Exsemantica.Repo.Post, foreign_key: :user_id)
    has_many(:comments, Exsemantica.Repo.Comment, foreign_key: :user_id)

    has_many(:comment_votes, Exsemantica.Repo.Vote.Comment, foreign_key: :user_id)
    has_many(:post_votes, Exsemantica.Repo.Vote.Post, foreign_key: :user_id)

    many_to_many(:subscriptions, Exsemantica.Repo.Aggregate, join_through: "subscriptions_users")
    many_to_many(:aggregates, Exsemantica.Repo.Aggregate, join_through: "moderators_aggregates")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :hidden,
      :username,
      :biography,
      :email,
      :password,
      :subscriptions,
      :aggregates
    ])
    |> validate_required([
      :hidden,
      :username,
      :biography,
      :email,
      :password,
      :subscriptions,
      :aggregates
    ])
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end
end
