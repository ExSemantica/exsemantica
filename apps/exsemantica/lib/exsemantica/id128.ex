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
defmodule Exsemantica.Id128 do
  @moduledoc """
  An ID128 is a 128-bit identifier, that can be tested for equality by most
  SIMD engines.
  """

  defguard is_valid(item) when is_binary(item) and byte_size(item) == 16

  @doc """
  Converts a 16-byte binary into its base-64 ID128.

  ```elixir
      iex> Exsemantica.Id128.serialize(<<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15>>)
      "AAECAwQFBgcICQoLDA0ODw=="
  ```
  """
  def serialize(item) do
    case item do
      item when is_valid(item) -> Base.url_encode64(item)
      _ -> :error
    end
  end

  @doc """
  Converts a base-64 ID128 into a 16-byte binary.

  ```elixir
      iex> Exsemantica.Id128.parse("AAECAwQFBgcICQoLDA0ODw==")
      <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15>>
  ```
  """
  def parse(item) do
    base64 = Base.url_decode64(item)

    case base64 do
      {:ok, extracted} when is_valid(extracted) -> extracted
      _error -> :error
    end
  end
end
