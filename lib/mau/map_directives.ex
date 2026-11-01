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
  - `#case` - Pattern matching on values (like Elixir's case)
  - `#cond` - Condition-based branching (like Elixir's cond)
  - `#filter` - Filter items in a collection based on a condition
  - `#pick` - Extract specific keys from a map (similar to Map.pick)

  A directive with invalid arguments is treated as a regular map key, or is an
  error with `strict_mode: true`. A malformed `#case` or `#cond` entry is always
  an error.

  ## Easy Extension

  To add a new directive:
  1. Add it to `@directives`
  2. Add a `valid_args?/2` clause for its arguments
  3. Add an `apply_directive/4` clause
  """

  alias Mau.Budget

  # In match order: when a map has several directives, the first valid one wins
  @directives [
    {"#map", :map, "[collection, template]"},
    {"#flat_map", :flat_map, "[collection, template]"},
    {"#merge", :merge, "at least one template"},
    {"#if", :if, "[condition, then] or [condition, then, else]"},
    {"#case", :case, "[value, patterns] or [value, patterns, default], with patterns a list"},
    {"#cond", :cond, "[conditions], with conditions a list"},
    {"#filter", :filter, "[collection, condition]"},
    {"#pick", :pick, "[map, keys], with keys a list"},
    {"#pipe", :pipe, "[initial, directives], with directives a list"}
  ]

  @doc """
  Checks if a map contains a directive and returns the directive type and arguments.

  ## Examples

      iex> Mau.MapDirectives.match_directive(%{"#map" => ["collection", "template"]})
      {:map, ["collection", "template"]}

      iex> Mau.MapDirectives.match_directive(%{"#merge" => [%{}, %{}]})
      {:merge, [%{}, %{}]}

      iex> Mau.MapDirectives.match_directive(%{"name" => "John"})
      :none

      iex> Mau.MapDirectives.match_directive(%{"#map" => ["collection", "template", "extra"]})
      :none
  """
  def match_directive(map) when is_map(map) do
    Enum.find_value(@directives, :none, fn {key, type, _expected} ->
      case map do
        %{^key => args} -> if valid_args?(type, args), do: {type, args}
        _ -> nil
      end
    end)
  end

  # No directive matched
  def match_directive(_map), do: :none

  @doc """
  Raises `Mau.Error` if a map that matched no directive has a directive key,
  which means its arguments are invalid.

  ## Examples

      iex> Mau.MapDirectives.validate!(%{"name" => "John"})
      :ok
  """
  def validate!(map) when is_map(map) do
    Enum.each(@directives, fn {key, type, _expected} ->
      if is_map_key(map, key), do: raise(invalid_args_error(type))
    end)
  end

  # Only match if args fit the directive, otherwise treat as regular map key
  defp valid_args?(:map, [_collection, _template]), do: true
  defp valid_args?(:flat_map, [_collection, _template]), do: true
  defp valid_args?(:merge, [_template | _rest]), do: true
  defp valid_args?(:if, [_condition, _then]), do: true
  defp valid_args?(:if, [_condition, _then, _else]), do: true
  defp valid_args?(:case, [_value, patterns]), do: is_list(patterns)
  defp valid_args?(:case, [_value, patterns, _default]), do: is_list(patterns)
  defp valid_args?(:cond, [conditions]), do: is_list(conditions)
  defp valid_args?(:filter, [_collection, _condition]), do: true
  defp valid_args?(:pick, [_map, keys]), do: is_list(keys)
  defp valid_args?(:pipe, [_initial, directives]), do: is_list(directives)
  defp valid_args?(_type, _args), do: false

  defp invalid_args_error(type) do
    {key, ^type, expected} = List.keyfind(@directives, type, 1)
    Mau.Error.runtime_error("Invalid arguments for #{key}, expected #{expected}")
  end

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
  - `#case` - Pattern matching on values (like Elixir's case)
  - `#cond` - Condition-based branching (like Elixir's cond)
  - `#filter` - Filter items in a collection based on a condition
  - `#pick` - Extract specific keys from a map (similar to Map.pick)

  Raises `Mau.Error` if the arguments are invalid. `match_directive/1` only
  returns valid ones.

  ## Examples

      iex> Mau.MapDirectives.apply_directive({:map, ["{{$items}}", %{name: "{{$self.name}}"}]}, %{}, [], fn template, _context, _opts -> template end)
      []

      iex> Mau.MapDirectives.apply_directive({:merge, [%{a: 1}, %{b: 2}]}, %{}, [], fn template, _context, _opts -> template end)
      %{a: 1, b: 2}

  """
  def apply_directive({type, args}, context, opts, render_fn) do
    if valid_args?(type, args) do
      apply_valid_directive({type, args}, context, opts, render_fn)
    else
      raise invalid_args_error(type)
    end
  end

  defp apply_valid_directive({:map, [collection_template, item_template]}, context, opts, render_fn) do
    collection_template
    |> loop_items(context, opts, render_fn)
    |> Enum.map(fn {_item, item_context} ->
      render_fn.(item_template, item_context, opts)
    end)
  end

  defp apply_valid_directive({:flat_map, [collection_template, item_template]}, context, opts, render_fn) do
    collection_template
    |> loop_items(context, opts, render_fn)
    |> Enum.flat_map(fn {_item, item_context} ->
      # Ensure result is a list for flattening
      ensure_list(render_fn.(item_template, item_context, opts))
    end)
  end

  defp apply_valid_directive({:merge, templates}, context, opts, render_fn) do
    Enum.reduce(templates, %{}, fn template, acc ->
      result = render_fn.(template, context, opts)
      # Later values override earlier ones, and non-maps are ignored
      if is_map(result), do: Map.merge(acc, result), else: acc
    end)
  end

  defp apply_valid_directive({:if, [condition_template, then_template | else_template]}, context, opts, render_fn) do
    if render_fn.(condition_template, context, opts) do
      render_fn.(then_template, context, opts)
    else
      render_optional(else_template, context, opts, render_fn)
    end
  end

  defp apply_valid_directive({:case, [value_template, patterns | default_template]}, context, opts, render_fn) do
    validate_entries!("#case", "[pattern, template]", patterns)
    value = render_fn.(value_template, context, opts)

    case find_case_match(patterns, value, context, opts, render_fn) do
      {:ok, result} -> result
      nil -> render_optional(default_template, context, opts, render_fn)
    end
  end

  defp apply_valid_directive({:cond, [conditions]}, context, opts, render_fn) do
    validate_entries!("#cond", "[condition, template]", conditions)

    # Find the first condition that evaluates to true
    match_result =
      Enum.find_value(conditions, fn [condition_template, template] ->
        # Wrapped so a branch that renders to false or nil still counts as a match
        if render_fn.(condition_template, context, opts) do
          {:ok, render_fn.(template, context, opts)}
        end
      end)

    case match_result do
      {:ok, result} -> result
      nil -> nil
    end
  end

  defp apply_valid_directive({:filter, [collection_template, condition_template]}, context, opts, render_fn) do
    collection_template
    |> loop_items(context, opts, render_fn)
    |> Enum.filter(fn {_item, item_context} ->
      render_fn.(condition_template, item_context, opts)
    end)
    |> Enum.map(fn {item, _item_context} -> item end)
  end

  defp apply_valid_directive({:pick, [map_template, keys]}, context, opts, render_fn) do
    map_result = render_fn.(map_template, context, opts)

    # Ensure we have a map to take from
    if is_map(map_result), do: Map.take(map_result, keys), else: %{}
  end

  defp apply_valid_directive({:pipe, [initial_template, directives]}, context, opts, render_fn) do
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

  # Checks every entry up front, so a bad one can't hide behind an earlier match
  defp validate_entries!(key, expected, entries) do
    Enum.each(entries, fn
      [_first, _second] ->
        :ok

      entry ->
        raise Mau.Error.runtime_error(
                "Invalid entry in #{key}, expected #{expected}, got #{inspect(entry)}"
              )
    end)
  end

  # Finds the first matching pattern - returns {:ok, result} to distinguish from no match
  defp find_case_match(patterns, value, context, opts, render_fn) do
    Enum.find_value(patterns, fn [pattern, template] ->
      # Render pattern if it's a template string
      pattern_value = if is_binary(pattern), do: render_fn.(pattern, context, opts), else: pattern

      if pattern_value == value do
        {:ok, render_fn.(template, context, opts)}
      end
    end)
  end

  # Renders the optional last argument of #if and #case, which is nil when left out
  defp render_optional([], _context, _opts, _render_fn), do: nil
  defp render_optional([template], context, opts, render_fn), do: render_fn.(template, context, opts)

  # Helper to render a collection into {item, context} pairs, each context with
  # a $loop structure pointing at its parent loop
  defp loop_items(collection_template, context, opts, render_fn) do
    collection = render_fn.(collection_template, context, opts)
    parent_loop = context["$loop"]

    collection
    |> iterable_items(opts)
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      loop_context = %{
        "item" => item,
        "index" => index,
        "parentloop" => parent_loop
      }

      {item, Map.put(context, "$loop", loop_context)}
    end)
  end

  # Helper to inject piped value as first argument to directives. The value is
  # already rendered, so it's wrapped to stop it being rendered again as a template.
  # #cond has no value argument, so it keeps its args and reads $self.
  defp inject_piped_value(directive_map, piped_value) when is_map(directive_map) do
    directive_map
    |> Enum.map(fn {key, args} ->
      if String.starts_with?(key, "#") and key != "#cond" do
        {key, [{:mau_value, piped_value}, args]}
      else
        {key, args}
      end
    end)
    |> Map.new()
  end

  # Helper to get a list of items, spending them against the render's limits
  defp iterable_items(collection, opts) do
    items = ensure_list(collection)

    case Budget.spend_iterations(length(items), opts) do
      :ok -> items
      {:error, error} -> raise error
    end
  end

  # Helper to ensure value is a list
  defp ensure_list(value) when is_list(value), do: value
  defp ensure_list(_), do: []
end
