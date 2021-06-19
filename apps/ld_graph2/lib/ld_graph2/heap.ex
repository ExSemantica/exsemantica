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
defmodule LdGraph2.Heap do
  @moduledoc """
  A pairing heap.
  """
  defstruct root: 0, children: []

  @spec meld(%LdGraph2.Heap{}, %LdGraph2.Heap{}) :: %LdGraph2.Heap{}
  @doc """
  Joins two heaps together.
  """
  def meld(heap1, heap2) when heap1.root > heap2.root do
    %LdGraph2.Heap{root: heap1.root + 1, children: [heap1 | heap2.children]}
  end

  def meld(heap1, heap2) do
    %LdGraph2.Heap{root: heap2.root + 1, children: [heap2 | heap1.children]}
  end

  @spec insert(%LdGraph2.Heap{}) :: %LdGraph2.Heap{}
  @doc """
  Inserts a value onto a heap.
  """
  def insert(heap) do
    meld(heap, %LdGraph2.Heap{root: heap.root, children: []})
  end

  @spec delete_max(%LdGraph2.Heap{}) :: %LdGraph2.Heap{}
  @doc """
  Deletes the maximum (root) value of a heap.
  """
  def delete_max(heap) do
    merge_pairs(heap.children)
  end

  defp merge_pairs([head1 | []]) do
    head1
  end

  defp merge_pairs([head1 | [head2 | []]]) do
    meld(head1, head2)
  end

  defp merge_pairs([head1 | [head2 | tail]]) do
    meld(meld(head1, head2), merge_pairs(tail))
  end
end
