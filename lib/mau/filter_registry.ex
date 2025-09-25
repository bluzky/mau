defmodule Mau.FilterRegistry do
  @moduledoc """
  Dynamic filter registry that loads filters from module specs.

  This registry automatically discovers filters by calling spec() functions
  on filter modules, providing better organization and discoverability.

  ## Configuration

  By default, uses compile-time module attributes for maximum performance.
  Enable runtime mode for user-defined filters:

      config :mau, :enable_runtime_filters, true

  """

  @type filter_mfa :: {module(), atom()}
  @type filter_name :: atom() | String.t()

  # Built-in filter modules - these are guaranteed to exist
  @built_in_filters [
    Mau.Filters.String,
    Mau.Filters.Collection,
    Mau.Filters.Math
  ]

  # True compile-time filter map
  @compile_time_filters Mau.FilterRegistry.CompileTimeHelpers.build_filter_map(@built_in_filters)

  use GenServer

  @runtime_enabled Application.compile_env(:mau, :enable_runtime_filters, false)

  @doc """
  Starts the filter registry GenServer.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Initializes the registry by loading all filters into state.
  """
  def init([]) do
    filter_map = load_all_filters()
    {:ok, filter_map}
  end

  @doc """
  Gets a filter function by name.

  ## Examples

      iex> {:ok, {module, function}} = Mau.FilterRegistry.get(:upper_case)
      iex> is_atom(module) and is_atom(function)
      true

      iex> Mau.FilterRegistry.get(:unknown_filter)
      {:error, :not_found}
  """
  @spec get(filter_name()) :: {:ok, filter_mfa()} | {:error, :not_found}
  def get(name) do
    normalized_name = normalize_name(name)

    if @runtime_enabled do
      GenServer.call(__MODULE__, {:get, normalized_name})
    else
      case Map.get(@compile_time_filters, normalized_name) do
        nil -> {:error, :not_found}
        mfa -> {:ok, mfa}
      end
    end
  end

  @doc """
  Applies a filter to a value with the given arguments.
  """
  @spec apply(filter_name(), any(), list()) ::
          {:ok, any()} | {:error, :filter_not_found | {:filter_error, any()}}
  def apply(name, value, args \\ []) do
    case get(name) do
      {:ok, {module, function}} ->
        try do
          case Kernel.apply(module, function, [value, args]) do
            {:ok, result} -> {:ok, result}
            {:error, reason} -> {:error, {:filter_error, reason}}
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

  # GenServer callbacks
  def handle_call({:get, name}, _from, filter_map) do
    case Map.get(filter_map, name) do
      nil -> {:reply, {:error, :not_found}, filter_map}
      mfa -> {:reply, {:ok, mfa}, filter_map}
    end
  end

  # Private functions

  defp normalize_name(name) when is_atom(name), do: Atom.to_string(name)
  defp normalize_name(name) when is_binary(name), do: name


  defp load_all_filters do
    user_defined_filters = Application.get_env(:mau, :filters, [])
    all_modules = @built_in_filters ++ user_defined_filters

    all_modules
    |> Enum.reduce(%{}, &load_module_filters/2)
  end

  defp load_module_filters(module, acc) do
    try do
      if Code.ensure_loaded?(module) and function_exported?(module, :spec, 0) do
        spec = module.spec()

        spec.filters
        |> Enum.reduce(acc, fn {name, filter_spec}, map_acc ->
          normalized_name = normalize_name(name)
          Map.put(map_acc, normalized_name, filter_spec.function)
        end)
      else
        acc
      end
    rescue
      _ ->
        # Skip modules that fail to load or don't have proper spec
        acc
    end
  end
end
