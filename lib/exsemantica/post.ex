defmodule Exsemantica.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :contents, :string
    field :title, :string
    field :type, Ecto.Enum, values: [:self, :link]

    belongs_to :user, Exsemantica.User
    belongs_to :aggregate, Exsemantica.Aggregate
    has_many :comments, Exsemantica.Comment

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :contents, :type, :user_id, :aggregate_id])
    |> validate_required([:title, :contents, :type, :user_id, :aggregate_id])
  end
end
