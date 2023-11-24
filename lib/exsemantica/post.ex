defmodule Exsemantica.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :type, Ecto.Enum, values: [:self, :link]
    field :contents, :string
    field :author, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:type, :contents])
    |> validate_required([:type, :contents])
  end
end
