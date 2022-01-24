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

  def increment_popularity(table, idx) do
    %{
      operation: :rank,
      table: table,
      info: %{idx: idx, inc: 1}
    }
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
        info: {:users, id, DateTime.utc_now(), handle}
      }
    else
      :error
    end
  end

  @spec put_post(any, any, any) :: %{
          info: {:posts, <<_::128>>, DateTime.t(), any, any, any},
          operation: :put,
          table: :posts
        }
  def put_post(title, content, user) do
    %{
      operation: :put,
      table: :posts,
      info: {:posts, increment(:id_count), DateTime.utc_now(), title, content, user}
    }
  end

  @spec put_interest(any, any, any) :: %{
          info: {:interests, <<_::128>>, DateTime.t(), any, any, any},
          operation: :put,
          table: :interests
        }
  def put_interest(title, content, related_to) do
    id = increment(:id_count)

    %{
      operation: :put,
      table: :interests,
      info: {:interests, id, DateTime.utc_now(), title, content, related_to}
    }
  end

  # ============================================================================
  # Get items
  # ============================================================================
  def get(table, idx) do
    %{
      operation: :get,
      table: table,
      info: idx
    }
  end

  @spec trending(integer) :: %{info: any, operation: :tail, table: :ctrending}
  def trending(count) do
    %{
      operation: :tail,
      table: :ctrending,
      info: count
    }
  end
end
