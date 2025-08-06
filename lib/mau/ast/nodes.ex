defmodule Mau.AST.Nodes do
  @moduledoc """
  AST node helpers for the Mau template engine.

  Provides functions to create AST nodes that follow the 
  unified tuple format: `{type, parts, opts}`.
  """

  @doc """
  Creates a text node for raw text content.
  """
  @compile {:inline, text_node: 1, text_node: 2}
  def text_node(content, opts \\ []) when is_binary(content) do
    {:text, [content], opts}
  end

  @doc """
  Creates a literal node for constant values.
  """
  @compile {:inline, literal_node: 1, literal_node: 2}
  def literal_node(value, opts \\ []) do
    {:literal, [value], opts}
  end

  @doc """
  Creates an atom literal node for atom values.
  """
  @compile {:inline, atom_literal_node: 1, atom_literal_node: 2}
  def atom_literal_node(atom_name, opts \\ []) when is_binary(atom_name) do
    {:literal, [String.to_atom(atom_name)], opts}
  end

  @doc """
  Creates an expression node for variable interpolation.
  """
  @compile {:inline, expression_node: 1, expression_node: 2}
  def expression_node(expression_ast, opts \\ []) do
    {:expression, [expression_ast], opts}
  end

  @doc """
  Creates a tag node for control flow and logic.
  """
  @compile {:inline, tag_node: 2, tag_node: 3}
  def tag_node(tag_type, parts, opts \\ []) do
    {:tag, [tag_type | parts], opts}
  end

  @doc """
  Creates a variable node for variable access.
  """
  @compile {:inline, variable_node: 1, variable_node: 2}
  def variable_node(path, opts \\ []) when is_list(path) do
    {:variable, path, opts}
  end

  @doc """
  Creates a binary operation node for binary operators.
  """
  @compile {:inline, binary_op_node: 3, binary_op_node: 4}
  def binary_op_node(operator, left, right, opts \\ []) when is_binary(operator) do
    {:binary_op, [operator, left, right], opts}
  end

  @doc """
  Creates a logical operation node for logical operators.
  """
  @compile {:inline, logical_op_node: 3, logical_op_node: 4}
  def logical_op_node(operator, left, right, opts \\ []) when is_binary(operator) do
    {:logical_op, [operator, left, right], opts}
  end

  @doc """
  Creates a function call node for function calls and filters.
  """
  @compile {:inline, call_node: 2, call_node: 3}
  def call_node(function_name, args, opts \\ [])
      when is_binary(function_name) and is_list(args) do
    {:call, [function_name, args], opts}
  end

  @doc """
  Creates a comment node for template comments.
  Comments are not rendered in the final output.
  """
  @compile {:inline, comment_node: 1, comment_node: 2}
  def comment_node(content, opts \\ []) when is_binary(content) do
    {:comment, [content], opts}
  end

  @doc """
  Creates a unary operation node for unary operators like 'not'.
  """
  @compile {:inline, unary_op_node: 2, unary_op_node: 3}
  def unary_op_node(operator, operand, opts \\ []) when is_binary(operator) do
    {:unary_op, [operator, operand], opts}
  end
end
