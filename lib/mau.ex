defmodule Mau do
  @moduledoc """
  Mau template engine for the Prana template language.

  Provides three main functions:
  - `compile/2` - Parse template string into AST
  - `render/3` - Render template string or AST with context
  - `render_map/3` - Recursively render template strings in nested maps with directive support

  ## Map Directives

  The `render_map/3` function supports powerful map transformation directives:

  - `#map` - Iterate over collections and apply templates to each item with index and parent access
  - `#merge` - Combine multiple maps together
  - `#if` - Conditional rendering based on boolean conditions
  - `#filter` - Filter collections based on conditions with index access
  - `#pick` - Extract specific keys from maps

  See `docs/map_directives_reference.md` for comprehensive documentation.
  """

  alias Mau.Parser
  alias Mau.Renderer
  alias Mau.AST.Nodes
  alias Mau.BlockProcessor
  alias Mau.WhitespaceProcessor
  alias Mau.MapDirectives

  @doc """
  Compiles a template string into an AST ready for `render/3`.

  Runs the same parse, whitespace and block stages as rendering a string.

  ## Options
  - `:strict_mode` - boolean, default `false`. When `true`, invalid templates return
    `{:error, error}`. When `false`, they compile to a single text node holding the
    original template string.
  - `:max_template_size` - integer, maximum template size in bytes (default 100,000)

  ## Examples

      iex> Mau.compile("Hello world")
      {:ok, [{:text, ["Hello world"], []}]}
  """
  def compile(template, opts \\ []) when is_binary(template) do
    with {:ok, ast} <- build_ast(template, opts) do
      if opts[:strict_mode] do
        {:ok, ast, []}
      else
        {:ok, ast}
      end
    end
  end

  @doc """
  Renders a template string or AST with the given context.

  ## Options
  - `:preserve_types` - boolean, default `false`. When `true`, preserves data types
    for single-value templates (templates that render to a single expression result).
  - `:strict_mode` - boolean, default `false`. When `true`, invalid templates return
    `{:error, error}`. When `false`, they render as the original template string.
  - `:max_template_size` - integer, maximum template size in bytes (default 100,000)
  - `:max_loop_iterations` - integer, maximum loop iterations (default 10000)

  Errors while rendering a valid template return `{:error, error}` in both modes.

  ## Examples

      iex> Mau.render("Hello world", %{})
      {:ok, "Hello world"}

      # Type preservation for single values
      iex> Mau.render("{{ 42 }}", %{}, preserve_types: true)
      {:ok, 42}

      iex> Mau.render("{{ user.active }}", %{"user" => %{"active" => true}}, preserve_types: true)
      {:ok, true}

      # Mixed content always returns strings
      iex> Mau.render("Count: {{ items | length }}", %{"items" => [1,2,3]}, preserve_types: true)
      {:ok, "Count: 3"}
  """
  def render(template, context, opts \\ [])

  def render(template, context, opts) when is_binary(template) and is_map(context) do
    with {:ok, ast} <- build_ast(template, opts),
         {:ok, result} <- render_ast(ast, context, opts) do
      {:ok, result}
    end
  end

  def render(ast, context, opts) when is_tuple(ast) and is_map(context) do
    render_ast(ast, context, opts)
  end

  def render(nodes, context, opts) when is_list(nodes) and is_map(context) do
    render_ast(nodes, context, opts)
  end

  @doc """
  Recursively renders template strings in nested maps.

  When a value fails to render, it keeps its template string. With
  `strict_mode: true`, the whole call returns `{:error, error}` instead.

  For Group 1, only handles plain text templates.

  ## Examples

      iex> Mau.render_map(%{message: "Hello world"}, %{})
      {:ok, %{message: "Hello world"}}
  """
  def render_map(nested_map, context, opts \\ []) when is_map(nested_map) and is_map(context) do
    opts = Keyword.put_new(opts, :preserve_types, true)

    try do
      result = render_map_recursive(nested_map, context, opts)
      {:ok, result}
    rescue
      e in Mau.Error -> {:error, e}
      e -> {:error, Mau.Error.runtime_error("Error rendering map: #{Exception.message(e)}")}
    end
  end

  # Shared compile pipeline for compile/2 and render/3
  defp build_ast(template, opts) do
    with :ok <- validate_template_size(template, opts) do
      case process_template(template) do
        {:ok, ast} ->
          {:ok, ast}

        {:error, error} ->
          if opts[:strict_mode], do: {:error, error}, else: {:ok, [Nodes.text_node(template)]}
      end
    end
  end

  defp process_template(template) do
    with {:ok, ast} <- Parser.parse(template, strict_mode: true),
         trimmed_ast <- WhitespaceProcessor.apply_whitespace_control(ast),
         processed_ast <- BlockProcessor.process_blocks(trimmed_ast) do
      {:ok, processed_ast}
    end
  rescue
    e in Mau.Error -> {:error, e}
    e -> {:error, Mau.Error.syntax_error("Parse error: #{Exception.message(e)}")}
  end

  defp render_ast(ast, context, opts) do
    Renderer.render(ast, context, opts)
  rescue
    e -> {:error, Mau.Error.runtime_error("Error rendering template: #{Exception.message(e)}")}
  end

  # Private helper for recursive map rendering
  # Already-rendered data injected by #pipe - never treat it as a template
  defp render_map_recursive({:mau_value, value}, _context, _opts), do: value

  defp render_map_recursive(map, context, opts) when is_map(map) do
    # Try to match special directive patterns
    case MapDirectives.match_directive(map) do
      {directive_type, args} ->
        MapDirectives.apply_directive({directive_type, args}, context, opts, &render_map_recursive/3)

      :none ->
        # Regular map - recursively process all values
        map
        |> Enum.map(fn {key, value} ->
          {key, render_map_recursive(value, context, opts)}
        end)
        |> Enum.into(%{})
    end
  end

  defp render_map_recursive(list, context, opts) when is_list(list) do
    Enum.map(list, &render_map_recursive(&1, context, opts))
  end

  defp render_map_recursive(value, context, opts) when is_binary(value) do
    if has_template_syntax?(value) do
      case render(value, context, opts) do
        {:ok, result} -> result
        # Return original value if rendering fails, unless strict
        {:error, error} -> if opts[:strict_mode], do: raise(error), else: value
      end
    else
      # Return as-is if no template syntax
      value
    end
  end

  defp render_map_recursive(value, _context, _opts), do: value

  # Helper to check if a string contains template syntax
  defp has_template_syntax?(value) when is_binary(value) do
    String.contains?(value, "{{") or
      String.contains?(value, "{%") or
      String.contains?(value, "{#")
  end

  # Validates template size against max_template_size option
  @max_template_size 100_000
  defp validate_template_size(template, opts) when is_binary(template) do
    max_size = opts[:max_template_size] || @max_template_size

    case max_size do
      max_size when is_integer(max_size) and max_size > 0 ->
        if byte_size(template) <= max_size do
          :ok
        else
          {:error,
           Mau.Error.runtime_error(
             "Template size #{byte_size(template)} exceeds maximum #{max_size} bytes"
           )}
        end

      _ ->
        :ok
    end
  end
end
