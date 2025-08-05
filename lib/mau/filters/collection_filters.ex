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
    result =
      case value do
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
      [first | _] ->
        first

      string when is_binary(string) and byte_size(string) > 0 ->
        String.first(string)

      _ ->
        nil
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
      list when is_list(list) ->
        List.last(list)

      string when is_binary(string) and byte_size(string) > 0 ->
        String.last(string)

      _ ->
        nil
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
    separator =
      case args do
        [sep] when is_binary(sep) -> sep
        [] -> ""
        _ -> ""
      end

    case value do
      list when is_list(list) ->
        list
        |> Enum.map(&to_string/1)
        |> Enum.join(separator)

      _ ->
        to_string(value)
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

  @doc """
  Extracts a slice from a list or string.

  ## Examples

      iex> Mau.Filters.CollectionFilters.slice([1, 2, 3, 4, 5], [1, 3])
      {:ok, [2, 3, 4]}
      
      iex> Mau.Filters.CollectionFilters.slice("hello", [1, 3])
      {:ok, "ell"}
      
      iex> Mau.Filters.CollectionFilters.slice([1, 2, 3], [1])
      {:ok, [2, 3]}
  """
  def slice(value, args) do
    case {value, args} do
      {list, [start]} when is_list(list) and is_integer(start) ->
        {:ok, Enum.drop(list, start)}

      {list, [start, length]} when is_list(list) and is_integer(start) and is_integer(length) ->
        {:ok, list |> Enum.drop(start) |> Enum.take(length)}

      {string, [start]} when is_binary(string) and is_integer(start) ->
        {:ok, String.slice(string, start..-1)}

      {string, [start, length]}
      when is_binary(string) and is_integer(start) and is_integer(length) ->
        {:ok, String.slice(string, start, length)}

      _ ->
        {:error, "slice requires start index and optional length"}
    end
  end

  @doc """
  Checks if a collection contains a value.

  ## Examples

      iex> Mau.Filters.CollectionFilters.contains([1, 2, 3], [2])
      {:ok, true}
      
      iex> Mau.Filters.CollectionFilters.contains("hello", ["ll"])
      {:ok, true}
      
      iex> Mau.Filters.CollectionFilters.contains(%{a: 1, b: 2}, ["a"])
      {:ok, true}
  """
  def contains(value, args) do
    case {value, args} do
      {list, [item]} when is_list(list) ->
        {:ok, Enum.member?(list, item)}

      {string, [substring]} when is_binary(string) and is_binary(substring) ->
        {:ok, String.contains?(string, substring)}

      {map, [key]} when is_map(map) ->
        {:ok, Map.has_key?(map, key)}

      _ ->
        {:error, "contains requires a value to search for"}
    end
  end

  @doc """
  Removes nil values from a list.

  ## Examples

      iex> Mau.Filters.CollectionFilters.compact([1, nil, 2, nil, 3], [])
      {:ok, [1, 2, 3]}
      
      iex> Mau.Filters.CollectionFilters.compact([], [])
      {:ok, []}
  """
  def compact(value, _args) do
    case value do
      list when is_list(list) ->
        {:ok, Enum.reject(list, &is_nil/1)}

      _ ->
        {:ok, value}
    end
  end

  @doc """
  Flattens nested lists.

  ## Examples

      iex> Mau.Filters.CollectionFilters.flatten([[1, 2], [3, 4]], [])
      {:ok, [1, 2, 3, 4]}
      
      iex> Mau.Filters.CollectionFilters.flatten([1, [2, [3, 4]]], [])
      {:ok, [1, 2, 3, 4]}
  """
  def flatten(value, _args) do
    case value do
      list when is_list(list) ->
        {:ok, List.flatten(list)}

      _ ->
        {:ok, value}
    end
  end

  @doc """
  Sums numeric values in a list.

  ## Examples

      iex> Mau.Filters.CollectionFilters.sum([1, 2, 3, 4], [])
      {:ok, 10}
      
      iex> Mau.Filters.CollectionFilters.sum([1.5, 2.5], [])
      {:ok, 4.0}
      
      iex> Mau.Filters.CollectionFilters.sum([1, "2", 3], [])
      {:ok, 4}
  """
  def sum(value, _args) do
    case value do
      list when is_list(list) ->
        result =
          list
          |> Enum.filter(&is_number/1)
          |> Enum.sum()

        {:ok, result}

      _ ->
        {:ok, 0}
    end
  end

  @doc """
  Gets the keys of a map.

  ## Examples

      iex> Mau.Filters.CollectionFilters.keys(%{a: 1, b: 2}, [])
      {:ok, [:a, :b]}
      
      iex> Mau.Filters.CollectionFilters.keys(%{"x" => 1, "y" => 2}, [])
      {:ok, ["x", "y"]}
  """
  def keys(value, _args) do
    case value do
      map when is_map(map) ->
        {:ok, Map.keys(map)}

      _ ->
        {:ok, []}
    end
  end

  @doc """
  Gets the values of a map.

  ## Examples

      iex> Mau.Filters.CollectionFilters.values(%{a: 1, b: 2}, [])
      {:ok, [1, 2]}
      
      iex> Mau.Filters.CollectionFilters.values(%{"x" => 1, "y" => 2}, [])
      {:ok, [1, 2]}
  """
  def values(value, _args) do
    case value do
      map when is_map(map) ->
        {:ok, Map.values(map)}

      _ ->
        {:ok, []}
    end
  end

  @doc """
  Groups list elements by a key field.

  ## Examples

      iex> users = [%{"name" => "Alice", "role" => "admin"}, %{"name" => "Bob", "role" => "user"}, %{"name" => "Carol", "role" => "admin"}]
      iex> Mau.Filters.CollectionFilters.group_by(users, ["role"])
      {:ok, %{"admin" => [%{"name" => "Alice", "role" => "admin"}, %{"name" => "Carol", "role" => "admin"}], "user" => [%{"name" => "Bob", "role" => "user"}]}}
  """
  def group_by(value, args) do
    case {value, args} do
      {list, [key]} when is_list(list) ->
        result =
          Enum.group_by(list, fn item ->
            case item do
              map when is_map(map) -> Map.get(map, key)
              _ -> nil
            end
          end)

        {:ok, result}

      _ ->
        {:error, "group_by requires a key field"}
    end
  end

  @doc """
  Extracts field values from a list of maps, filtering out nil values.

  Only works with maps (including structs). Non-map entries are ignored.
  Only returns values where the field exists and is not nil.

  ## Examples

      iex> users = [%{"name" => "Alice"}, %{"name" => "Bob"}]
      iex> Mau.Filters.CollectionFilters.map(users, ["name"])
      {:ok, ["Alice", "Bob"]}

      iex> users = [%{"name" => "Alice"}, %{}, %{"name" => "Bob", "email" => nil}]
      iex> Mau.Filters.CollectionFilters.map(users, ["name"])
      {:ok, ["Alice"]}
  """
  def map(value, args) do
    case {value, args} do
      {list, [field]} when is_list(list) ->
        result =
          list
          |> Enum.map(fn item ->
            if is_map(item) do
              Map.get(item, field)
            else
              nil
            end
          end)
          |> Enum.filter(&(&1 != nil))

        {:ok, result}

      _ ->
        {:error, "map requires a field name"}
    end
  end

  @doc """
  Filters list of maps by field value.

  Only works with maps (including structs). Non-map entries are excluded from results.

  ## Examples

      iex> users = [%{"name" => "Alice", "active" => true}, %{"name" => "Bob", "active" => false}]
      iex> Mau.Filters.CollectionFilters.filter(users, ["active", true])
      {:ok, [%{"name" => "Alice", "active" => true}]}
  """
  def filter(value, args) do
    case {value, args} do
      {list, [field, filter_value]} when is_list(list) ->
        result =
          Enum.filter(list, fn item ->
            if is_map(item) do
              Map.get(item, field) == filter_value
            else
              false
            end
          end)

        {:ok, result}

      _ ->
        {:error, "filter requires field name and value"}
    end
  end

  @doc """
  Rejects list of maps by field value (opposite of filter).

  Only works with maps (including structs). Non-map entries are excluded from results.

  ## Examples

      iex> users = [%{"name" => "Alice", "active" => true}, %{"name" => "Bob", "active" => false}]
      iex> Mau.Filters.CollectionFilters.reject(users, ["active", false])
      {:ok, [%{"name" => "Alice", "active" => true}]}
  """
  def reject(value, args) do
    case {value, args} do
      {list, [field, reject_value]} when is_list(list) ->
        result =
          Enum.reject(list, fn item ->
            if is_map(item) do
              Map.get(item, field) == reject_value
            else
              false
            end
          end)

        {:ok, result}

      _ ->
        {:error, "reject requires field name and value"}
    end
  end

  @doc """
  Formats data structures for display (debugging).

  ## Examples

      iex> Mau.Filters.CollectionFilters.dump(%{a: 1, b: 2}, [])
      {:ok, "%{a: 1, b: 2}"}
      
      iex> Mau.Filters.CollectionFilters.dump([1, 2, 3], [])
      {:ok, "[1, 2, 3]"}
  """
  def dump(value, _args) do
    {:ok, inspect(value)}
  end
end
