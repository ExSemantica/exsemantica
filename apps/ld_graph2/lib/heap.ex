defmodule LdGraph2.Heap do
  @moduledoc """
  A pairing heap.
  """
  defstruct [root: 0, child: nil, sibling: []]

  @doc """
  Joins two heaps together.
  """
  def meld(heap1, heap2) when heap1.root > heap2.root do
    %LdGraph2.Heap{root: heap1.root + 1, child: heap1.child, sibling: [heap1 | heap2.sibling]}
  end
  def meld(heap1, heap2) do
    %LdGraph2.Heap{root: heap2.root + 1, child: heap2.child, sibling: [heap2 | heap1.sibling]}
  end

  @doc """
  Inserts an integer into a heap.
  """
  def insert(heap) do
    meld(heap, %LdGraph2.Heap{root: heap.root, child: nil, sibling: []})
  end
end
