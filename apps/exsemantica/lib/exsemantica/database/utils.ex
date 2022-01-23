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
defmodule Exsemantica.Database.Utils do
  @moduledoc """
  Utilities for the Mnesia database to make things easier.
  """
  require Exsemantica.Handle128

  @spec increment(any) :: <<_::128>>
  def increment(type) do
    cnt = :mnesia.dirty_update_counter(:counters, type, 1)
    <<cnt::128>>
  end

  # ============================================================================
  # Put items
  # ============================================================================
  @spec put_user(any) ::
          :error | %{info: {:users, <<_::128>>, binary}, operation: :put, table: :users}
  def put_user(raw_handle) do
    if Exsemantica.Handle128.is_valid(raw_handle) do
      id = increment(:id_count)
      handle = Exsemantica.Handle128.serialize(raw_handle)

      %{
        operation: :put,
        table: :users,
        info: {:users, id, handle}
      }
    else
      :error
    end
  end

  @spec put_post(binary, binary, <<_::128>>) :: %{
          info: {:posts, <<_::128>>, binary, binary, <<_::128>>},
          operation: :put,
          table: :posts
        }
  def put_post(title, content, user) do
    %{
      operation: :put,
      table: :posts,
      info: {:posts, increment(:id_count), title, content, user}
    }
  end

  @spec put_interest(binary, binary, [binary]) :: %{
          info: {:interests, <<_::128>>, binary, binary, [binary]},
          operation: :put,
          table: :interests
        }
  def put_interest(title, content, related_to) do
    %{
      operation: :put,
      table: :interests,
      info: {:interests, increment(:id_count), title, content, related_to}
    }
  end

  # ============================================================================
  # Get items
  # ============================================================================
  @spec get(atom, <<_::128>>) :: %{info: <<_::128>>, operation: :get, table: atom}
  def get(table, idx) do
    %{
      operation: :get,
      table: table,
      info: idx
    }
  end
end
