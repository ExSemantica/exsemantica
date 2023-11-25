defmodule Exsemantica.Constrain do
  @moduledoc """
  Functions for converting usernames and aggregates into valid data

  These try to convert into a subset of valid IRC nickname characters
  """
  # ===========================================================================
  defguardp is_valid_char(item)
            when item in 0x30..0x39 or item in 0x41..0x5A or item in 0x61..0x7A or item == 0x5F

  defguardp is_valid_agg_pre(item)
            when is_binary(item) and byte_size(item) > 0 and byte_size(item) <= 32

  defguardp is_valid_pre(item)
            when is_binary(item) and byte_size(item) > 0 and byte_size(item) <= 16

  # ===========================================================================
  defp preconvert(input),
    do:
      input
      |> Unidecode.decode()
      |> String.trim()
      |> String.replace(" ", "_")

  defp postconvert(input) do
    ascii? = input |> to_charlist |> Enum.all?(&is_valid_char/1)

    if ascii?, do: {:ok, input}, else: :error
  end

  # ===========================================================================
  @spec into_valid_username(binary()) :: :error | {:ok, binary()}
  @doc """
  Convert into a valid username, or else return the atom `:error`
  """
  def into_valid_username(input) do
    case input |> preconvert do
      ascii when ascii |> is_valid_pre ->
        ascii |> postconvert

      _other ->
        :error
    end
  end

  @spec into_valid_aggregate(binary()) :: :error | {:ok, binary()}
  @doc """
  Convert into a valid aggregate, or else return the atom `:error`
  """
  def into_valid_aggregate(input) do
    case input |> preconvert do
      ascii when ascii |> is_valid_agg_pre ->
        ascii |> postconvert

      _other ->
        :error
    end
  end
end
