defmodule Exsemantica.Aggregate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "aggregates" do
    field :hidden, :boolean, default: false
    field :name, :string
    field :description, :string

    has_many :posts, Exsemantica.Post
    many_to_many :subscriptions, Exsemantica.Aggregate, join_through: "subscriptions_users"
    many_to_many :moderators, Exsemantica.User, join_through: "moderators_aggregates"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(aggregate, attrs) do
    aggregate
    |> cast(attrs, [:name, :description, :posts, :moderators])
    |> validate_required([:name, :description, :posts, :moderators])
    |> unique_constraint(:name)
  end
end
