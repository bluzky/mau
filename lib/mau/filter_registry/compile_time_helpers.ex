defmodule Mau.FilterRegistry.CompileTimeHelpers do
  @moduledoc false

  def build_filter_map(modules) do
    normalize_name = fn
      name when is_atom(name) -> Atom.to_string(name)
      name when is_binary(name) -> name
    end

    load_module_filters = fn module, acc ->
      try do
        if Code.ensure_loaded?(module) and function_exported?(module, :spec, 0) do
          spec = module.spec()

          spec.filters
          |> Enum.reduce(acc, fn {name, filter_spec}, map_acc ->
            normalized_name = normalize_name.(name)
            Map.put(map_acc, normalized_name, filter_spec.function)
          end)
        else
          acc
        end
      rescue
        _ ->
          acc
      end
    end

    modules
    |> Enum.reduce(%{}, load_module_filters)
  end
end