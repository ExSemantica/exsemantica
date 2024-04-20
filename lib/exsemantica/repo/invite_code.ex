defmodule Exsemantica.Repo.InviteCode do
  @moduledoc """
  Optional storage for invite codes that are used for user registration
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "invite_codes" do
    field(:code, :binary)
    field(:is_valid, :boolean, default: true)
  end

  @doc false
  def changeset(invite_code, attrs) do
    invite_code
    |> cast(attrs, [:code, :is_valid])
    |> validate_required([:code, :is_valid])
    |> unique_constraint(:code)
  end
end
