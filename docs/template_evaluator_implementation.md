# Template Evaluator Implementation Guide

This document provides implementation guidance for evaluating the Prana template AST defined in `template_ast_specification.md`.

## Overview

The template evaluator takes the parsed AST and renders it into final output by:
1. Evaluating expressions against a context
2. Executing control flow logic with unified tag rendering
3. Applying filters and functions
4. Managing variable scope and assignments

## Core Design Principles

- **Unified Tag Interface**: All tags use `render_tag(tag_name, params, opts, context)` for consistent handling
- **Clear Separation**: Distinguish between evaluation (expressions) and rendering (tags/text)
- **Consistent Naming**: Use "render" for output generation and "evaluate" for expression computation
- **Pattern Matching**: Use Elixir's pattern matching for clean tag dispatch

## Core Evaluation Patterns

### Pattern Matching for Node Types

```elixir
def evaluate_node({:text, [content], opts}) do
  # Handle raw text node
  {:ok, content}
end

def evaluate_node({:literal, [value], opts}) do
  # Handle literal value node
  {:ok, value}
end

def evaluate_node({:expression, [expr], opts}) do
  # Handle expression node
  case evaluate_expression(expr) do
    {:ok, result} -> {:ok, to_string(result)}
    {:error, reason} -> {:error, reason}
  end
end

def evaluate_node({:tag, [tag_name | params], opts}) do
  # Handle tag node with unified render_tag function
  render_tag(tag_name, params, opts, context)
end
```

## Unified Tag Rendering

### Pattern-Matched Tag Rendering

```elixir
# If/Elsif/Else tag
def render_tag(:if, [clauses], opts, context) do
  # Iterate through condition-body pairs
  Enum.find_value(clauses, fn
    {:else, body} ->
      # Execute else clause
      {:ok, render_body(body, context)}
    
    {condition, body} ->
      # Check condition and execute body if true
      case evaluate_expression(condition, context) do
        {:ok, truthy} when is_truthy(truthy) -> {:ok, render_body(body, context)}
        _ -> nil
      end
  end) || {:ok, ""}
end

# For loop tag
def render_tag(:for, [var_name, collection_expr, body, loop_opts], opts, context) do
  case evaluate_expression(collection_expr, context) do
    {:ok, collection} when is_list(collection) ->
      # Apply limit and offset from loop_opts
      limited_collection = apply_loop_limits(collection, loop_opts)
      
      # Iterate and render body for each item
      results = Enum.with_index(limited_collection)
      |> Enum.map(fn {item, index} ->
        # Create loop context with item variable and loop metadata
        loop_context = Map.merge(context, %{
          var_name => item,
          "forloop" => create_forloop_metadata(index, limited_collection)
        })
        
        render_body(body, loop_context)
      end)
      
      {:ok, Enum.join(results)}
    
    {:ok, _non_list} ->
      {:error, "For loop collection must be a list"}
    
    {:error, reason} -> 
      {:error, reason}
  end
end

# Assignment tag
def render_tag(:assign, [var_name, value_expr, []], opts, context) do
  case evaluate_expression(value_expr, context) do
    {:ok, value} -> 
      # Return updated context
      {:ok, :assign, var_name, value}
    {:error, reason} -> 
      {:error, reason}
  end
end

# Catch-all for unknown tags
def render_tag(unknown_tag, _params, _opts, _context) do
  {:error, "Unknown tag: #{unknown_tag}"}
end

# Helper functions
defp create_forloop_metadata(index, collection) do
  length = length(collection)
  %{
    index: index + 1,
    index0: index,
    rindex: length - index,
    rindex0: length - index - 1,
    first: index == 0,
    last: index == length - 1,
    length: length
  }
end

defp is_truthy(nil), do: false
defp is_truthy(false), do: false
defp is_truthy(""), do: false
defp is_truthy([]), do: false
defp is_truthy(%{} = map) when map_size(map) == 0, do: false
defp is_truthy(_), do: true

defp apply_loop_limits(collection, loop_opts) do
  offset = Keyword.get(loop_opts, :offset, 0)
  limit = Keyword.get(loop_opts, :limit, length(collection))
  
  collection
  |> Enum.drop(offset)
  |> Enum.take(limit)
end
```


## Expression Evaluation

### Main Expression Dispatcher

```elixir
def evaluate_expression(expr, context) do
  case expr do
    {:variable, path, opts} -> evaluate_variable(path, opts, context)
    {:literal, [value], opts} -> {:ok, value}
    {:binary_op, [op, left, right], opts} -> evaluate_binary_op(op, left, right, opts, context)
    {:logical_op, [op, left, right], opts} -> evaluate_logical_op(op, left, right, opts, context)
    {:call, [func_name, args], opts} -> evaluate_call(func_name, args, opts, context)
    
    # Unknown expression type
    {unknown_type, _params, _opts} ->
      {:error, "Unknown expression type: #{unknown_type}"}
  end
end
```

### Variable Access

```elixir
def evaluate_expression({:variable, path, opts}) do
  case extract_variable_value(path, context) do
    {:ok, value} -> {:ok, value}
    {:error, _} when opts[:strict_mode] == false -> {:ok, nil}
    {:error, reason} -> {:error, reason}
  end
end

defp extract_variable_value([key], context) do
  case Map.get(context, key) do
    nil -> {:error, "Variable '#{key}' not found"}
    value -> {:ok, value}
  end
end

defp extract_variable_value([key | rest], context) do
  case Map.get(context, key) do
    nil -> {:error, "Variable '#{key}' not found"}
    value when is_map(value) -> extract_variable_value(rest, value)
    value when is_list(value) -> extract_from_list(rest, value)
    _ -> {:error, "Cannot access property on non-object value"}
  end
end

defp extract_from_list([index | rest], list) when is_integer(index) do
  case Enum.at(list, index) do
    nil -> {:error, "Index #{index} out of bounds"}
    value when rest == [] -> {:ok, value}
    value when is_map(value) -> extract_variable_value(rest, value)
    _ -> {:error, "Cannot access property on non-object value"}
  end
end
```

### Binary Operations

```elixir
def evaluate_expression({:binary_op, [operator, left_expr, right_expr], opts}) do
  with {:ok, left} <- evaluate_expression(left_expr),
       {:ok, right} <- evaluate_expression(right_expr) do
    apply_binary_operation(operator, left, right)
  end
end

defp apply_binary_operation(:==, left, right), do: {:ok, left == right}
defp apply_binary_operation(:!=, left, right), do: {:ok, left != right}
defp apply_binary_operation(:>, left, right) when is_number(left) and is_number(right), do: {:ok, left > right}
defp apply_binary_operation(:>=, left, right) when is_number(left) and is_number(right), do: {:ok, left >= right}
defp apply_binary_operation(:<, left, right) when is_number(left) and is_number(right), do: {:ok, left < right}
defp apply_binary_operation(:<=, left, right) when is_number(left) and is_number(right), do: {:ok, left <= right}
defp apply_binary_operation(:+, left, right) when is_number(left) and is_number(right), do: {:ok, left + right}
defp apply_binary_operation(:-, left, right) when is_number(left) and is_number(right), do: {:ok, left - right}
defp apply_binary_operation(:*, left, right) when is_number(left) and is_number(right), do: {:ok, left * right}
defp apply_binary_operation(:/, left, right) when is_number(left) and is_number(right) and right != 0, do: {:ok, left / right}
defp apply_binary_operation(:/, _left, 0), do: {:error, "Division by zero"}
defp apply_binary_operation(op, left, right), do: {:error, "Unsupported operation #{op} with #{inspect(left)} and #{inspect(right)}"}
```

### Logical Operations

```elixir
def evaluate_expression({:logical_op, [operator, left_expr, right_expr], opts}) do
  case operator do
    :and ->
      case evaluate_expression(left_expr) do
        {:ok, left} when left in [nil, false] -> {:ok, false}
        {:ok, _left} -> evaluate_expression(right_expr)
        {:error, reason} -> {:error, reason}
      end
    
    :or ->
      case evaluate_expression(left_expr) do
        {:ok, left} when left not in [nil, false] -> {:ok, left}
        {:ok, _left} -> evaluate_expression(right_expr)
        {:error, reason} -> {:error, reason}
      end
  end
end
```

### Function/Filter Calls

```elixir
def evaluate_expression({:call, [function_name, args], opts}) do
  # Evaluate all arguments first
  case evaluate_arguments(args) do
    {:ok, evaluated_args} ->
      apply_filter(function_name, evaluated_args)
    {:error, reason} ->
      {:error, reason}
  end
end

defp evaluate_arguments(args) do
  args
  |> Enum.reduce_while({:ok, []}, fn arg, {:ok, acc} ->
    case evaluate_expression(arg) do
      {:ok, value} -> {:cont, {:ok, acc ++ [value]}}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end)
end

defp apply_filter(function_name, args) do
  case FilterRegistry.apply_filter(function_name, List.first(args), List.delete_at(args, 0)) do
    {:ok, result} -> {:ok, result}
    {:error, reason} -> {:error, "Filter '#{function_name}' failed: #{reason}"}
  end
end
```

## AST Traversal and Processing

### Recursive Processing

```elixir
def process_ast(nodes) when is_list(nodes) do
  Enum.map(nodes, &process_node/1)
end

def process_node({:text, [content], opts} = node) do
  # Text nodes don't need processing
  node
end

def process_node({:literal, [value], opts} = node) do
  # Literal nodes don't need processing
  node
end

def process_node({:expression, [expr], opts}) do
  # Recursively process expression
  processed_expr = process_expression(expr)
  {:expression, [processed_expr], opts}
end

def process_node({:tag, [tag_name | params], opts}) do
  process_tag(tag_name, params, opts)
end

# Pattern-matched tag processing
def process_tag(:if, [clauses], opts) do
  # Process if clauses
  processed_clauses = Enum.map(clauses, fn
    {:else, body} -> {:else, process_ast(body)}
    {condition, body} -> {process_expression(condition), process_ast(body)}
  end)
  {:tag, [:if, processed_clauses], opts}
end

def process_tag(:for, [var_name, collection_expr, body, loop_opts], opts) do
  # Process for loop with flattened structure
  processed_collection = process_expression(collection_expr)
  processed_body = process_ast(body)
  {:tag, [:for, var_name, processed_collection, processed_body, loop_opts], opts}
end

def process_tag(:assign, [var_name, value_expr, []], opts) do
  # Process assign tag
  processed_value = process_expression(value_expr)
  {:tag, [:assign, var_name, processed_value, []], opts}
end

# Catch-all for unknown tags
def process_tag(tag_name, params, opts) do
  # Generic tag processing fallback
  {:tag, [tag_name | params], opts}
end

def process_expression({:call, [function_name, args], opts}) do
  # Recursively process call arguments
  processed_args = Enum.map(args, &process_expression/1)
  {:call, [function_name, processed_args], opts}
end

def process_expression({:variable, path, opts} = expr) do
  # Variables don't need processing
  expr
end

def process_expression({:literal, [value], opts} = expr) do
  # Literals don't need processing
  expr
end

def process_expression({:binary_op, [op, left, right], opts}) do
  # Process binary operation expressions
  {:binary_op, [op, process_expression(left), process_expression(right)], opts}
end

def process_expression({:logical_op, [op, left, right], opts}) do
  # Process logical operation expressions
  {:logical_op, [op, process_expression(left), process_expression(right)], opts}
end
```

## Whitespace Control

### Applying Whitespace Trimming

```elixir
def apply_whitespace_control(nodes) do
  nodes
  |> Enum.with_index()
  |> Enum.map(fn {node, index} ->
    apply_node_whitespace(node, index, nodes)
  end)
end

def apply_node_whitespace({type, parts, opts} = node, index, all_nodes) do
  node = if opts[:trim_left] do
    trim_previous_node(node, index, all_nodes)
  else
    node
  end

  if opts[:trim_right] do
    trim_next_node(node, index, all_nodes)
  else
    node
  end
end

defp trim_previous_node(node, 0, _nodes), do: node
defp trim_previous_node(node, index, nodes) do
  case Enum.at(nodes, index - 1) do
    {:text, [content], opts} ->
      trimmed_content = String.trim_trailing(content)
      List.replace_at(nodes, index - 1, {:text, [trimmed_content], opts})
    _ ->
      node
  end
end

defp trim_next_node(node, index, nodes) do
  if index + 1 < length(nodes) do
    case Enum.at(nodes, index + 1) do
      {:text, [content], opts} ->
        trimmed_content = String.trim_leading(content)
        List.replace_at(nodes, index + 1, {:text, [trimmed_content], opts})
      _ ->
        node
    end
  else
    node
  end
end
```

## Error Handling

### Strict Mode Support

```elixir
def evaluate_with_mode(ast, context, strict_mode \\ false) do
  context = Map.put(context, :__strict_mode__, strict_mode)
  evaluate_ast(ast, context)
end

defp handle_undefined_variable(var_name, context) do
  if context[:__strict_mode__] do
    {:error, "Undefined variable: #{var_name}"}
  else
    {:ok, nil}
  end
end

defp handle_parse_error(error, context) do
  if context[:__strict_mode__] do
    {:error, "Parse error: #{error}"}
  else
    # Return original text in non-strict mode
    {:ok, "{{ #{error} }}"}
  end
end
```

## Performance Optimizations

### Context Cloning Strategy

```elixir
# Efficient context management for loops
defp create_loop_context(base_context, var_name, item, loop_metadata) do
  # Shallow copy with new variables
  base_context
  |> Map.put(var_name, item)
  |> Map.put("forloop", loop_metadata)
end

# Avoid deep cloning for assign operations
defp update_context_with_assignment(context, var_name, value) do
  Map.put(context, var_name, value)
end
```

### Memoization for Expensive Operations

```elixir
defp evaluate_with_cache(expr, context, cache_key) do
  case :ets.lookup(:template_cache, cache_key) do
    [{^cache_key, result}] -> result
    [] ->
      result = evaluate_expression(expr, context)
      :ets.insert(:template_cache, {cache_key, result})
      result
  end
end
```


## Security Considerations

### Depth Limiting

```elixir
defp check_nesting_depth(depth) when depth > 100 do
  {:error, "Maximum nesting depth exceeded"}
end
defp check_nesting_depth(_depth), do: :ok

defp check_loop_iterations(count) when count > 10_000 do
  {:error, "Maximum loop iterations exceeded"}
end
defp check_loop_iterations(_count), do: :ok
```


This implementation guide provides a complete foundation for building an efficient and secure template evaluator based on the AST specification.