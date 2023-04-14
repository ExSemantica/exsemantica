defmodule Exsemantica.AggHandle do
  @moduledoc """
  An AggHandle is a lowercase ASCII identifier used to identify aggregates.
  """

  defguard is_valid(item) when is_binary(item) and byte_size(item) > 0 and byte_size(item) <= 32

  @doc """
  Converts a handle into an AggHandle with at most 32 characters.
  **THIS IS A LOSSY CONVERSION**.
  ```elixir
      iex> Exsemantica.AggHandle.convert_to("老干妈")
      {:ok, "lao_gan_ma"}
  ```
  """
  def convert_to(item) do
    case item
         |> Unidecode.decode()
         |> String.trim()
         |> String.replace(" ", "_") do
      ascii when is_valid(ascii) ->
        chars_ascii? =
          ascii
          |> to_charlist()
          |> Enum.all?(&(&1 in 0x21..0x7E))

        if chars_ascii? do
          {:ok, ascii}
        else
          :error
        end

      _ ->
        :error
    end
  end
end
