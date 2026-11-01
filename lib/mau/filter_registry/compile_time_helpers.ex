defmodule Mau.FilterRegistry.CompileTimeHelpers do
  @moduledoc false

  def build_filter_map(modules) do
    normalize_name = fn
      name when is_atom(name) -> Atom.to_string(name)
      name when is_binary(name) -> name
    end

    load_module_filters = fn module, acc ->
      # Waits for modules still being compiled, and raises instead of
      # silently building a registry with missing filters.
      Code.ensure_compiled!(module)

      module.spec().filters
      |> Enum.reduce(acc, fn {name, filter_spec}, map_acc ->
        normalized_name = normalize_name.(name)
        Map.put(map_acc, normalized_name, filter_spec.function)
      end)
    end

    modules
    |> Enum.reduce(%{}, load_module_filters)
  end
end
