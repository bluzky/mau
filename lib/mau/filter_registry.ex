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
    upper_case: &Mau.Filters.StringFilters.upper_case/2,
    lower_case: &Mau.Filters.StringFilters.lower_case/2,
    capitalize: &Mau.Filters.StringFilters.capitalize/2,
    truncate: &Mau.Filters.StringFilters.truncate/2,
    default: &Mau.Filters.StringFilters.default/2,
    
    # Number filters
    round: &Mau.Filters.NumberFilters.round/2,
    format_currency: &Mau.Filters.NumberFilters.format_currency/2,
    
    # Collection filters
    length: &Mau.Filters.CollectionFilters.length/2,
    first: &Mau.Filters.CollectionFilters.first/2,
    last: &Mau.Filters.CollectionFilters.last/2,
    join: &Mau.Filters.CollectionFilters.join/2,
    sort: &Mau.Filters.CollectionFilters.sort/2,
    reverse: &Mau.Filters.CollectionFilters.reverse/2,
    uniq: &Mau.Filters.CollectionFilters.uniq/2,
    
    # Math filters
    abs: &Mau.Filters.MathFilters.abs/2,
    ceil: &Mau.Filters.MathFilters.ceil/2,
    floor: &Mau.Filters.MathFilters.floor/2,
    max: &Mau.Filters.MathFilters.max/2,
    min: &Mau.Filters.MathFilters.min/2,
    power: &Mau.Filters.MathFilters.power/2,
    sqrt: &Mau.Filters.MathFilters.sqrt/2,
    mod: &Mau.Filters.MathFilters.mod/2,
    clamp: &Mau.Filters.MathFilters.clamp/2
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
  def get(name) do
    normalized_name = normalize_name(name)
    
    case Map.get(@built_in_filters, normalized_name) do
      nil -> {:error, :not_found}
      function -> {:ok, function}
    end
  end

  @doc """
  Lists all registered filter names.
  
  ## Examples
  
      iex> Mau.FilterRegistry.list()
      [:abs, :capitalize, :ceil, :clamp, :default, :first, :floor, :format_currency, :join, :last, :length, :lower_case, :max, :min, :mod, :power, :reverse, :round, :sort, :sqrt, :truncate, :uniq, :upper_case]
  """
  @spec list() :: [atom()]
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
          result = filter_function.(value, args)
          {:ok, result}
        rescue
          error ->
            {:error, {:filter_error, error}}
        end
      
      {:error, :not_found} ->
        {:error, :filter_not_found}
    end
  end

  # Private functions

  defp normalize_name(name) when is_binary(name), do: String.to_atom(name)
  defp normalize_name(name) when is_atom(name), do: name
end