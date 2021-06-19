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
  A graph based on `LdGraph2.Heap` pairing heaps.
  """
  # NOTE: There may be a time where we start doing fancy stuff in graphs.
  # EXAMPLE: Compressing graphs
  # EXAMPLE: Caching in graphs
  # For now, we'll store a graph as a struct with only a map.
  defstruct nodes: %{}

  @spec put_node(%LdGraph2.Graph{}, any) :: %LdGraph2.Graph{}
  def put_node(graph, at) do
    %LdGraph2.Graph{graph | nodes: graph.nodes |> Map.put_new(at, MapSet.new())}
  end

  @spec put_edge(%LdGraph2.Graph{}, any, any) :: %LdGraph2.Graph{}
  def put_edge(graph = %{nodes: nodes}, from, to) when is_map_key(nodes, from) do
    node_at = nodes[from]
    %LdGraph2.Graph{graph | nodes: %{nodes | from => node_at |> MapSet.put(to)}}
  end
end
