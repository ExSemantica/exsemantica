defmodule Exsemantica.Repo.Comment do
  @moduledoc """
  Represents a comment inside of a `Exsemantica.Repo.Post`
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :hidden, :boolean, default: false
    field :contents, :string

    belongs_to :user, Exsemantica.Repo.User, foreign_key: :user_id
    belongs_to :post, Exsemantica.Repo.User, foreign_key: :post_id

    belongs_to :parent, Exsemantica.Repo.Comment, foreign_key: :parent_id
    has_many :replies, Exsemantica.Repo.Comment, foreign_key: :parent_id

    has_many :votes, Exsemantica.Repo.Vote.Comment, foreign_key: :comment_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:contents, :hidden, :user, :post, :parent, :replies, :votes])
    |> validate_required([:contents, :hidden, :user, :post, :parent, :replies, :votes])
  end
end
