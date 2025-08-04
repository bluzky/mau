defmodule Mau.AST.Nodes do
  @moduledoc """
  AST node helpers for the Mau template engine.
  
  Provides functions to create AST nodes that follow the 
  unified tuple format: `{type, parts, opts}`.
  """

  @doc """
  Creates a text node for raw text content.
  """
  def text_node(content, opts \\ []) when is_binary(content) do
    {:text, [content], opts}
  end

  @doc """
  Creates a literal node for constant values.
  """
  def literal_node(value, opts \\ []) do
    {:literal, [value], opts}
  end

  @doc """
  Creates an atom literal node for atom values.
  """
  def atom_literal_node(atom_name, opts \\ []) when is_binary(atom_name) do
    {:literal, [String.to_atom(atom_name)], opts}
  end

  @doc """
  Creates an expression node for variable interpolation.
  """
  def expression_node(expression_ast, opts \\ []) do
    {:expression, [expression_ast], opts}
  end

  @doc """
  Creates a tag node for control flow and logic.
  """
  def tag_node(tag_type, parts, opts \\ []) do
    {:tag, [tag_type | parts], opts}
  end

  @doc """
  Creates a variable node for variable access.
  """
  def variable_node(path, opts \\ []) when is_list(path) do
    {:variable, path, opts}
  end

  @doc """
  Creates a binary operation node for binary operators.
  """
  def binary_op_node(operator, left, right, opts \\ []) when is_binary(operator) do
    {:binary_op, [operator, left, right], opts}
  end

  @doc """
  Creates a logical operation node for logical operators.
  """
  def logical_op_node(operator, left, right, opts \\ []) when is_binary(operator) do
    {:logical_op, [operator, left, right], opts}
  end

  @doc """
  Creates a function call node for function calls and filters.
  """
  def call_node(function_name, args, opts \\ []) when is_binary(function_name) and is_list(args) do
    {:call, [function_name, args], opts}
  end
end