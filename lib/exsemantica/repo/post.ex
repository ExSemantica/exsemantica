defmodule Exsemantica.Repo.Post do
  @moduledoc """
  Represents either a self or a link posted in an `Exsemantica.Repo.Aggregate`
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field(:hidden, :boolean, default: false)
    field(:type, Ecto.Enum, values: [:self, :link])
    field(:title, :string)
    field(:contents, :string)
    field(:tags, {:array, :string})

    belongs_to(:user, Exsemantica.Repo.User)
    belongs_to(:aggregate, Exsemantica.Repo.Aggregate)

    has_many(:votes, Exsemantica.Repo.Vote.Post, foreign_key: :post_id)
    has_many(:comments, Exsemantica.Repo.Comment, foreign_key: :post_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:hidden, :type, :title, :contents, :user, :aggregate, :votes, :comments])
    |> validate_required([:hidden, :type, :title, :contents, :user, :aggregate, :votes, :comments])
  end
end
