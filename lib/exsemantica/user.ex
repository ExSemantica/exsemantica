defmodule Exsemantica.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :hidden, :boolean, default: false
    field :username, :string
    field :password, :string, redact: true
    field :biography, :string
    field :email, :string

    has_many :posts, Exsemantica.Post, foreign_key: :user_id
    has_many :comments, Exsemantica.Comment, foreign_key: :user_id

    many_to_many :subscriptions, Exsemantica.Aggregate, join_through: "subscriptions_users"
    many_to_many :aggregates, Exsemantica.Aggregate, join_through: "moderators_aggregates"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :biography, :email, :password])
    |> validate_required([:username, :biography, :email, :password])
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end
end
