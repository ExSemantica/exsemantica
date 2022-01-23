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
          |> Enum.map(&Exsemantica.Database.Utils.get(:posts, &1))
          |> Exsemantica.Database.transaction()

        {:ok,
         packets
         |> Enum.map(fn packet ->
           if length(packet.response) == 1 do
             [{:posts, id, title, content, posted_by}] = packet.response

             %{
               node: Exsemantica.Id128.serialize(id),
               title: title,
               content: content,
               posted_by: posted_by
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
          |> Enum.map(&Exsemantica.Database.Utils.get(:users, &1))
          |> Exsemantica.Database.transaction()

        {:ok,
         packets
         |> Enum.map(fn packet ->
           if length(packet.response) == 1 do
             [{:users, id, handle}] = packet.response

             %{
               node: Exsemantica.Id128.serialize(id),
               handle: handle
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
          |> Enum.map(&Exsemantica.Database.Utils.get(:interests, &1))
          |> Exsemantica.Database.transaction()

        {:ok,
         packets
         |> Enum.map(fn packet ->
           if length(packet.response) == 1 do
             [{:interests, id, title, content, related_to}] = packet.response

             %{
               node: Exsemantica.Id128.serialize(id),
               title: title,
               content: content,
               related_to: related_to
             }
           else
             nil
           end
         end)}
      end)
    end
  end
end
