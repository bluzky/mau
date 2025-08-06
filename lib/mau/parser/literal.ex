defmodule Mau.Parser.Literal do
  @moduledoc """
  Literal value parsing for the Mau template engine.

  Handles parsing of:
  - String literals with escape sequences
  - Number literals (integers, floats, scientific notation)
  - Boolean literals (true, false)
  - Null literals (null)
  - Atom literals (:atom_name)
  - Whitespace parsing utilities
  """

  import NimbleParsec

  @doc """
  Parses optional whitespace (spaces, tabs, newlines, carriage returns).
  """
  def optional_whitespace do
    repeat(ascii_char([?\s, ?\t, ?\n, ?\r]))
  end

  @doc """
  Parses required whitespace (at least one space or tab).
  """
  def required_whitespace do
    times(ascii_char([?\s, ?\t]), min: 1)
  end

  # Escape sequence handling
  defp escaped_char do
    ignore(string("\\"))
    |> choice([
      string("\"") |> replace(?"),
      string("'") |> replace(?'),
      string("\\") |> replace(?\\),
      string("/") |> replace(?/),
      string("b") |> replace(?\b),
      string("f") |> replace(?\f),
      string("n") |> replace(?\n),
      string("r") |> replace(?\r),
      string("t") |> replace(?\t),
      # Unicode escape sequences \uXXXX
      string("u")
      |> concat(times(ascii_char([?0..?9, ?A..?F, ?a..?f]), 4))
      |> reduce(:parse_unicode_escape)
    ])
  end

  # Double-quoted string content
  defp double_quoted_char do
    choice([
      escaped_char(),
      utf8_char(not: ?", not: ?\\)
    ])
  end

  defp double_quoted_string do
    ignore(string("\""))
    |> repeat(double_quoted_char())
    |> ignore(string("\""))
    |> reduce(:build_string_from_chars)
  end

  # Single-quoted string content
  defp single_quoted_char do
    choice([
      escaped_char(),
      utf8_char(not: ?', not: ?\\)
    ])
  end

  defp single_quoted_string do
    ignore(string("'"))
    |> repeat(single_quoted_char())
    |> ignore(string("'"))
    |> reduce(:build_string_from_chars)
  end

  @doc """
  Parses string literals with single or double quotes.

  Supports escape sequences including Unicode.

  ## Examples

      * `"hello world"`
      * `'single quoted'`
      * `"escaped \\"quotes\\""`
      * `"unicode \\u0041"`
  """
  def string_literal do
    choice([
      double_quoted_string(),
      single_quoted_string()
    ])
    |> reduce(:build_string_literal_node)
  end

  # ============================================================================
  # NUMBER LITERAL PARSING
  # ============================================================================

  # Integer part (required for all numbers)
  defp integer_part do
    choice([
      string("0"),
      concat(ascii_char([?1..?9]), repeat(ascii_char([?0..?9])))
    ])
  end

  # Fractional part for floats
  defp fractional_part do
    string(".")
    |> concat(times(ascii_char([?0..?9]), min: 1))
  end

  # Exponent part for scientific notation
  defp exponent_part do
    choice([string("e"), string("E")])
    |> optional(choice([string("+"), string("-")]))
    |> concat(times(ascii_char([?0..?9]), min: 1))
  end

  # Float number: integer.fractional or integer.fractionalE±exponent or integerE±exponent
  defp float_number do
    choice([
      # integer.fractional[E±exponent]
      integer_part()
      |> concat(fractional_part())
      |> optional(exponent_part()),
      # integerE±exponent (no fractional part)
      integer_part()
      |> concat(exponent_part())
    ])
    |> reduce(:parse_float)
  end

  # Integer number
  defp integer_number do
    integer_part()
    |> reduce(:parse_integer)
  end

  # Positive number (integer or float)
  defp positive_number do
    choice([
      float_number(),
      integer_number()
    ])
  end

  @doc """
  Parses number literals including integers, floats, and scientific notation.

  Supports negative numbers.

  ## Examples

      * `42`
      * `3.14`
      * `-123`
      * `1.23e-4`
      * `42E+10`
  """
  def number_literal do
    choice([
      ignore(string("-")) |> concat(positive_number()) |> reduce(:negate_number),
      positive_number()
    ])
    |> reduce(:build_number_literal_node)
  end

  # ============================================================================
  # BOOLEAN AND NULL LITERAL PARSING
  # ============================================================================

  @doc """
  Parses boolean literals with word boundary checking.

  ## Examples

      * `true`
      * `false`
  """
  def boolean_literal do
    choice([
      string("true")
      |> lookahead_not(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))
      |> replace(true),
      string("false")
      |> lookahead_not(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))
      |> replace(false)
    ])
    |> reduce(:build_boolean_literal_node)
  end

  @doc """
  Parses null literal with word boundary checking.

  ## Examples

      * `null`
  """
  def null_literal do
    string("null")
    |> lookahead_not(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))
    |> replace(nil)
    |> reduce(:build_null_literal_node)
  end

  @doc """
  Parses atom literals.

  ## Examples

      * `:atom_name`
      * `:key`
  """
  def atom_literal do
    string(":")
    |> concat(ascii_char([?a..?z, ?A..?Z, ?_]))
    |> repeat(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))
    |> reduce(:build_atom_literal)
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  # Note: Helper functions removed to eliminate unused function warnings
  # These were originally intended for more complex literal processing features
end
