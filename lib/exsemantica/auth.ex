defmodule Exsemantica.Auth do
  @moduledoc """
  Low-level authentication code goes into this namespace
  """
  import Ecto.Query

  def check_user(username, password) do
    user_data = Exsemantica.Repo.one(from u in Exsemantica.Repo.User, where: ilike(u.username, ^username))

    case user_data do
      # User not found
      nil ->
        # Try not to let hash timing attacks succeed
        Argon2.no_user_verify()
        {:error, :not_found}

      # User found, authenticate them
      %Exsemantica.Repo.User{password: hash} ->
        if Argon2.verify_pass(password, hash) do
          {:ok, user_data}
        else
          {:error, :unauthorized}
        end
    end
  end

  def check_token(token) do
    resource = Exsemantica.Auth.Guardian.resource_from_token(token)

    case resource do
      {:ok, user, _claims} ->
        {:ok, user}

        {:error, error} ->
          {:error, error}
    end
  end
end
