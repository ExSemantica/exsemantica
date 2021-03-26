defmodule LdGraph2.Heap do
  @moduledoc """
  A pairing heap with unique elements.
  """
  defstruct [par: nil, ch0: nil, ch1: nil]

  @doc """
  Creates a new heap map, used for storing the main heap.
  """
  def new() do
    %{0 => %LdGraph2.Heap{}}
  end

  @doc """
  Joins two heaps together.
  """
  def meld(heapmap, heap1i, heap2i) when heap1i < heap2i do
    heap1 = heapmap |> Map.get(heap1i)
    heapmap = case heap1 do
      # Create a new subheap
      nil -> heapmap |> Map.put(map_size(heapmap), %LdGraph2.Heap{par: heap2i})

      # One for one subheap
      %LdGraph2.Heap{ch0: nil, ch1: nil} -> %{heapmap | heap1i => %LdGraph2.Heap{heap1 | ch0: heap2i}}
        
      # Two for one subheaps
      %LdGraph2.Heap{ch0: _c0, ch1: nil} -> %{heapmap | heap1i => %LdGraph2.Heap{heap1 | ch1: heap2i}}

      # Create one subheap in place, HACK-y...
      %LdGraph2.Heap{ch0: ch0, ch1: _c1} -> heapmap |> meld(ch0, map_size(heapmap))
    end
    heap2 = heapmap |> Map.get(heap2i)
    case heap2 do
      # Nothing changed
      nil -> heapmap |> Map.put(heap2i, %LdGraph2.Heap{par: 0})

      # Get a subheap then just assign the children from before
      _h2 -> %{heapmap | heap2i => %LdGraph2.Heap{heap2 | par: heap1i}}
    end
  end

  def meld(heapmap, heap1i, heap2i) when heap1i > heap2i do
    heapmap |> meld(heap2i, heap1i)
  end

  @doc """
  Inserts a value onto a heap.
  """
  def insert(heapmap, heap1i) do
    heapmap |> meld(heap1i, 0)
  end

  @doc """
  Deletes the minimum (root) value of a heap.
  """
  def delete(heapmap, _heap1i) do
    heapmap # UNIMPLEMENTED
  end
end
