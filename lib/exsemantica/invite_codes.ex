defmodule Exsemantica.InviteCodes do
  @moduledoc """
  Handle manipulation of invite codes
  """
  import Ecto.Query

  @spec reset() :: :ok
  @doc """
  Refresh the invite code system.
  """
  def reset do
    # Get a new one-time generated number
    nonce = <<:erlang.unique_integer()::128>>

    # Put it in a persistent_term
    :persistent_term.put(__MODULE__.Nonce, nonce)
  end

  @spec generate() :: {:ok, binary()}
  @doc """
  Generates a valid Base64-encoded invite code.
  """
  def generate do
    nonce = :persistent_term.get(__MODULE__.Nonce)
    total = <<Exsemantica.Repo.aggregate(Exsemantica.Repo.InviteCode, :count)::64>>
    unix_time = DateTime.utc_now() |> DateTime.to_unix()
    digest = :crypto.hash(:sha3_256, nonce <> <<unix_time::64>> <> total)

    {:ok, _schema} = Exsemantica.Repo.insert(%Exsemantica.Repo.InviteCode{code: digest})
    {:ok, digest |> Base.url_encode64()}
  end

  @spec is_valid(binary()) :: boolean()
  @doc """
  Returns true if the Base64-encoded invite code is valid.
  """
  def is_valid(code) do
    case Base.url_decode64(code) do
      {:ok, digest} ->
        Exsemantica.Repo.one(
          from(c in Exsemantica.Repo.InviteCode, where: c.code == ^digest, select: c.is_valid)
        ) || false

      :error ->
        false
    end
  end

  @spec use(binary()) :: :error | :ok
  @doc """
  Tries to invalidate the Base64-encoded invite code.
  """
  def use(code) do
    case Base.url_decode64(code) do
      {:ok, digest} ->
        case Exsemantica.Repo.one(
               from(c in Exsemantica.Repo.InviteCode,
                 where: c.code == ^digest and c.is_valid,
                 select: c
               )
             ) do
          code_entry = %Exsemantica.Repo.InviteCode{} ->
            {:ok, _changed} =
              code_entry
              |> Ecto.Changeset.change(%{is_valid: false})
              |> Exsemantica.Repo.update()

            :ok

          nil ->
            :error
        end

      :error ->
        :error
    end
  end
end
