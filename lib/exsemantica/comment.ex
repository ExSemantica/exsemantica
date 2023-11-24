defmodule Exsemantica.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :hidden, :boolean, default: false
    field :contents, :string
    field :author, :id
    field :parent, :id

    belongs_to :parent, Exsemantica.Comment, foreign_key: :parent_id, references: :id, define_field: false
    has_many :replies, Exsemantica.Comment, foreign_key: :parent_id, references: :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:contents, :hidden])
    |> validate_required([:contents, :hidden])
  end
end
