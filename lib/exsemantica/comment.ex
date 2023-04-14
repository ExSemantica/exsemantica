defmodule Exsemantica.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :contents, :string
    field :parent_id, :id

    belongs_to :post, Exsemantica.Post
    belongs_to :user, Exsemantica.User

    belongs_to :parent, Exsemantica.Comment,
      foreign_key: :parent_id,
      references: :id,
      define_field: false

    has_many :children, Exsemantica.Comment, foreign_key: :parent_id, references: :id

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:contents, :user_id, :post_id])
    |> validate_required([:contents, :user_id, :post_id])
  end
end
