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
defmodule LdGraph2.Store do
  @moduledoc """
  A storage for `LdGraph2.Graph`.
  """
  use Agent

  @spec start_link(any) :: {:error, any} | {:ok, pid}
  def start_link(name) do
    Agent.start_link(fn ->
      {:ok, hard_table} = open_hard(name)

      table = :ets.new(:storage, [:private, :ordered_set])
      :ets.from_dets(table, hard_table)
      :dets.close(hard_table)
      {name, table}
    end)
  end

  @spec read(pid) :: %LdGraph2.Graph{}
  def read(agent) do
    Agent.get(agent, fn {_name, table} ->
      %LdGraph2.Graph{nodes: table |> :ets.tab2list() |> Map.new()}
    end)
  end

  ### =========================================================================
  ###  Nodes
  ### =========================================================================
  @spec insert_nodes(pid, [any]) :: :ok
  def insert_nodes(agent, nodes) do
    Agent.update(agent, fn {name, table} ->
      {:ok, hard_table} = open_hard(name)

      :ets.insert_new(table, Enum.map(nodes, fn item -> {item, []} end))
      :ets.to_dets(table, hard_table)
      :dets.close(hard_table)
      {name, table}
    end)
  end

  @spec delete_nodes(pid, [any]) :: :ok
  def delete_nodes(agent, nodes) do
    Agent.update(agent, fn {name, table} ->
      {:ok, hard_table} = open_hard(name)

      nodes |> Enum.map(fn selected -> :ets.delete(table, selected) end)
      :ets.to_dets(table, hard_table)
      :dets.close(hard_table)
      {name, table}
    end)
  end

  ### =========================================================================
  ###  Edges
  ### =========================================================================

  defp open_hard(name) do
    :dets.open_file(to_charlist(name),
      file: to_charlist(Path.join([Application.app_dir(:ld_graph2, "priv"), "#{name}.dets"])),
      type: :set
    )
  end
end
