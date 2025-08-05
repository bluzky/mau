defmodule Mau do
  @moduledoc """
  Mau template engine for the Prana template language.

  Provides three main functions:
  - `compile/2` - Parse template string into AST
  - `render/3` - Render template string or AST with context
  - `render_map/3` - Recursively render template strings in nested maps
  """

  alias Mau.Parser
  alias Mau.Renderer
  alias Mau.BlockProcessor
  alias Mau.WhitespaceProcessor

  @doc """
  Compiles a template string into an AST.

  Handles text and expression blocks.

  ## Options
  - `:strict_mode` - boolean, default `false`

  ## Examples

      iex> Mau.compile("Hello world")
      {:ok, [{:text, ["Hello world"], []}]}
  """
  def compile(template, opts \\ []) when is_binary(template) do
    case Parser.parse(template) do
      {:ok, ast} ->
        if opts[:strict_mode] do
          {:ok, ast, []}
        else
          {:ok, ast}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Renders a template string or AST with the given context.

  ## Options
  - `:preserve_types` - boolean, default `false`. When `true`, preserves data types 
    for single-value templates (templates that render to a single expression result).

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
    with {:ok, ast} <- Parser.parse(template),
         trimmed_ast <- WhitespaceProcessor.apply_whitespace_control(ast),
         processed_ast <- BlockProcessor.process_blocks(trimmed_ast),
         {:ok, result} <- Renderer.render(processed_ast, context, opts) do
      {:ok, result}
    end
  end

  def render(ast, context, opts) when is_tuple(ast) and is_map(context) do
    Renderer.render(ast, context, opts)
  end

  def render(nodes, context, opts) when is_list(nodes) and is_map(context) do
    Renderer.render(nodes, context, opts)
  end

  @doc """
  Recursively renders template strings in nested maps.

  For Group 1, only handles plain text templates.

  ## Examples

      iex> Mau.render_map(%{message: "Hello world"}, %{})
      {:ok, %{message: "Hello world"}}
  """
  def render_map(nested_map, context, opts \\ []) when is_map(nested_map) and is_map(context) do
    try do
      result = render_map_recursive(nested_map, context, opts)
      {:ok, result}
    rescue
      e -> {:error, Mau.Error.runtime_error("Error rendering map: #{Exception.message(e)}")}
    end
  end

  # Private helper for recursive map rendering
  defp render_map_recursive(map, context, opts) when is_map(map) do
    map
    |> Enum.map(fn {key, value} ->
      {key, render_map_recursive(value, context, opts)}
    end)
    |> Enum.into(%{})
  end

  defp render_map_recursive(value, context, opts) when is_binary(value) do
    if has_template_syntax?(value) do
      case render(value, context, opts) do
        {:ok, result} -> result
        # Return original value if rendering fails
        {:error, _} -> value
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
end
