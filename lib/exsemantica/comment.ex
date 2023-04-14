defmodule Exsemantica.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :contents, :string
    field :posted_by, :id
    field :parent_id, :id
    field :post_id, :id
    belongs_to :parent, Exsemantica.Comment, foreign_key: :parent_id, references: :id, define_field: false
    has_many :children, Exsemantica.Comment, foreign_key: :parent_id, references: :id

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:contents])
    |> validate_required([:contents])
  end
end
