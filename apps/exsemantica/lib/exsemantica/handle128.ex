# Copyright 2019-2022 Roland Metivier
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
