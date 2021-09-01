defmodule ExsemanticaPhx.Site.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "site_users" do
    field :biography, :string
    field :contract, :binary
    field :email, :string
    field :node_corresponding, :integer
    field :password, :binary
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:node_corresponding, :username, :biography, :email, :password, :contract])
    |> validate_required([:node_corresponding, :username, :biography, :email, :password, :contract])
    |> unique_constraint(:node_corresponding)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> unique_constraint(:contract)
  end
end
