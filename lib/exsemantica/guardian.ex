defmodule Exsemantica.Guardian do
  @moduledoc """
  Handles Guardian-based authentication.
  """
  use Guardian, otp_app: :exsemantica

  @spec subject_for_token(any(), any()) :: {:ok, nil | binary()}
  def subject_for_token(%Exsemantica.Repo.User{id: id}, _claims) do
    subject = to_string(id)

    {:ok, subject}
  end

  def subject_for_token(_map, _claims) do
    {:ok, nil}
  end

  @spec resource_from_claims(any()) :: {:error, :invalid_claims | :invalid_user} | {:ok, any()}
  def resource_from_claims(%{"sub" => id}) do
    user = Exsemantica.Repo.one(Exsemantica.Repo.User, id: id)

    case user do
      nil -> {:error, :invalid_user}
      resource -> {:ok, resource}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :invalid_claims}
  end
end
