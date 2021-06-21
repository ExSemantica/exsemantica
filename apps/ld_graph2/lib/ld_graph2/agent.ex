# Copyright 2020-2021 Roland Metivier
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
defmodule LdGraph2.Agent do
  @moduledoc """
  An agent that manages a graph, allowing key-value databases to be used
  instead of a purposefully-built graph database.

  Note that a few special graph operations like searching are not implemented
  yet.
  """
  use Agent

  @spec start_link(binary) :: {:error, any} | {:ok, pid}
  @doc """
  Starts the agent, loading the specified graph off the `LdGraph2`
  application's priv directory.
  """
  def start_link(name) do
    Agent.start_link(fn ->
      candidates =
        Path.wildcard(
          Path.join([
            Application.app_dir(:ld_graph2, "priv"),
            name,
            "*.ld2"
          ])
        )
        |> Enum.map(fn file ->
          {:ok, date, _} = Path.basename(file, ".ld2") |> DateTime.from_iso8601()
          date
        end)
        |> Enum.sort(DateTime)

      {name,
       case candidates do
         [] ->
           File.mkdir(
             Path.join([
               Application.app_dir(:ld_graph2, "priv"),
               name
             ])
           )

           {%LdGraph2.Graph{}, nil}

         _ ->
           candidates
           |> Enum.reduce([], fn sorted, acc ->
             date = DateTime.to_iso8601(sorted)

             {:ok, terms} =
               :file.consult(
                 to_charlist(
                   Path.join([
                     Application.app_dir(:ld_graph2, "priv"),
                     name,
                     "#{date}.ld2"
                   ])
                 )
               )

             [terms | acc]
           end)
       end
       |> List.flatten()
       |> Enum.reduce(%LdGraph2.Graph{}, &apply_delta/2)}
    end)
  end

  @spec get(atom | pid | {atom, any} | {:via, atom, any}) :: any
  @doc """
  Gets the current graph data.
  """
  def get(agent) do
    Agent.get(agent, fn {_name, graph} ->
      graph
    end)
  end

  @spec update(atom | pid | {atom, any} | {:via, atom, any}, any) :: :ok
  @doc """
  Applies a transaction/delta to a `LdGraph2.Graph`, saving to disk.

  ## Examples
  Listed below are a few examples of possible transactions. Each tuple is
  processed left-to-right within the list.

  ```elixir
  [{:add, {:node, 2}}]
  [{:add, {:node, 0}}, {:add, {:node, 1}}, {:add, {:edge, 0, 1}}]
  [{:del, {:edge, 0, 1}}]
  ```
  """
  def update(agent, transactions) do
    Agent.update(agent, fn {name, graph} ->
      date = DateTime.to_iso8601(DateTime.utc_now())

      File.write(
        Path.join([
          Application.app_dir(:ld_graph2, "priv"),
          name,
          "#{date}.ld2"
        ]),
        :io_lib.fwrite('~p.\n', transactions, encoding: :utf8)
      )

      {name, transactions |> Enum.reduce(graph, &apply_delta/2)}
    end)
  end

  defp apply_delta(delta, graph) do
    case delta do
      {:add, what} ->
        case what do
          {:node, at} -> LdGraph2.Graph.put_node(graph, at)
          {:edge, from, to} -> LdGraph2.Graph.put_edge(graph, from, to)
        end

      {:del, what} ->
        case what do
          {:node, at} -> LdGraph2.Graph.del_node(graph, at)
          {:edge, from, to} -> LdGraph2.Graph.del_edge(graph, from, to)
        end
    end
  end
end
