defmodule Mau.FilterRegistry do
  @moduledoc """
  Dynamic filter registry that loads filters from module specs.

  This registry automatically discovers filters by calling spec() functions
  on filter modules, providing better organization and discoverability.
  """

  @type filter_mfa :: {module(), atom()}
  @type filter_name :: atom() | String.t()

  # Filter modules to load
  @filter_modules [
    Mau.Filters.String,
    Mau.Filters.Collection,
    Mau.Filters.Math,
    Mau.Filters.Number
  ]

  # Build compile-time filter name to {module, function} mapping for fast runtime lookups
  @filter_function_map @filter_modules
                       |> Enum.reduce(%{}, fn module, acc ->
                         spec = module.spec()

                         filter_functions =
                           spec.filters
                           |> Enum.map(fn {name, filter_spec} ->
                             {name, filter_spec.function}
                           end)
                           |> Map.new()

                         Map.merge(acc, filter_functions)
                       end)

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
  def get(name) when is_binary(name) do
    case Map.get(@filter_function_map, name) do
      nil -> {:error, :not_found}
      mfa -> {:ok, mfa}
    end
  end

  def get(name) when is_atom(name) do
    get(Atom.to_string(name))
  end

  @doc """
  Applies a filter to a value with the given arguments.
  """
  @spec apply(filter_name(), any(), list()) ::
          {:ok, any()} | {:error, :filter_not_found | :filter_error}
  def apply(name, value, args \\ []) do
    case get(name) do
      {:ok, {module, function}} ->
        try do
          case Kernel.apply(module, function, [value, args]) do
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
end
