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
  alias Mau.AST.Nodes

  # ============================================================================
  # WHITESPACE HANDLING
  # ============================================================================

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

  # ============================================================================
  # STRING LITERAL PARSING
  # ============================================================================

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
      |> concat(lookahead_not(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_])))
      |> replace(true),
      string("false")
      |> concat(lookahead_not(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_])))
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
    |> concat(lookahead_not(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_])))
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

  # String literal helpers
  defp parse_unicode_escape(["u", d1, d2, d3, d4]) do
    hex_string = <<d1, d2, d3, d4>>
    {code_point, ""} = Integer.parse(hex_string, 16)
    <<code_point::utf8>>
  end

  defp build_string_from_chars(chars) do
    chars |> List.to_string()
  end

  defp build_string_literal_node([string_value]) do
    Nodes.literal_node(string_value)
  end

  # Number literal helpers
  defp parse_integer(digits) do
    digits
    |> List.flatten()
    |> :binary.list_to_bin()
    |> String.to_integer()
  end

  defp parse_float(parts) do
    string_value =
      parts
      |> List.flatten()
      |> :binary.list_to_bin()

    case Float.parse(string_value) do
      {float_val, ""} ->
        float_val

      {float_val, _rest} ->
        float_val

      :error ->
        # This should never happen with valid NimbleParsec input, but if it does,
        # we should raise an error rather than silently convert to 0.0
        raise "Invalid float string encountered in parser: #{inspect(string_value)}"
    end
  end

  defp negate_number([number]) when is_number(number) do
    -number
  end

  defp build_number_literal_node([number_value]) when is_number(number_value) do
    Nodes.literal_node(number_value)
  end

  # Boolean and null literal helpers
  defp build_boolean_literal_node([boolean_value]) when is_boolean(boolean_value) do
    Nodes.literal_node(boolean_value)
  end

  defp build_null_literal_node([nil]) do
    Nodes.literal_node(nil)
  end

  # Atom literal helpers
  defp build_atom_literal([":" | atom_chars]) do
    atom_name = atom_chars |> List.to_string()
    Nodes.atom_literal_node(atom_name)
  end
end