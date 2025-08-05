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
  def render_node(node, context) do
    case render_node_with_context(node, context) do
      {:ok, result, _updated_context} -> {:ok, result}
      {:error, error} -> {:error, error}
    end
  end

  # Renders a node and returns {result, updated_context} - main rendering pipeline
  defp render_node_with_context({:text, [content], _opts}, context) when is_binary(content) do
    {:ok, content, context}
  end

  defp render_node_with_context({:comment, [_content], _opts}, context) do
    {:ok, "", context}
  end

  defp render_node_with_context({:expression, [expression_ast], _opts}, context) do
    case evaluate_expression(expression_ast, context) do
      {:ok, value} -> {:ok, format_value(value), context}
      {:error, error} -> {:error, error}
    end
  end

  defp render_node_with_context({:tag, [tag_type | tag_parts], _opts}, context) do
    render_tag_with_context(tag_type, tag_parts, context)
  end

  defp render_node_with_context({:conditional_block, block_data, _opts}, context) do
    render_conditional_block_with_context(block_data, context)
  end

  defp render_node_with_context({:loop_block, block_data, _opts}, context) do
    render_loop_block_with_context(block_data, context)
  end

  defp render_node_with_context(node, _context) do
    error = Mau.Error.runtime_error("Unknown node type: #{inspect(node)}")
    {:error, error}
  end

  @doc """
  Renders a template AST with the given context.

  Handles both single nodes and lists of nodes.
  """
  def render(data, context, opts \\ [])

  def render(nodes, context, opts) when is_list(nodes) and is_map(context) do
    case render_nodes(nodes, context) do
      {:ok, parts} ->
        if opts[:preserve_types] && is_single_value_template?(nodes, parts) do
          # Extract the raw value from single expression templates
          extract_single_value(nodes, context)
        else
          {:ok, IO.iodata_to_binary(parts)}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def render(ast, context, opts) when is_map(context) do
    if opts[:preserve_types] && is_single_expression?(ast) do
      # For single expression nodes, evaluate and return the raw value
      case ast do
        {:expression, [expression_ast], _opts} ->
          evaluate_expression(expression_ast, context)

        _ ->
          render_node(ast, context)
      end
    else
      render_node(ast, context)
    end
  end

  # Private helper functions

  # Checks if AST represents a single expression (no mixed text)
  defp is_single_expression?({:expression, _expression_ast, _opts}), do: true
  defp is_single_expression?(_), do: false

  # Checks if a list of nodes represents a single value template
  defp is_single_value_template?(nodes, _parts) do
    case nodes do
      [{:expression, _expression_ast, _opts}] -> true
      _ -> false
    end
  end

  # Extracts the raw value from a single expression template
  defp extract_single_value([{:expression, [expression_ast], _opts}], context) do
    evaluate_expression(expression_ast, context)
  end

  defp extract_single_value(_, _),
    do: {:error, Mau.Error.runtime_error("Not a single value template")}

  # Renders a list of nodes
  defp render_nodes(nodes, context) do
    case render_nodes(nodes, context, []) do
      {:ok, parts, _updated_context} -> {:ok, parts}
      {:error, error} -> {:error, error}
    end
  end

  defp render_nodes([], context, acc) do
    {:ok, Enum.reverse(acc), context}
  end

  defp render_nodes([node | rest], context, acc) do
    case render_node_with_context(node, context) do
      {:ok, result, updated_context} ->
        render_nodes(rest, updated_context, [result | acc])

      {:error, error} ->
        {:error, error}
    end
  end

  # Evaluates expressions - handles literals, variables, and arithmetic operations
  defp evaluate_expression({:literal, [value], _opts}, _context) do
    {:ok, value}
  end

  defp evaluate_expression({:variable, path, _opts}, context) do
    extract_variable_value_with_context(path, context, context)
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

  defp evaluate_expression({:unary_op, [operator, operand], _opts}, context) do
    evaluate_unary_operation(operator, operand, context)
  end

  defp evaluate_expression({:call, [function_name, args], _opts}, context) do
    evaluate_call(function_name, args, context)
  end

  defp evaluate_expression(expression, _context) do
    error = Mau.Error.runtime_error("Unknown expression type: #{inspect(expression)}")
    {:error, error}
  end

  # ============================================================================
  # VARIABLE VALUE EXTRACTION
  # ============================================================================

  # Context-aware variable value extraction with support for variable indices.
  # This is the main entry point for resolving variable paths like:
  # - Simple variables: "user"
  # - Property access: "user.name"
  # - Array access: "items[0]", "items[index]"
  # - Complex paths: "users[0].profile.name"

  defp extract_variable_value_with_context([identifier | path_rest], context, original_context)
       when is_binary(identifier) do
    case Map.get(context, identifier) do
      nil -> {:ok, nil}
      value when path_rest == [] -> {:ok, value}
      value -> extract_variable_value_with_context_from_value(path_rest, value, original_context)
    end
  end

  # Fallback for edge cases
  defp extract_variable_value_with_context(_path, _context, _original_context) do
    {:ok, nil}
  end

  # Continues path traversal from a resolved value (not the initial context map)
  defp extract_variable_value_with_context_from_value([], value, _original_context) do
    {:ok, value}
  end

  defp extract_variable_value_with_context_from_value(
         [access | path_rest],
         value,
         original_context
       ) do
    with {:ok, accessed_value} <- resolve_value_access(access, value, original_context) do
      extract_variable_value_with_context_from_value(path_rest, accessed_value, original_context)
    end
  end

  # Unified access resolution - handles both property and index access
  defp resolve_value_access({:property, property}, value, _context) when is_map(value) do
    case Map.fetch(value, property) do
      {:ok, new_value} -> {:ok, new_value}
      # Property not found, return nil
      :error -> {:ok, Map.get(value, String.to_atom(property))}
    end
  end

  defp resolve_value_access({:index, index}, value, context) do
    with {:ok, resolved_index} <- resolve_index_value(index, context) do
      {:ok, get_list_element(value, resolved_index)}
    end
  end

  defp resolve_value_access(_access, _value, _context) do
    {:ok, nil}
  end

  # Resolves index values from literals, variables, or direct values
  # This provides a clean pathway for handling different index types:
  # - {:literal, [42], []} -> 42 (if valid)
  # - {:variable, ["index"], []} -> evaluates variable "index" (if valid)
  # - 42 -> 42 (direct value, if valid)
  defp resolve_index_value({:literal, [literal_value], _opts}, _context) do
    if is_valid_index_or_key(literal_value) do
      {:ok, literal_value}
    else
      {:error,
       Mau.Error.runtime_error("Invalid array index or map key: #{inspect(literal_value)}")}
    end
  end

  defp resolve_index_value({:variable, _path, _opts} = var_expr, context) do
    case evaluate_expression(var_expr, context) do
      {:ok, value} ->
        if is_valid_index_or_key(value) do
          {:ok, value}
        else
          {:error, Mau.Error.runtime_error("Invalid array index or map key: #{inspect(value)}")}
        end

      error ->
        error
    end
  end

  defp resolve_index_value(direct_value, _context) do
    if is_valid_index_or_key(direct_value) do
      {:ok, direct_value}
    else
      {:error,
       Mau.Error.runtime_error("Invalid array index or map key: #{inspect(direct_value)}")}
    end
  end

  # Helper to check if a value can be used as an index or key
  # Allow all integers, including negative
  defp is_valid_index_or_key(value) when is_integer(value), do: true
  defp is_valid_index_or_key(value) when is_binary(value), do: true
  defp is_valid_index_or_key(value) when is_atom(value), do: true
  defp is_valid_index_or_key(_), do: false

  # Gets an element from list/map by index/key - returns the value directly (nil if not found)
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
    error =
      Mau.Error.runtime_error(
        "Unsupported binary operation: #{inspect(left)} #{operator} #{inspect(right)}"
      )

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

      {:error, error} ->
        {:error, error}
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

      {:error, error} ->
        {:error, error}
    end
  end

  # Unary operation evaluation
  defp evaluate_unary_operation("not", operand, context) do
    case evaluate_expression(operand, context) do
      {:ok, value} -> {:ok, !is_truthy(value)}
      {:error, error} -> {:error, error}
    end
  end

  # Filter/function call evaluation
  defp evaluate_call(function_name, args, context) do
    with {:ok, evaluated_args} <- evaluate_arguments(args, context) do
      case Mau.FilterRegistry.apply(
             function_name,
             List.first(evaluated_args, nil),
             Enum.drop(evaluated_args, 1)
           ) do
        {:ok, result} ->
          {:ok, result}

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
  defp is_truthy(map) when is_map(map), do: map_size(map) > 0
  defp is_truthy(_), do: true

  # Tag rendering functions

  defp render_tag_with_context(:assign, [variable_name, expression], context) do
    case evaluate_expression(expression, context) do
      {:ok, value} ->
        updated_context = Map.put(context, variable_name, value)
        # Assignment produces no output
        {:ok, "", updated_context}

      {:error, error} ->
        {:error, error}
    end
  end

  # Conditional tags - these need special handling as they work in blocks
  defp render_tag_with_context(:if, [condition], context) do
    case evaluate_expression(condition, context) do
      {:ok, value} ->
        # For now, store the condition result in a special context key
        # This is a placeholder - proper block handling will be implemented later
        updated_context = Map.put(context, :__if_condition__, is_truthy(value))
        {:ok, "", updated_context}

      {:error, error} ->
        {:error, error}
    end
  end

  defp render_tag_with_context(:elsif, [condition], context) do
    case evaluate_expression(condition, context) do
      {:ok, value} ->
        # Placeholder implementation
        updated_context = Map.put(context, :__elsif_condition__, is_truthy(value))
        {:ok, "", updated_context}

      {:error, error} ->
        {:error, error}
    end
  end

  defp render_tag_with_context(:else, [], context) do
    # Placeholder implementation
    {:ok, "", context}
  end

  defp render_tag_with_context(:endif, [], context) do
    # Placeholder implementation
    {:ok, "", context}
  end

  # Individual for/endfor tags (when block processing fails or doesn't apply)
  defp render_tag_with_context(:for, [_loop_variable, _collection_expression], context) do
    # Individual for tag - just return empty (should be handled by block processor)
    {:ok, "", context}
  end

  defp render_tag_with_context(:endfor, [], context) do
    # Individual endfor tag - just return empty
    {:ok, "", context}
  end

  defp render_tag_with_context(tag_type, _tag_parts, _context) do
    error = Mau.Error.runtime_error("Unknown tag type: #{inspect(tag_type)}")
    {:error, error}
  end

  # Conditional block rendering functions

  defp render_conditional_block_with_context(block_data, context) do
    if_branch = Keyword.get(block_data, :if_branch)
    elsif_branches = Keyword.get(block_data, :elsif_branches, [])
    else_branch = Keyword.get(block_data, :else_branch)

    case if_branch do
      {condition, content} ->
        case evaluate_expression(condition, context) do
          {:ok, condition_value} ->
            if is_truthy(condition_value) do
              # Render if branch content
              render_conditional_content(content, context)
            else
              # Check elsif branches
              render_elsif_branches(elsif_branches, else_branch, context)
            end

          {:error, error} ->
            {:error, error}
        end

      _ ->
        error = Mau.Error.runtime_error("Invalid conditional block structure")
        {:error, error}
    end
  end

  defp render_elsif_branches([], else_branch, context) do
    # No more elsif branches, render else if present
    case else_branch do
      # No else branch
      nil -> {:ok, "", context}
      content when is_list(content) -> render_conditional_content(content, context)
    end
  end

  defp render_elsif_branches([{condition, content} | rest_branches], else_branch, context) do
    case evaluate_expression(condition, context) do
      {:ok, condition_value} ->
        if is_truthy(condition_value) do
          # Render this elsif branch content
          render_conditional_content(content, context)
        else
          # Check next elsif branch
          render_elsif_branches(rest_branches, else_branch, context)
        end

      {:error, error} ->
        {:error, error}
    end
  end

  # Helper to render nodes for conditional blocks
  defp render_conditional_content(nodes, context) do
    case render_nodes(nodes, context, []) do
      {:ok, parts, updated_context} ->
        {:ok, parts, updated_context}

      {:error, error} ->
        {:error, error}
    end
  end

  # Loop block rendering functions

  defp render_loop_block_with_context(block_data, context) do
    loop_variable = Keyword.get(block_data, :loop_variable)
    collection_expression = Keyword.get(block_data, :collection_expression)
    content = Keyword.get(block_data, :content, [])

    with {:ok, collection} <- evaluate_expression(collection_expression, context),
         {:ok, items} <- ensure_iterable(collection),
         {:ok, acc_result, updated_context} <-
           render_loop_items(items, loop_variable, content, context) do
      updated_context = Map.drop(updated_context, [loop_variable, "forloop"])
      {:ok, Enum.reverse(acc_result), updated_context}
    end
  end

  defp ensure_iterable(value) when is_list(value), do: {:ok, value}

  defp ensure_iterable(value) when is_map(value) do
    # Convert map to list of {key, value} tuples
    {:ok, Enum.to_list(value)}
  end

  defp ensure_iterable(value) when is_binary(value) do
    # Convert string to list of characters
    {:ok, String.graphemes(value)}
  end

  defp ensure_iterable(nil), do: {:ok, []}
  defp ensure_iterable(_), do: {:error, Mau.Error.runtime_error("Collection is not iterable")}

  defp render_loop_items(items, loop_variable, content, context) do
    loop_context = create_loop_context(context, loop_variable, items)

    Enum.reduce_while(items, {:ok, [], loop_context}, fn item, {:ok, acc, loop_context} ->
      # Update loop context with current item
      updated_loop_context = update_loop_context(loop_context, loop_variable, item)

      case render_nodes(content, updated_loop_context, []) do
        {:ok, parts, final_context} ->
          restored_context =
            Map.merge(final_context, %{
              loop_variable => item,
              "forloop" => updated_loop_context["forloop"]
            })

          # Accumulate rendered content
          {:cont, {:ok, [parts | acc], restored_context}}

        {:error, error} ->
          {:halt, {:error, error}}
      end
    end)
  end

  defp create_loop_context(base_context, loop_variable, items) do
    length = length(items)

    # Preserve parent forloop context if exists
    parent_forloop = Map.get(base_context, "forloop")

    # Initialize forloop data
    # set index to -1 (0-based), rindex to length - 1
    # because we will increment index before first item render
    forloop_data = %{
      # 0-based index
      "index" => -1,
      # Reverse index (remaining items + 1)
      "rindex" => length - 1,
      # Reverse 0-based index
      "first" => false,
      "last" => false,
      "length" => length
    }

    # Add parent loop reference if we're in a nested loop
    forloop_data =
      if parent_forloop do
        Map.put(forloop_data, "parentloop", parent_forloop)
      else
        forloop_data
      end

    base_context
    |> Map.put(loop_variable, nil)
    |> Map.put("forloop", forloop_data)
  end

  defp update_loop_context(loop_context, loop_variable, item) do
    forloop = Map.get(loop_context, "forloop", %{})
    index = forloop["index"] + 1

    forloop =
      Map.merge(forloop, %{
        "index" => index,
        "rindex" => forloop["length"] - 1 - index,
        "first" => index == 0,
        "last" => forloop["length"] - 1 == index
      })

    Map.put(loop_context, "forloop", forloop)
    |> Map.put(loop_variable, item)
  end
end
