defmodule Mau.FilterRegistry do
  @moduledoc """
  Dynamic filter registry that loads filters from module specs.
  
  This registry automatically discovers filters by calling spec() functions
  on filter modules, providing better organization and discoverability.
  """

  @type filter_function :: (any(), list() -> any())
  @type filter_name :: atom() | String.t()

  # Filter modules to load
  @filter_modules [
    Mau.Filters.String,
    Mau.Filters.Collection,
    Mau.Filters.Math,
    Mau.Filters.Number
  ]

  # Build filter name registry at compile time
  @filter_names @filter_modules
               |> Enum.flat_map(fn module ->
                 spec = module.spec()
                 Map.keys(spec.filters)
               end)

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
    # Find the filter function by searching through modules
    result = 
      @filter_modules
      |> Enum.find_value(fn module ->
        spec = module.spec()
        case Map.get(spec.filters, name) do
          nil -> nil
          filter_spec -> filter_spec.function
        end
      end)

    case result do
      nil -> {:error, :not_found}
      function -> {:ok, function}
    end
  end

  def get(name) when is_atom(name) do
    get(Atom.to_string(name))
  end

  @doc """
  Lists all registered filter names.
  """
  @spec list() :: [String.t()]
  def list do
    @filter_names
    |> Enum.sort()
  end

  @doc """
  Lists filters organized by category.
  """
  @spec list_by_category() :: %{atom() => [%{name: String.t(), description: String.t()}]}
  def list_by_category do
    @filter_modules
    |> Enum.reduce(%{}, fn module, acc ->
      spec = module.spec()
      
      filters = 
        spec.filters
        |> Enum.map(fn {name, filter_spec} ->
          %{name: name, description: filter_spec.description}
        end)
      
      Map.put(acc, spec.category, filters)
    end)
  end

  @doc """
  Gets detailed information about a filter.
  """
  @spec get_info(filter_name()) :: {:ok, map()} | {:error, :not_found}
  def get_info(name) when is_binary(name) do
    result = 
      @filter_modules
      |> Enum.find_value(fn module ->
        spec = module.spec()
        case Map.get(spec.filters, name) do
          nil -> nil
          filter_spec -> 
            %{
              name: name,
              category: spec.category,
              description: filter_spec.description
            }
        end
      end)

    case result do
      nil -> {:error, :not_found}
      info -> {:ok, info}
    end
  end

  def get_info(name) when is_atom(name) do
    get_info(Atom.to_string(name))
  end

  @doc """
  Applies a filter to a value with the given arguments.
  """
  @spec apply(filter_name(), any(), list()) ::
          {:ok, any()} | {:error, :filter_not_found | :filter_error}
  def apply(name, value, args \\ []) do
    case get(name) do
      {:ok, filter_function} ->
        try do
          case filter_function.(value, args) do
            {:ok, result} -> {:ok, result}
            {:error, reason} -> {:error, {:filter_error, reason}}
            # Support legacy filters that return direct values
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

  @doc """
  Returns all available categories.
  """
  @spec categories() :: [atom()]
  def categories do
    @filter_modules
    |> Enum.map(fn module -> module.spec().category end)
    |> Enum.uniq()
    |> Enum.sort()
  end
end