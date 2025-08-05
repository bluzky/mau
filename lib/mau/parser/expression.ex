defmodule Mau.Parser.Expression do
  @moduledoc """
  Expression parsing for the Mau template engine.

  Handles parsing of:
  - Primary expressions (literals and variables)
  - Arithmetic operators (multiplicative, additive)
  - Comparison operators (equality, relational)
  - Logical operators (and, or, unary)
  """

  import NimbleParsec

  # ============================================================================
  # PRIMARY EXPRESSION PARSING
  # ============================================================================

  # Note: primary_expression parsing involves complex circular dependencies
  # with variable_path and is kept in the main parser for now

  # ============================================================================
  # OPERATOR DEFINITIONS
  # ============================================================================

  @doc """
  Multiplicative operators - *, /, % (highest arithmetic precedence).
  """
  def multiplicative_operator do
    choice([
      string("*"),
      string("/"),
      string("%")
    ])
  end

  @doc """
  Additive operators - +, - (lowest arithmetic precedence).
  """
  def additive_operator do
    choice([
      string("+"),
      string("-")
    ])
  end

  @doc """
  Equality operators - ==, !=.
  """
  def equality_operator do
    choice([
      string("=="),
      string("!=")
    ])
  end

  @doc """
  Relational operators - >, >=, <, <=.
  """
  def relational_operator do
    choice([
      string(">="),
      string("<="),
      string(">"),
      string("<")
    ])
  end

  # Note: Helper functions for expression building remain in the main parser
  # due to NimbleParsec's compilation model requiring helpers to be in the
  # same module as the combinators that use them
end