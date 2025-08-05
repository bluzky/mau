defmodule Mau.Filters.Collection do
  @moduledoc """
  Collection manipulation filters.
  """

  @doc """
  Returns the filter specification for this module.
  """
  def spec do
    %{
      category: :collection,
      description: "Collection manipulation and utility filters",
      filters: %{
        "length" => %{
          description: "Returns the length of a collection",
          function: {__MODULE__, :length}
        },
        "first" => %{
          description: "Returns the first element of a collection",
          function: {__MODULE__, :first}
        },
        "last" => %{
          description: "Returns the last element of a collection",
          function: {__MODULE__, :last}
        },
        "join" => %{
          description: "Joins collection elements with a separator",
          function: {__MODULE__, :join}
        },
        "sort" => %{
          description: "Sorts a collection",
          function: {__MODULE__, :sort}
        },
        "reverse" => %{
          description: "Reverses a collection",
          function: {__MODULE__, :reverse}
        },
        "uniq" => %{
          description: "Returns unique elements from collection",
          function: {__MODULE__, :uniq}
        },
        "slice" => %{
          description: "Returns a slice of the collection",
          function: {__MODULE__, :slice}
        },
        "contains" => %{
          description: "Checks if collection contains a value",
          function: {__MODULE__, :contains}
        },
        "compact" => %{
          description: "Removes nil values from collection",
          function: {__MODULE__, :compact}
        },
        "flatten" => %{
          description: "Flattens nested lists",
          function: {__MODULE__, :flatten}
        },
        "sum" => %{
          description: "Sums numeric values in collection",
          function: {__MODULE__, :sum}
        },
        "keys" => %{
          description: "Returns keys from a map",
          function: {__MODULE__, :keys}
        },
        "values" => %{
          description: "Returns values from a map",
          function: {__MODULE__, :values}
        },
        "group_by" => %{
          description: "Groups collection items by field value",
          function: {__MODULE__, :group_by}
        },
        "map" => %{
          description: "Extracts field values from maps, filtering out nils",
          function: {__MODULE__, :map}
        },
        "filter" => %{
          description: "Filters collection by field value",
          function: {__MODULE__, :filter}
        },
        "reject" => %{
          description: "Rejects items from collection by field value",
          function: {__MODULE__, :reject}
        },
        "dump" => %{
          description: "Formats data structures for display",
          function: {__MODULE__, :dump}
        }
      }
    }
  end

  # Implementation functions (copying from existing CollectionFilters)

  @doc """
  Returns the length of a collection or string.
  """
  def length(value, _args) do
    case value do
      list when is_list(list) -> {:ok, Kernel.length(list)}
      map when is_map(map) -> {:ok, map_size(map)}
      str when is_binary(str) -> {:ok, String.length(str)}
      _ -> {:error, "length can only be applied to collections or strings"}
    end
  end

  @doc """
  Returns the first element of a collection.
  """
  def first(value, _args) do
    case value do
      [] -> {:ok, nil}
      [head | _] -> {:ok, head}
      str when is_binary(str) and str != "" -> {:ok, String.first(str)}
      "" -> {:ok, nil}
      _ -> {:error, "first can only be applied to lists or strings"}
    end
  end

  @doc """
  Returns the last element of a collection.
  """
  def last(value, _args) do
    case value do
      [] -> {:ok, nil}
      list when is_list(list) -> {:ok, List.last(list)}
      str when is_binary(str) and str != "" -> {:ok, String.last(str)}
      "" -> {:ok, nil}
      _ -> {:error, "last can only be applied to lists or strings"}
    end
  end

  @doc """
  Joins elements of a list with a separator.
  """
  def join(value, args) do
    case {value, args} do
      {list, [separator]} when is_list(list) ->
        result =
          list
          |> Enum.map(&to_string/1)
          |> Enum.join(separator)

        {:ok, result}

      {list, []} when is_list(list) ->
        result =
          list
          |> Enum.map(&to_string/1)
          |> Enum.join("")

        {:ok, result}

      _ ->
        {:error, "join can only be applied to lists"}
    end
  end

  @doc """
  Sorts a collection.
  """
  def sort(value, _args) do
    case value do
      list when is_list(list) -> {:ok, Enum.sort(list)}
      str when is_binary(str) -> {:ok, str |> String.graphemes() |> Enum.sort() |> Enum.join()}
      _ -> {:error, "sort can only be applied to lists or strings"}
    end
  end

  @doc """
  Reverses a collection.
  """
  def reverse(value, _args) do
    case value do
      list when is_list(list) -> {:ok, Enum.reverse(list)}
      str when is_binary(str) -> {:ok, String.reverse(str)}
      _ -> {:error, "reverse can only be applied to lists or strings"}
    end
  end

  @doc """
  Returns unique elements from a list.
  """
  def uniq(value, _args) do
    case value do
      list when is_list(list) -> {:ok, Enum.uniq(list)}
      _ -> {:error, "uniq can only be applied to lists"}
    end
  end

  @doc """
  Returns a slice of a list or string.
  """
  def slice(value, args) do
    case {value, args} do
      {list, [start]} when is_list(list) and is_integer(start) ->
        {:ok, Enum.drop(list, start)}

      {list, [start, length]} when is_list(list) and is_integer(start) and is_integer(length) ->
        {:ok, Enum.slice(list, start, length)}

      {str, [start]} when is_binary(str) and is_integer(start) ->
        {:ok, String.slice(str, start..-1)}

      {str, [start, length]} when is_binary(str) and is_integer(start) and is_integer(length) ->
        {:ok, String.slice(str, start, length)}

      _ ->
        {:error, "slice requires start index and optional length"}
    end
  end

  @doc """
  Checks if a collection contains a specific value.
  """
  def contains(value, args) do
    case {value, args} do
      {list, [search_value]} when is_list(list) ->
        {:ok, Enum.member?(list, search_value)}

      {str, [search_value]} when is_binary(str) ->
        search_str = to_string(search_value)
        {:ok, String.contains?(str, search_str)}

      {map, [key]} when is_map(map) ->
        {:ok, Map.has_key?(map, key)}

      _ ->
        {:error, "contains requires a value to search for"}
    end
  end

  @doc """
  Removes nil values from a list.
  """
  def compact(value, _args) do
    case value do
      list when is_list(list) -> {:ok, Enum.reject(list, &is_nil/1)}
      _ -> {:error, "compact can only be applied to lists"}
    end
  end

  @doc """
  Flattens nested lists into a single list.
  """
  def flatten(value, _args) do
    case value do
      list when is_list(list) -> {:ok, List.flatten(list)}
      _ -> {:error, "flatten can only be applied to lists"}
    end
  end

  @doc """
  Sums numeric values in a list.
  """
  def sum(value, _args) do
    case value do
      list when is_list(list) ->
        result =
          Enum.reduce(list, 0, fn
            x, acc when is_number(x) -> acc + x
            # Skip non-numeric values
            _, acc -> acc
          end)

        {:ok, result}

      _ ->
        {:error, "sum can only be applied to lists"}
    end
  end

  @doc """
  Returns the keys of a map as a list.
  """
  def keys(value, _args) do
    case value do
      map when is_map(map) -> {:ok, Map.keys(map)}
      _ -> {:error, "keys can only be applied to maps"}
    end
  end

  @doc """
  Returns the values of a map as a list.
  """
  def values(value, _args) do
    case value do
      map when is_map(map) -> {:ok, Map.values(map)}
      _ -> {:error, "values can only be applied to maps"}
    end
  end

  @doc """
  Groups a list of maps by a specified field.
  """
  def group_by(value, args) do
    case {value, args} do
      {list, [key_field]} when is_list(list) ->
        result =
          list
          |> Enum.filter(&is_map/1)
          |> Enum.group_by(fn item -> Map.get(item, key_field) end)
          |> Enum.into(%{})

        {:ok, result}

      _ ->
        {:error, "group_by requires a key field"}
    end
  end

  @doc """
  Extracts field values from a list of maps, filtering out nil values.
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
  """
  def dump(value, _args) do
    {:ok, inspect(value)}
  end
end
