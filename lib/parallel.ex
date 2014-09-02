defmodule Parallel do

  @moduledoc """
  Works just like Enum.map, but in parallel across all cores.
  """

  @doc """
  Pass in a `collection` and a `function` to apply in parallel to
  all elements of the collection. This will light up all cores.

      ## Examples
      iex> result = Parallel.pmap(1..1000, &(&1 * &1))
      iex> [1, 4, 9, 16, 25] = Enum.take(result, 5)

  """
  def pmap(collection, func) do
    collection
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(&Task.await/1)
  end

end
