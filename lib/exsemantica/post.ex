defmodule Exsemantica.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :hidden, :boolean, default: false
    field :type, Ecto.Enum, values: [:self, :link]
    field :title, :string
    field :contents, :string

    belongs_to :user, Exsemantica.User
    belongs_to :aggregate, Exsemantica.Aggregate

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:type, :contents])
    |> validate_required([:type, :contents])
  end
end
