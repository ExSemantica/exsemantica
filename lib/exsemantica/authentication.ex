defmodule Exsemantica.Authentication do
  @moduledoc """
  Low-level authentication code goes into this namespace
  """
  import Ecto.Query

  @doc """
  Checks if a username and password are valid
  """
  def check_user(username, password) do
    user_data =
      Exsemantica.Repo.one(from(u in Exsemantica.Repo.User, where: ilike(u.username, ^username)))

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

  @doc """
  Checks if an authentication token is valid
  """
  def check_token(token) do
    resource = Exsemantica.Guardian.resource_from_token(token)

    case resource do
      {:ok, user, _claims} ->
        {:ok, user}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Gets how many minutes an authentication token shall last
  """
  def get_minutes_grace() do
    Application.get_env(:exsemantica, __MODULE__)[:minutes_grace]
  end

  @doc """
  Tries to parse the "Bearer" header from a secure HTTP request
  """
  def extract_bearer([raw_header]) do
    case raw_header |> String.split(" ") do
      ["Bearer", token] -> {:ok, token}
      _ -> :error
    end
  end

  def extract_bearer(_), do: :error
end
