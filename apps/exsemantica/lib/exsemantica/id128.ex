defmodule Exsemantica.Id128 do
  @moduledoc """
  Am ID128 is a 128-bit identifier, that can be tested for equality by most
  SIMD engines.
  """

  @doc """
  Converts a 16-byte binary into its base-64 ID128.

  ```elixir
      iex> Exsemantica.Id128.serialize(<<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15>>)
      "AAECAwQFBgcICQoLDA0ODw=="
  ```
  """
  def serialize(item) when is_binary(item) and byte_size(item) == 16 do
    Base.url_encode64(item)
  end

  @doc """
  Converts a base-64 ID128 into a 16-byte binary.

  ```elixir
      iex> Exsemantica.Id128.parse("AAECAwQFBgcICQoLDA0ODw==")
      {:ok, <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15>>}
  ```
  """
  def parse(item) do
    base64 = Base.url_decode64(item)

    case base64 do
      {:ok, extracted} when byte_size(extracted) == 16 -> base64
      error -> error
    end
  end

  def parse!(item) do
    base64 = Base.url_decode64!(item)
    cond do
      byte_size(base64) == 16 -> base64
      true -> raise ArgumentError
    end
  end
end
