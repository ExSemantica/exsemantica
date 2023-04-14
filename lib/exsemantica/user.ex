defmodule Exsemantica.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :description, :string
    field :email, :string
    field :handle, :string
    field :password, :binary, redact: true
    field :status, :binary

    has_many :posts, Exsemantica.Post
    has_many :comments, Exsemantica.Comment
    many_to_many :aggregates, Exsemantica.Aggregate, join_through: "aggregates_moderators"

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:handle, :email, :description, :password, :status])
    |> validate_required([:handle, :email, :description, :password, :status])
    |> unique_constraint([:handle, :email])
  end
end
