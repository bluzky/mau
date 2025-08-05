defmodule Mau.FilterRegistry do
  @moduledoc """
  Static registry for template filters with compile-time filter storage.
  
  The filter registry manages filter functions that can be applied to values in templates
  using either pipe syntax (`{{ value | filter }}`) or function call syntax (`{{ filter(value) }}`).
  """

  @type filter_function :: (any(), list() -> any())
  @type filter_name :: atom() | String.t()

  # Built-in filters stored as module attribute at compile time
  @built_in_filters %{
    # String filters
    "upper_case" => &Mau.Filters.StringFilters.upper_case/2,
    "lower_case" => &Mau.Filters.StringFilters.lower_case/2,
    "capitalize" => &Mau.Filters.StringFilters.capitalize/2,
    "truncate" => &Mau.Filters.StringFilters.truncate/2,
    "default" => &Mau.Filters.StringFilters.default/2,
    "strip" => &Mau.Filters.StringFilters.strip/2,
    
    # Number filters
    "round" => &Mau.Filters.NumberFilters.round/2,
    "format_currency" => &Mau.Filters.NumberFilters.format_currency/2,
    
    # Collection filters
    "length" => &Mau.Filters.CollectionFilters.length/2,
    "first" => &Mau.Filters.CollectionFilters.first/2,
    "last" => &Mau.Filters.CollectionFilters.last/2,
    "join" => &Mau.Filters.CollectionFilters.join/2,
    "sort" => &Mau.Filters.CollectionFilters.sort/2,
    "reverse" => &Mau.Filters.CollectionFilters.reverse/2,
    "uniq" => &Mau.Filters.CollectionFilters.uniq/2,
    "slice" => &Mau.Filters.CollectionFilters.slice/2,
    "contains" => &Mau.Filters.CollectionFilters.contains/2,
    "compact" => &Mau.Filters.CollectionFilters.compact/2,
    "flatten" => &Mau.Filters.CollectionFilters.flatten/2,
    "sum" => &Mau.Filters.CollectionFilters.sum/2,
    "keys" => &Mau.Filters.CollectionFilters.keys/2,
    "values" => &Mau.Filters.CollectionFilters.values/2,
    "group_by" => &Mau.Filters.CollectionFilters.group_by/2,
    "map" => &Mau.Filters.CollectionFilters.map/2,
    "filter" => &Mau.Filters.CollectionFilters.filter/2,
    "reject" => &Mau.Filters.CollectionFilters.reject/2,
    "dump" => &Mau.Filters.CollectionFilters.dump/2,
    
    # Math filters
    "abs" => &Mau.Filters.MathFilters.abs/2,
    "ceil" => &Mau.Filters.MathFilters.ceil/2,
    "floor" => &Mau.Filters.MathFilters.floor/2,
    "max" => &Mau.Filters.MathFilters.max/2,
    "min" => &Mau.Filters.MathFilters.min/2,
    "power" => &Mau.Filters.MathFilters.power/2,
    "sqrt" => &Mau.Filters.MathFilters.sqrt/2,
    "mod" => &Mau.Filters.MathFilters.mod/2,
    "clamp" => &Mau.Filters.MathFilters.clamp/2
  }

  @doc """
  Gets a filter function by name.
  
  ## Examples
  
      iex> {:ok, func} = Mau.FilterRegistry.get(:upper_case)
      iex> is_function(func, 2)
      true
      
      iex> Mau.FilterRegistry.get(:unknown_filter)
      {:error, :not_found}
  """
  @spec get(filter_name()) :: {:ok, filter_function()} | {:error, :not_found}
  def get(name) when is_binary(name) do
    case Map.get(@built_in_filters, name) do
      nil -> {:error, :not_found}
      function -> {:ok, function}
    end
  end
  
  def get(name) when is_atom(name) do
    get(Atom.to_string(name))
  end

  @doc """
  Lists all registered filter names.
  
  ## Examples
  
      iex> Mau.FilterRegistry.list()
      ["abs", "capitalize", "ceil", "clamp", "compact", "contains", "default", "dump", "filter", "first", "flatten", "floor", "format_currency", "group_by", "join", "keys", "last", "length", "lower_case", "map", "max", "min", "mod", "power", "reject", "reverse", "round", "slice", "sort", "sqrt", "strip", "sum", "truncate", "uniq", "upper_case", "values"]
  """
  @spec list() :: [String.t()]
  def list do
    @built_in_filters
    |> Map.keys()
    |> Enum.sort()
  end

  @doc """
  Applies a filter to a value with the given arguments.
  
  ## Examples
  
      iex> Mau.FilterRegistry.apply(:upper_case, "hello", [])
      {:ok, "HELLO"}
      
      iex> Mau.FilterRegistry.apply(:truncate, "hello world", [5])
      {:ok, "hello"}
      
      iex> Mau.FilterRegistry.apply(:unknown, "value", [])
      {:error, :filter_not_found}
  """
  @spec apply(filter_name(), any(), list()) :: {:ok, any()} | {:error, :filter_not_found | :filter_error}
  def apply(name, value, args \\ []) do
    case get(name) do
      {:ok, filter_function} ->
        try do
          case filter_function.(value, args) do
            {:ok, result} -> {:ok, result}
            {:error, reason} -> {:error, {:filter_error, reason}}
            # Support legacy filters that return direct values (for backward compatibility)
            result -> {:ok, result}
          end
        rescue
          error ->
            {:error, {:filter_error, error}}
        end
      
      {:error, :not_found} ->
        {:error, :filter_not_found}
    end
  end

end