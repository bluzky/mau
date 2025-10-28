defmodule Mau.MapDirectives do
  @moduledoc """
  Handles special directives for render_map functionality.

  Directives are special map keys that start with "_." and provide
  advanced map transformation capabilities with lodash-style naming.

  ## Supported Directives

  - `_.forEach` - Iterate over a collection and apply a template to each item
  - `_.merge` - Merge multiple maps together
  - `_.if` - Conditional rendering based on a boolean condition
  - `_.filter` - Filter items in a collection based on a condition
  - `_.map` - Extract specific fields from items in a collection (similar to lodash.map)
  - `_.pick` - Extract specific keys from a map (similar to lodash.pick)

  ## Easy Extension

  To add a new directive:
  1. Add a pattern match in `match_directive/1`
  2. Implement the corresponding `apply_*_directive/3` function
  """

  
  @doc """
  Checks if a map contains a directive and returns the directive type and arguments.

  ## Examples

      iex> Mau.MapDirectives.match_directive(%{"_.forEach" => ["collection", "template"]})
      {:for_each, ["collection", "template"]}

      iex> Mau.MapDirectives.match_directive(%{"_.merge" => [%{}, %{}]})
      {:merge, [%{}, %{}]}

      iex> Mau.MapDirectives.match_directive(%{"name" => "John"})
      :none
  """
  # Only match if args is a list, otherwise treat as regular map key
  def match_directive(%{"_.forEach" => args}) when is_list(args) and length(args) > 0, do: {:for_each, args}
  def match_directive(%{"_.merge" => args}) when is_list(args) and length(args) > 0, do: {:merge, args}
  def match_directive(%{"_.if" => args}) when is_list(args) and length(args) in [2, 3], do: {:if, args}
  def match_directive(%{"_.filter" => args}) when is_list(args) and length(args) == 2, do: {:filter, args}
  def match_directive(%{"_.map" => args}) when is_list(args) and length(args) == 2, do: {:map, args}
  def match_directive(%{"_.pick" => args}) when is_list(args) and length(args) == 2, do: {:pick, args}

  # No directive matched
  def match_directive(_map), do: :none

    @doc """
  Applies a directive to a map with the given context and rendering function.

  ## Parameters

  - `{:directive_name, args}` - The directive tuple with its arguments
  - `context` - The context map containing variables and data
  - `opts` - Options for rendering
  - `render_fn` - Function to recursively render templates (arity 3)

  ## Supported Directives

  - `_.forEach` - Iterate over a collection and apply a template to each item
  - `_.merge` - Merge multiple maps together
  - `_.if` - Conditional rendering based on a boolean condition
  - `_.filter` - Filter items in a collection based on a condition
  - `_.map` - Extract specific fields from items in a collection (similar to lodash.map)
  - `_.pick` - Extract specific keys from a map (similar to lodash.pick)

  ## Examples

      iex> Mau.MapDirectives.apply_directive({:for_each, ["{{$items}}", %{name: "{{$self.name}}"}]}, %{}, [], fn template, context, _opts -> template end)
      []

      iex> Mau.MapDirectives.apply_directive({:merge, [%{a: 1}, %{b: 2}]}, %{}, [], fn template, _context, _opts -> template end)
      %{a: 1, b: 2}

  """
  def apply_directive({:for_each, [collection_template, item_template]}, context, opts, render_fn) do
    # Render the collection template to get the actual collection
    collection = render_fn.(collection_template, context, opts)

    # Ensure we have a list to iterate over
    items = ensure_list(collection)

    # Map over each item with $self context
    Enum.map(items, fn item ->
      # Create new context with $self pointing to current item
      item_context = Map.put(context, "$self", item)
      # Recursively render the item template
      render_fn.(item_template, item_context, opts)
    end)
  end

  def apply_directive({:for_each, _invalid_args}, _context, _opts, _render_fn) do
    # Invalid arguments - return empty list
    []
  end

  def apply_directive({:merge, templates}, context, opts, render_fn) when is_list(templates) do
    templates
    |> Enum.map(fn template ->
      # Render each template
      result = render_fn.(template, context, opts)
      # Ensure result is a map, otherwise use empty map
      if is_map(result), do: result, else: %{}
    end)
    |> Enum.reduce(%{}, fn map, acc ->
      # Merge maps, later values override earlier ones
      Map.merge(acc, map)
    end)
  end

  def apply_directive({:merge, _invalid_args}, _context, _opts, _render_fn) do
    # Invalid arguments - return empty map
    %{}
  end

    def apply_directive({:if, [condition_template, true_template]}, context, opts, render_fn) do
    # Render the condition to get a boolean value
    condition_result = render_fn.(condition_template, context, opts)
    condition = truthy?(condition_result)

    if condition do
      render_fn.(true_template, context, opts)
    else
      nil
    end
  end

  def apply_directive({:if, [condition_template, true_template, false_template]}, context, opts, render_fn) do
    # Render the condition to get a boolean value
    condition_result = render_fn.(condition_template, context, opts)
    condition = truthy?(condition_result)

    if condition do
      render_fn.(true_template, context, opts)
    else
      render_fn.(false_template, context, opts)
    end
  end

  def apply_directive({:if, _invalid_args}, _context, _opts, _render_fn) do
    # Invalid arguments - return nil
    nil
  end

    def apply_directive({:filter, [collection_template, condition_template]}, context, opts, render_fn) do
    # Render the collection template to get the actual collection
    collection = render_fn.(collection_template, context, opts)

    # Ensure we have a list to filter
    items = ensure_list(collection)

    # Filter items based on condition
    Enum.filter(items, fn item ->
      # Create new context with $self pointing to current item
      item_context = Map.put(context, "$self", item)
      # Render the condition template
      condition_result = render_fn.(condition_template, item_context, opts)
      # Check if condition is truthy
      truthy?(condition_result)
    end)
  end

  def apply_directive({:filter, _invalid_args}, _context, _opts, _render_fn) do
    # Invalid arguments - return empty list
    []
  end

    def apply_directive({:map, [collection_template, field_name]}, context, opts, render_fn) when is_binary(field_name) do
    # Render the collection template to get the actual collection
    collection = render_fn.(collection_template, context, opts)

    # Ensure we have a list to pluck from
    items = ensure_list(collection)

    # Extract the field from each item
    Enum.map(items, fn item ->
      if is_map(item) do
        Map.get(item, field_name)
      else
        nil
      end
    end)
  end

  def apply_directive({:map, _invalid_args}, _context, _opts, _render_fn) do
    # Invalid arguments - return empty list
    []
  end

    def apply_directive({:pick, [map_template, keys]}, context, opts, render_fn) when is_list(keys) do
    # Render the map template to get the actual map
    map_result = render_fn.(map_template, context, opts)

    # Ensure we have a map to take from
    if is_map(map_result) do
      # Take only the specified keys
      Map.take(map_result, keys)
    else
      %{}
    end
  end

  def apply_directive({:pick, _invalid_args}, _context, _opts, _render_fn) do
    # Invalid arguments - return empty map
    %{}
  end

  # Helper to check if a value is truthy
  defp truthy?(nil), do: false
  defp truthy?(false), do: false
  defp truthy?([]), do: false
  defp truthy?({}), do: false
  defp truthy?(""), do: false
  defp truthy?(_), do: true

  # Helper to ensure value is a list
  defp ensure_list(value) when is_list(value), do: value
  defp ensure_list(nil), do: []
  defp ensure_list(_), do: []
end
