defmodule Exsemantica.Id128 do
  @moduledoc """
  An ID128 is a 128-bit identifier, that can be tested for equality by most
  SIMD engines.
  """

  defguard is_valid(item) when is_binary(item) and byte_size(item) == 16

  @doc """
  Converts a 16-byte binary into its base-64 Id128.
  ```elixir
      iex> Exsemantica.Id128.convert_to(<<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15>>)
      {:ok, "AAECAwQFBgcICQoLDA0ODw=="}
  ```
  """
  def convert_to(item) do
    case item do
      item when is_valid(item) -> {:ok, Base.url_encode64(item)}
      _ -> :error
    end
  end

  @doc """
  Converts a base-64 ID128 into a 16-byte binary.
  """
  def convert_from(item) do
    base64 = Base.url_decode64(item)

    case base64 do
      {:ok, extracted} when is_valid(extracted) -> {:ok, extracted}
      _ -> :error
    end
  end
end
