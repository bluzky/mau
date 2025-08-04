defmodule Mau.Filters.CollectionFilters do
  @moduledoc """
  Collection manipulation filters for Mau templates.
  """

  @doc """
  Returns the length of a collection or string.
  
  ## Examples
  
      iex> Mau.Filters.CollectionFilters.length([1, 2, 3], [])
      {:ok, 3}
      
      iex> Mau.Filters.CollectionFilters.length("hello", [])
      {:ok, 5}
      
      iex> Mau.Filters.CollectionFilters.length(%{a: 1, b: 2}, [])
      {:ok, 2}
  """
  def length(value, _args) do
    result = case value do
      list when is_list(list) -> Enum.count(list)
      string when is_binary(string) -> String.length(string)
      map when is_map(map) -> map_size(map)
      _ -> 0
    end
    {:ok, result}
  end

  @doc """
  Returns the first element of a collection.
  
  ## Examples
  
      iex> Mau.Filters.CollectionFilters.first([1, 2, 3], [])
      1
      
      iex> Mau.Filters.CollectionFilters.first("hello", [])
      "h"
      
      iex> Mau.Filters.CollectionFilters.first([], [])
      nil
  """
  def first(value, _args) do
    case value do
      [first | _] -> first
      string when is_binary(string) and byte_size(string) > 0 ->
        String.first(string)
      _ -> nil
    end
  end

  @doc """
  Returns the last element of a collection.
  
  ## Examples
  
      iex> Mau.Filters.CollectionFilters.last([1, 2, 3], [])
      3
      
      iex> Mau.Filters.CollectionFilters.last("hello", [])
      "o"
      
      iex> Mau.Filters.CollectionFilters.last([], [])
      nil
  """
  def last(value, _args) do
    case value do
      list when is_list(list) -> List.last(list)
      string when is_binary(string) and byte_size(string) > 0 ->
        String.last(string)
      _ -> nil
    end
  end

  @doc """
  Joins elements of a collection with a separator.
  
  ## Examples
  
      iex> Mau.Filters.CollectionFilters.join([1, 2, 3], [", "])
      "1, 2, 3"
      
      iex> Mau.Filters.CollectionFilters.join(["a", "b", "c"], [])
      "abc"
      
      iex> Mau.Filters.CollectionFilters.join(["a", "b", "c"], ["-"])
      "a-b-c"
  """
  def join(value, args) do
    separator = case args do
      [sep] when is_binary(sep) -> sep
      [] -> ""
      _ -> ""
    end
    
    case value do
      list when is_list(list) ->
        list
        |> Enum.map(&to_string/1)
        |> Enum.join(separator)
      _ -> to_string(value)
    end
  end

  @doc """
  Sorts a collection.
  
  ## Examples
  
      iex> Mau.Filters.CollectionFilters.sort([3, 1, 2], [])
      [1, 2, 3]
      
      iex> Mau.Filters.CollectionFilters.sort(["c", "a", "b"], [])
      ["a", "b", "c"]
  """
  def sort(value, _args) do
    case value do
      list when is_list(list) -> Enum.sort(list)
      _ -> value
    end
  end

  @doc """
  Reverses a collection or string.
  
  ## Examples
  
      iex> Mau.Filters.CollectionFilters.reverse([1, 2, 3], [])
      [3, 2, 1]
      
      iex> Mau.Filters.CollectionFilters.reverse("hello", [])
      "olleh"
  """
  def reverse(value, _args) do
    case value do
      list when is_list(list) -> Enum.reverse(list)
      string when is_binary(string) -> String.reverse(string)
      _ -> value
    end
  end

  @doc """
  Returns unique elements from a collection.
  
  ## Examples
  
      iex> Mau.Filters.CollectionFilters.uniq([1, 2, 2, 3, 1], [])
      [1, 2, 3]
      
      iex> Mau.Filters.CollectionFilters.uniq(["a", "b", "a", "c"], [])
      ["a", "b", "c"]
  """
  def uniq(value, _args) do
    case value do
      list when is_list(list) -> Enum.uniq(list)
      _ -> value
    end
  end
end