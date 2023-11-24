defmodule Exsemantica.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :password, :string, redact: true
    field :biography, :string
    field :email, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :biography, :email, :password])
    |> validate_required([:username, :biography, :email, :password])
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end
end
