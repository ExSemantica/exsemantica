defmodule Exsemantica.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :hidden, :boolean, default: false
    field :contents, :string

    belongs_to :user, Exsemantica.User, foreign_key: :user_id
    belongs_to :parent, Exsemantica.Comment, foreign_key: :parent_id
    has_many :replies, Exsemantica.Comment, foreign_key: :parent_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:contents, :hidden])
    |> validate_required([:contents, :hidden])
  end
end
