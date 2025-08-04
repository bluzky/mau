defmodule Mau.Renderer do
  @moduledoc """
  Renderer for the Mau template engine.
  
  Handles rendering of AST nodes into output strings.
  For Group 1, only handles text node rendering.
  """

  @doc """
  Renders an AST node to a string.
  
  For Group 1, only handles text nodes.
  
  ## Examples
  
      iex> Mau.Renderer.render_node({:text, ["Hello world"], []}, %{})
      {:ok, "Hello world"}
  """
  def render_node({:text, [content], _opts}, _context) when is_binary(content) do
    {:ok, content}
  end

  def render_node(node, _context) do
    error = Mau.Error.runtime_error("Unknown node type: #{inspect(node)}")
    {:error, error}
  end

  @doc """
  Renders a template AST with the given context.
  
  For Group 1, only handles single text nodes.
  """
  def render(ast, context) when is_map(context) do
    render_node(ast, context)
  end
end