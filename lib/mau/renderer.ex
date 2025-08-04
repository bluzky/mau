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

  # Evaluates expressions - handles literals, variables, and arithmetic operations
  defp evaluate_expression({:literal, [value], _opts}, _context) do
    {:ok, value}
  end

  defp evaluate_expression({:variable, path, _opts}, context) do
    extract_variable_value(path, context)
  end

  defp evaluate_expression({:binary_op, [operator, left, right], _opts}, context) do
    with {:ok, left_value} <- evaluate_expression(left, context),
         {:ok, right_value} <- evaluate_expression(right, context) do
      evaluate_binary_operation(operator, left_value, right_value)
    end
  end

  defp evaluate_expression({:logical_op, [operator, left, right], _opts}, context) do
    evaluate_logical_operation(operator, left, right, context)
  end

  defp evaluate_expression({:call, [function_name, args], _opts}, context) do
    evaluate_call(function_name, args, context)
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
      value -> extract_variable_value(path_rest, value)
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
  defp extract_variable_value([{:index, index} | path_rest], value) do
    # Extract the actual index value from literal nodes
    actual_index = case index do
      {:literal, [literal_value], _opts} -> literal_value
      other -> other
    end
    
    case get_list_element(value, actual_index) do
      nil -> {:ok, nil}
      new_value -> extract_variable_value(path_rest, new_value)
    end
  end

  # Base case: empty path means we've reached the final value
  defp extract_variable_value([], value) do
    {:ok, value}
  end

  # Fallback for unsupported access patterns - handle any remaining cases
  defp extract_variable_value([{:property, _property} | _path_rest], value) when not is_map(value) do
    # Trying to access property on non-map value
    {:ok, nil}
  end

  defp extract_variable_value(_path, _value) do
    {:ok, nil}
  end

  # Gets an element from list/map by literal index/key only
  defp get_list_element(list, index) when is_list(list) and is_integer(index) and index >= 0 do
    Enum.at(list, index)
  end

  defp get_list_element(list, index) when is_list(list) and is_integer(index) and index < 0 do
    # Negative indices are not supported
    nil
  end

  defp get_list_element(map, key) when is_map(map) and is_binary(key) do
    Map.get(map, key)
  end

  defp get_list_element(map, key) when is_map(map) and is_atom(key) do
    Map.get(map, key)
  end

  defp get_list_element(_collection, _key) do
    # All other cases (unsupported collection types or key types)
    nil
  end

  # Formats values for output
  defp format_value(value) when is_binary(value), do: value
  defp format_value(value) when is_number(value), do: to_string(value)
  defp format_value(true), do: "true"
  defp format_value(false), do: "false"
  defp format_value(nil), do: ""
  defp format_value(value), do: inspect(value)

  # Arithmetic operation evaluation
  defp evaluate_binary_operation("+", left, right) when is_number(left) and is_number(right) do
    {:ok, left + right}
  end

  defp evaluate_binary_operation("+", left, right) when is_binary(left) or is_binary(right) do
    # String concatenation
    {:ok, to_string(left) <> to_string(right)}
  end

  defp evaluate_binary_operation("+", nil, right) do
    # Treat nil as empty string for concatenation
    {:ok, to_string(right)}
  end

  defp evaluate_binary_operation("+", left, nil) do
    # Treat nil as empty string for concatenation
    {:ok, to_string(left)}
  end

  defp evaluate_binary_operation("-", left, right) when is_number(left) and is_number(right) do
    {:ok, left - right}
  end

  defp evaluate_binary_operation("*", left, right) when is_number(left) and is_number(right) do
    {:ok, left * right}
  end

  defp evaluate_binary_operation("/", left, right) when is_number(left) and is_number(right) do
    if right == 0 do
      error = Mau.Error.runtime_error("Division by zero")
      {:error, error}
    else
      {:ok, left / right}
    end
  end

  defp evaluate_binary_operation("%", left, right) when is_integer(left) and is_integer(right) do
    if right == 0 do
      error = Mau.Error.runtime_error("Modulo by zero")
      {:error, error}
    else
      {:ok, rem(left, right)}
    end
  end

  # Comparison operations
  defp evaluate_binary_operation("==", left, right) do
    {:ok, left == right}
  end

  defp evaluate_binary_operation("!=", left, right) do
    {:ok, left != right}
  end

  defp evaluate_binary_operation(">", left, right) when is_number(left) and is_number(right) do
    {:ok, left > right}
  end

  defp evaluate_binary_operation(">=", left, right) when is_number(left) and is_number(right) do
    {:ok, left >= right}
  end

  defp evaluate_binary_operation("<", left, right) when is_number(left) and is_number(right) do
    {:ok, left < right}
  end

  defp evaluate_binary_operation("<=", left, right) when is_number(left) and is_number(right) do
    {:ok, left <= right}
  end

  # String comparison operations
  defp evaluate_binary_operation(">", left, right) when is_binary(left) and is_binary(right) do
    {:ok, left > right}
  end

  defp evaluate_binary_operation(">=", left, right) when is_binary(left) and is_binary(right) do
    {:ok, left >= right}
  end

  defp evaluate_binary_operation("<", left, right) when is_binary(left) and is_binary(right) do
    {:ok, left < right}
  end

  defp evaluate_binary_operation("<=", left, right) when is_binary(left) and is_binary(right) do
    {:ok, left <= right}
  end

  defp evaluate_binary_operation(operator, left, right) do
    error = Mau.Error.runtime_error("Unsupported binary operation: #{inspect(left)} #{operator} #{inspect(right)}")
    {:error, error}
  end

  # Logical operation evaluation with short-circuiting
  defp evaluate_logical_operation("and", left, right, context) do
    case evaluate_expression(left, context) do
      {:ok, left_value} ->
        if is_truthy(left_value) do
          evaluate_expression(right, context)
        else
          {:ok, false}
        end
      {:error, error} -> {:error, error}
    end
  end

  defp evaluate_logical_operation("or", left, right, context) do
    case evaluate_expression(left, context) do
      {:ok, left_value} ->
        if is_truthy(left_value) do
          {:ok, true}
        else
          case evaluate_expression(right, context) do
            {:ok, right_value} -> {:ok, is_truthy(right_value)}
            {:error, error} -> {:error, error}
          end
        end
      {:error, error} -> {:error, error}
    end
  end

  # Filter/function call evaluation
  defp evaluate_call(function_name, args, context) do
    with {:ok, evaluated_args} <- evaluate_arguments(args, context) do
      case Mau.FilterRegistry.apply(function_name, List.first(evaluated_args, nil), Enum.drop(evaluated_args, 1)) do
        {:ok, result} -> {:ok, result}
        {:error, :filter_not_found} ->
          error = Mau.Error.runtime_error("Unknown filter or function: #{function_name}")
          {:error, error}
        {:error, {:filter_error, reason}} ->
          error = Mau.Error.runtime_error("Filter error in #{function_name}: #{inspect(reason)}")
          {:error, error}
        {:error, reason} ->
          error = Mau.Error.runtime_error("Filter error in #{function_name}: #{inspect(reason)}")
          {:error, error}
      end
    end
  end

  # Evaluates a list of arguments
  defp evaluate_arguments(args, context) do
    evaluate_arguments(args, context, [])
  end

  defp evaluate_arguments([], _context, acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp evaluate_arguments([arg | rest], context, acc) do
    case evaluate_expression(arg, context) do
      {:ok, value} ->
        evaluate_arguments(rest, context, [value | acc])
      {:error, error} ->
        {:error, error}
    end
  end

  # Truthiness evaluation rules
  defp is_truthy(nil), do: false
  defp is_truthy(false), do: false
  defp is_truthy(""), do: false
  defp is_truthy(0), do: false
  defp is_truthy(value) when is_float(value) and value == 0.0, do: false
  defp is_truthy([]), do: false
  defp is_truthy(%{}), do: false
  defp is_truthy(_), do: true
end