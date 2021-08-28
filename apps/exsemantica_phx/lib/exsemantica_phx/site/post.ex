defmodule ExsemanticaPhx.Site.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "site_posts" do
    field :content, :string
    field :is_interest, :boolean, default: false
    field :node_corresponding, :integer
    field :poster, :integer
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:node_corresponding, :title, :content, :is_interest, :poster])
    |> validate_required([:node_corresponding, :title, :content, :is_interest, :poster])
    |> unique_constraint(:node_corresponding)
  end
end
