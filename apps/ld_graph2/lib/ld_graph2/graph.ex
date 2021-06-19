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
defmodule LdGraph2.Graph do
  @moduledoc """
  A directed graph.
  """
  # NOTE: There may be a time where we start doing fancy stuff in graphs.
  # EXAMPLE: Compressing graphs
  # EXAMPLE: Caching in graphs
  # For now, we'll store a graph as a struct with only a map.
  defstruct nodes: %{}

  ### =========================================================================
  ###  Putting new nodes and edges
  ### =========================================================================
  @spec put_node(%LdGraph2.Graph{}, any) :: %LdGraph2.Graph{}
  @doc """
  Creates a node with the specified key, not connected to any other nodes.

  ## Examples
  ```elixir
      iex> %LdGraph2.Graph{} |> LdGraph2.Graph.put_node(0) ===
      ...> %LdGraph2.Graph{nodes: %{0 => []}}
      true
  ```
  """
  def put_node(graph = %{nodes: nodes}, at) do
    %LdGraph2.Graph{graph | nodes: nodes |> Map.put_new(at, [])}
  end

  @spec put_edge(%LdGraph2.Graph{}, any, any) :: %LdGraph2.Graph{}
  @doc """
  Creates an edge pointing from the specified key to another specified key.

  Note that each edge points to and from nodes that already exist, and each
  edge must be unique.

  ## Examples
  ```elixir
      iex> %LdGraph2.Graph{}
      ...> |> LdGraph2.Graph.put_node(0)
      ...> |> LdGraph2.Graph.put_node(1)
      ...> |> LdGraph2.Graph.put_edge(0, 1)
      %LdGraph2.Graph{nodes: %{0 => [1], 1 => []}}
  ```
  """
  def put_edge(graph = %{nodes: nodes}, from, to) when is_map_key(nodes, from) do
    node_at = nodes[from]

    %LdGraph2.Graph{
      graph
      | nodes: %{nodes | from => node_at |> MapSet.new() |> MapSet.put(to) |> MapSet.to_list()}
    }
  end

  ### =========================================================================
  ###  Deleting old nodes and edges
  ### =========================================================================
  @spec del_node(%LdGraph2.Graph{}, any) :: %LdGraph2.Graph{}
  @doc """
  Deletes the specified node if it exists. Otherwise, the graph is left as is.
  ## Examples
  ```elixir
      iex> %LdGraph2.Graph{}
      ...> |> LdGraph2.Graph.put_node(0)
      ...> |> LdGraph2.Graph.del_node(0)
      %LdGraph2.Graph{nodes: %{}}
  ```
  """
  def del_node(graph = %{nodes: nodes}, at) do
    %LdGraph2.Graph{graph | nodes: nodes |> Map.delete(at)}
  end

  @spec del_edge(%LdGraph2.Graph{}, any, any) :: %LdGraph2.Graph{}
  @doc """
  Deletes the specified edge connection, if the connection to the destination
  exists. Otherwise, the graph is left as is.

  If the node we are connecting from does not exist, an error will be thrown.
  ## Examples
  ```elixir
      iex> %LdGraph2.Graph{}
      ...> |> LdGraph2.Graph.put_node(0)
      ...> |> LdGraph2.Graph.put_node(1)
      ...> |> LdGraph2.Graph.put_edge(0, 1)
      ...> |> LdGraph2.Graph.del_edge(0, 1)
      %LdGraph2.Graph{nodes: %{0 => [], 1 => []}}
  ```
  """
  def del_edge(graph = %{nodes: nodes}, from, to) when is_map_key(nodes, from) do
    node_at = nodes[from]

    %LdGraph2.Graph{
      graph
      | nodes: %{
          nodes
          | from =>
              node_at
              |> MapSet.new()
              |> MapSet.delete(to)
              |> MapSet.to_list()
        }
    }
  end
end
