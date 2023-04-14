defmodule Exsemantica.Aggregate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "aggregates" do
    field :description, :string
    field :name, :string
    has_many :posts, Exsemantica.Post
    many_to_many :moderators, Exsemantica.User, join_through: "aggregates_moderators"

    timestamps()
  end

  @doc false
  def changeset(aggregate, attrs) do
    aggregate
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
  end
end
