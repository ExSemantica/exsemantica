defmodule ExsemanticaPhx.Site.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "site_users" do
    field :biography, :string
    field :node_corresponding, :integer
    field :password, :binary
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:node_corresponding, :username, :password, :biography])
    |> validate_required([:node_corresponding, :username, :password, :biography])
    |> unique_constraint(:node_corresponding)
  end
end
