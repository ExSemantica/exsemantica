defmodule Exsemantica.Administration.ModifyUsers do
  @moduledoc """
  Administation utilities to modify the users database
  """
  require Logger

  @doc """
  Registers a user if the resulting handle is valid
  """
  def new(username, password, email, description) do
    case Exsemantica.Handle128.convert_to(username) do
      {:ok, handle} ->
        Logger.info("Registering new user #{username}")

        Exsemantica.Repo.insert(%Exsemantica.User{
          handle: handle,
          password: Argon2.hash_pwd_salt(password),
          email: email,
          description: description
        })

      :error ->
        Logger.error("Could not convert new username into a Handle128")
    end
  end
end
