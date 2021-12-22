defmodule Exsemantica.Handle128 do
  @moduledoc """
  A Handle128 is a 16-char ASCII identifier, that can be tested for equality by
  most SIMD engines.
  """

  defguard is_valid(item) when is_binary(item) and byte_size(item) > 0 and byte_size(item) <= 16

  @doc """
  Converts a 16-char handle into its Handle128.
  **THIS IS A LOSSY CONVERSION**.

  ```elixir
      iex> Exsemantica.Handle128.serialize("FooBarBaz")
      "FooBarBaz       "
  ```
  ```elixir
      iex> Exsemantica.Handle128.serialize("FooBarBazFooBarBaz")
      :error
  ```
  """
  def serialize(item) do
    case Unidecode.decode(item) do
      ascii when is_valid(ascii) -> String.pad_trailing(ascii, 16)
      _ -> :error
    end
  end

  @doc """
  Converts a Handle128 into a 16-byte binary.

  ```elixir
      iex> Exsemantica.Handle128.parse("")
  ```
  """
  def parse(item) do
    item # requires nothing, lossy conversion is done and over with.
  end
end
