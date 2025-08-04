defmodule Mau.Renderer do
  @moduledoc """
  Renderer for the Mau template engine.
  
  Handles rendering of AST nodes into output strings.
  For Group 1, only handles text node rendering.
  """

  @doc """
  Renders an AST node to a string.
  
  Handles text nodes and expression nodes with literal evaluation.
  
  ## Examples
  
      iex> Mau.Renderer.render_node({:text, ["Hello world"], []}, %{})
      {:ok, "Hello world"}
      
      iex> Mau.Renderer.render_node({:expression, [{:literal, ["hello"], []}], []}, %{})
      {:ok, "hello"}
      
      iex> Mau.Renderer.render_node({:expression, [{:literal, [42], []}], []}, %{})
      {:ok, "42"}
  """
  def render_node({:text, [content], _opts}, _context) when is_binary(content) do
    {:ok, content}
  end

  def render_node({:expression, [expression_ast], _opts}, context) do
    case evaluate_expression(expression_ast, context) do
      {:ok, value} -> {:ok, format_value(value)}
      {:error, error} -> {:error, error}
    end
  end

  def render_node(node, _context) do
    error = Mau.Error.runtime_error("Unknown node type: #{inspect(node)}")
    {:error, error}
  end

  @doc """
  Renders a template AST with the given context.
  
  Handles both single nodes and lists of nodes.
  """
  def render(nodes, context) when is_list(nodes) and is_map(context) do
    case render_nodes(nodes, context) do
      {:ok, parts} -> {:ok, Enum.join(parts, "")}
      {:error, error} -> {:error, error}
    end
  end

  def render(ast, context) when is_map(context) do
    render_node(ast, context)
  end

  # Private helper functions

  # Renders a list of nodes
  defp render_nodes(nodes, context) do
    render_nodes(nodes, context, [])
  end

  defp render_nodes([], _context, acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp render_nodes([node | rest], context, acc) do
    case render_node(node, context) do
      {:ok, result} -> render_nodes(rest, context, [result | acc])
      {:error, error} -> {:error, error}
    end
  end

  # Evaluates expressions - handles literals and variables
  defp evaluate_expression({:literal, [value], _opts}, _context) do
    {:ok, value}
  end

  defp evaluate_expression({:variable, path, _opts}, context) do
    extract_variable_value(path, context)
  end

  defp evaluate_expression(expression, _context) do
    error = Mau.Error.runtime_error("Unknown expression type: #{inspect(expression)}")
    {:error, error}
  end

  # Extracts variable values from context following the path
  defp extract_variable_value([identifier], context) when is_binary(identifier) do
    case Map.get(context, identifier) do
      nil -> {:ok, nil}  # Undefined variables return nil for now
      value -> {:ok, value}
    end
  end

  defp extract_variable_value([identifier | path_rest], context) when is_binary(identifier) do
    case Map.get(context, identifier) do
      nil -> {:ok, nil}
      value when is_map(value) -> extract_variable_value(path_rest, value)
      value when is_list(value) -> extract_from_list(path_rest, value)
      _value -> {:ok, nil}  # Can't traverse further
    end
  end

  # Helper for property access
  defp extract_variable_value([{:property, property} | path_rest], value) when is_map(value) do
    case Map.get(value, property) do
      nil -> {:ok, nil}
      new_value -> extract_variable_value(path_rest, new_value)
    end
  end

  # Helper for array index access
  defp extract_variable_value([{:index, index} | path_rest], value) when is_list(value) do
    case get_list_element(value, index) do
      nil -> {:ok, nil}
      new_value -> extract_variable_value(path_rest, new_value)
    end
  end

  # Base case: empty path means we've reached the final value
  defp extract_variable_value([], value) do
    {:ok, value}
  end

  # Fallback for unsupported access patterns
  defp extract_variable_value(_path, _value) do
    {:ok, nil}
  end

  # Helper for list access from property chain
  defp extract_from_list([{:index, index} | path_rest], list) when is_list(list) do
    case get_list_element(list, index) do
      nil -> {:ok, nil}
      value -> extract_variable_value(path_rest, value)
    end
  end

  defp extract_from_list(_path, _list) do
    {:ok, nil}
  end

  # Gets an element from list by index (integer) or by variable name lookup
  defp get_list_element(list, index) when is_integer(index) and index >= 0 do
    Enum.at(list, index)
  end

  defp get_list_element(_list, _index) do
    nil  # For now, variable indices are not implemented
  end

  # Formats values for output
  defp format_value(value) when is_binary(value), do: value
  defp format_value(value) when is_number(value), do: to_string(value)
  defp format_value(true), do: "true"
  defp format_value(false), do: "false"
  defp format_value(nil), do: ""
  defp format_value(value), do: inspect(value)
end