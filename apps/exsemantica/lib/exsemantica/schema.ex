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
defmodule Exsemantica.Schema do
  @moduledoc """
  The ExSemantica GraphQL API schema.
  """
  use Absinthe.Schema

  import_types(Exsemantica.Schema.Types)

  query do
    field :posts, list_of(:post) do
      arg(:ids, list_of(:id128))

      complexity(fn %{ids: ids}, child_complexity ->
        length(ids) * child_complexity
      end)

      resolve(fn %{ids: ids}, _ ->
        {:atomic, packets} =
          ids
          |> Enum.uniq()
          |> Enum.map(&Exsemantica.Database.Utils.get(:posts, &1))
          |> Exsemantica.Database.transaction()

        {:ok,
         packets
         |> Enum.map(fn packet ->
           if length(packet.response) == 1 do
             [{:posts, id, timestamp, title, content, posted_by}] = packet.response

             %{
               node: id,
               title: title,
               content: content,
               posted_by: posted_by,
               timestamp: timestamp
             }
           else
             nil
           end
         end)}
      end)
    end

    field :users, list_of(:user) do
      arg(:ids, list_of(:id128))

      complexity(fn %{ids: ids}, child_complexity ->
        length(ids) * child_complexity
      end)

      resolve(fn %{ids: ids}, _ ->
        {:atomic, packets} =
          ids
          |> Enum.uniq()
          |> Enum.map(&Exsemantica.Database.Utils.get(:users, &1))
          |> Exsemantica.Database.transaction()

        {:ok,
         packets
         |> Enum.map(fn packet ->
           if length(packet.response) == 1 do
             [{:users, id, timestamp, handle}] = packet.response

             %{
               node: id,
               handle: handle,
               timestamp: timestamp
             }
           else
             nil
           end
         end)}
      end)
    end

    field :interests, list_of(:interest) do
      arg(:ids, list_of(:id128))

      complexity(fn %{ids: ids}, child_complexity ->
        length(ids) * child_complexity
      end)

      resolve(fn %{ids: ids}, _ ->
        {:atomic, packets} =
          ids
          |> Enum.uniq()
          |> Enum.map(&Exsemantica.Database.Utils.get(:interests, &1))
          |> Exsemantica.Database.transaction()

        {:ok,
         packets
         |> Enum.map(fn packet ->
           if length(packet.response) == 1 do
             [{:interests, id, timestamp, title, content, related_to}] = packet.response

             %{
               node: id,
               title: title,
               content: content,
               related_to: related_to,
               timestamp: timestamp
             }
           else
             nil
           end
         end)}
      end)
    end

    field :trending, list_of(:interest) do
      arg(:count, :integer)

      complexity(fn %{count: count}, child_complexity ->
        count * child_complexity
      end)

      resolve(fn %{count: count}, _ ->
        {:atomic, packets} =
          [Exsemantica.Database.Utils.trending(count)]
          |> Exsemantica.Database.transaction()

        {:ok,
         packets
         |> Enum.map(fn packet ->
           if length(packet.response) == 1 and packet.response != [[:"$end_of_table"]] do
             [{:interests, id, timestamp, title, content, related_to}] = packet.response

             %{
               node: id,
               title: title,
               content: content,
               related_to: related_to,
               timestamp: timestamp
             }
           else
             nil
           end
         end)}
      end)
    end
  end
end
