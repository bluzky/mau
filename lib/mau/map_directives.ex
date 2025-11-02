defmodule Mau.MapDirectives do
  @moduledoc """
  Handles special directives for render_map functionality.

  Directives are special map keys that start with "#" and provide
  advanced map transformation capabilities.

  ## Supported Directives

  - `#pipe` - Thread data through a series of transformations (like Elixir's |> operator)
  - `#map` - Iterate over a collection and apply a template to each item
  - `#flat_map` - Map over a collection and flatten the results into a single list
  - `#merge` - Merge multiple maps together
  - `#if` - Conditional rendering based on a boolean condition
  - `#filter` - Filter items in a collection based on a condition
  - `#pick` - Extract specific keys from a map (similar to Map.pick)

  ## Easy Extension

  To add a new directive:
  1. Add a pattern match in `match_directive/1`
  2. Implement the corresponding `apply_*_directive/3` function
  """

  
  @doc """
  Checks if a map contains a directive and returns the directive type and arguments.

  ## Examples

      iex> Mau.MapDirectives.match_directive(%{"#map" => ["collection", "template"]})
      {:map, ["collection", "template"]}

      iex> Mau.MapDirectives.match_directive(%{"#merge" => [%{}, %{}]})
      {:merge, [%{}, %{}]}

      iex> Mau.MapDirectives.match_directive(%{"name" => "John"})
      :none
  """
  # Only match if args is a list, otherwise treat as regular map key
  def match_directive(%{"#map" => args}) when is_list(args) and length(args) > 0, do: {:map, args}
  def match_directive(%{"#flat_map" => args}) when is_list(args) and length(args) == 2, do: {:flat_map, args}
  def match_directive(%{"#merge" => args}) when is_list(args) and length(args) > 0, do: {:merge, args}
  def match_directive(%{"#if" => args}) when is_list(args) and length(args) in [2, 3], do: {:if, args}
  def match_directive(%{"#filter" => args}) when is_list(args) and length(args) == 2, do: {:filter, args}
  def match_directive(%{"#pick" => args}) when is_list(args) and length(args) == 2, do: {:pick, args}

  def match_directive(%{"#pipe" => args}) when is_list(args) and length(args) == 2 do
    [_initial, directives] = args
    if is_list(directives), do: {:pipe, args}, else: :none
  end

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

  - `#pipe` - Thread data through a series of transformations (like Elixir's |> operator)
  - `#map` - Iterate over a collection and apply a template to each item
  - `#flat_map` - Map over a collection and flatten the results into a single list
  - `#merge` - Merge multiple maps together
  - `#if` - Conditional rendering based on a boolean condition
  - `#filter` - Filter items in a collection based on a condition
  - `#pick` - Extract specific keys from a map (similar to Map.pick)

  ## Examples

      iex> Mau.MapDirectives.apply_directive({:map, ["{{$items}}", %{name: "{{$self.name}}"}]}, %{}, [], fn template, _context, _opts -> template end)
      []

      iex> Mau.MapDirectives.apply_directive({:merge, [%{a: 1}, %{b: 2}]}, %{}, [], fn template, _context, _opts -> template end)
      %{a: 1, b: 2}

  """
  def apply_directive({:map, [collection_template, item_template]}, context, opts, render_fn) do
    # Render the collection template to get the actual collection
    collection = render_fn.(collection_template, context, opts)

    # Ensure we have a list to iterate over
    items = ensure_list(collection)

    # Get parent loop reference if it exists
    parent_loop = context["$loop"]

    # Map over each item with $loop context
    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      # Create new $loop structure with parent reference
      loop_context = %{
        "item" => item,
        "index" => index,
        "parentloop" => parent_loop
      }

      # Create new context with $loop pointing to current loop structure
      item_context = Map.put(context, "$loop", loop_context)
      # Recursively render the item template
      render_fn.(item_template, item_context, opts)
    end)
  end

  def apply_directive({:map, _invalid_args}, _context, _opts, _render_fn) do
    # Invalid arguments - return empty list
    []
  end

  def apply_directive({:flat_map, [collection_template, item_template]}, context, opts, render_fn) do
    # Render the collection template to get the actual collection
    collection = render_fn.(collection_template, context, opts)

    # Ensure we have a list to iterate over
    items = ensure_list(collection)

    # Get parent loop reference if it exists
    parent_loop = context["$loop"]

    # Map over each item with $loop context, then flatten
    items
    |> Enum.with_index()
    |> Enum.flat_map(fn {item, index} ->
      # Create new $loop structure with parent reference
      loop_context = %{
        "item" => item,
        "index" => index,
        "parentloop" => parent_loop
      }

      # Create new context with $loop pointing to current loop structure
      item_context = Map.put(context, "$loop", loop_context)
      # Recursively render the item template
      result = render_fn.(item_template, item_context, opts)
      # Ensure result is a list for flattening
      ensure_list(result)
    end)
  end

  def apply_directive({:flat_map, _invalid_args}, _context, _opts, _render_fn) do
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

    # Get parent loop reference if it exists
    parent_loop = context["$loop"]

    # Filter items based on condition
    items
    |> Enum.with_index()
    |> Enum.filter(fn {item, index} ->
      # Create new $loop structure with parent reference
      loop_context = %{
        "item" => item,
        "index" => index,
        "parentloop" => parent_loop
      }

      # Create new context with $loop pointing to current loop structure
      item_context = Map.put(context, "$loop", loop_context)
      # Render the condition template
      condition_result = render_fn.(condition_template, item_context, opts)
      # Check if condition is truthy
      truthy?(condition_result)
    end)
    |> Enum.map(fn {item, _index} -> item end)
  end

  def apply_directive({:filter, _invalid_args}, _context, _opts, _render_fn) do
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

  def apply_directive({:pipe, [initial_template, directives]}, context, opts, render_fn) do
    # Render initial value
    initial_value = render_fn.(initial_template, context, opts)

    # Thread through each directive
    Enum.reduce(directives, initial_value, fn directive_map, acc ->
      # Inject accumulated value as first argument
      transformed_directive = inject_piped_value(directive_map, acc)

      # Provide $self in context for manual access
      self_context = Map.put(context, "$self", acc)

      # Render the transformed directive
      render_fn.(transformed_directive, self_context, opts)
    end)
  end

  def apply_directive({:pipe, _invalid_args}, _context, _opts, _render_fn) do
    # Invalid arguments - return nil
    nil
  end

  # Helper to inject piped value as first argument to directives
  defp inject_piped_value(directive_map, piped_value) when is_map(directive_map) do
    directive_map
    |> Enum.map(fn {key, args} ->
      if String.starts_with?(key, "#") do
        {key, [piped_value, args]}
      else
        {key, args}
      end
    end)
    |> Map.new()
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
