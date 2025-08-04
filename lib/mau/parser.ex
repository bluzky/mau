defmodule Mau.Parser do
  @moduledoc """
  Parser for the Mau template engine using NimbleParsec.
  
  Handles parsing of template strings into AST nodes.
  Supports plain text parsing and string literals with escape sequences.
  """

  import NimbleParsec
  alias Mau.AST.Nodes

  # ============================================================================
  # STRING LITERAL PARSING
  # ============================================================================

  # Escape sequence handling
  escaped_char =
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

  # Double-quoted string content
  double_quoted_char =
    choice([
      escaped_char,
      utf8_char([not: ?", not: ?\\])
    ])

  double_quoted_string =
    ignore(string("\""))
    |> repeat(double_quoted_char)
    |> ignore(string("\""))
    |> reduce(:build_string_from_chars)

  # Single-quoted string content  
  single_quoted_char =
    choice([
      escaped_char,
      utf8_char([not: ?', not: ?\\])
    ])

  single_quoted_string =
    ignore(string("'"))
    |> repeat(single_quoted_char)
    |> ignore(string("'"))
    |> reduce(:build_string_from_chars)

  # Combined string literal parser
  string_literal =
    choice([
      double_quoted_string,
      single_quoted_string
    ])
    |> reduce(:build_string_literal_node)

  # ============================================================================
  # NUMBER LITERAL PARSING
  # ============================================================================

  # Integer part (required for all numbers)
  integer_part =
    choice([
      string("0"),
      concat(ascii_char([?1..?9]), repeat(ascii_char([?0..?9])))
    ])

  # Fractional part for floats
  fractional_part =
    string(".")
    |> concat(times(ascii_char([?0..?9]), min: 1))

  # Exponent part for scientific notation
  exponent_part =
    choice([string("e"), string("E")])
    |> optional(choice([string("+"), string("-")]))
    |> concat(times(ascii_char([?0..?9]), min: 1))

  # Float number: integer.fractional or integer.fractionalE±exponent or integerE±exponent
  float_number =
    choice([
      # integer.fractional[E±exponent]
      integer_part
      |> concat(fractional_part)
      |> optional(exponent_part),
      # integerE±exponent (no fractional part)
      integer_part
      |> concat(exponent_part)
    ])
    |> reduce(:parse_float)

  # Integer number
  integer_number =
    integer_part
    |> reduce(:parse_integer)

  # Positive number (integer or float)
  positive_number =
    choice([
      float_number,
      integer_number
    ])

  # Number with optional negative sign
  number_literal =
    choice([
      ignore(string("-")) |> concat(positive_number) |> reduce(:negate_number),
      positive_number
    ])
    |> reduce(:build_number_literal_node)

  # ============================================================================
  # BOOLEAN AND NULL LITERAL PARSING
  # ============================================================================

  # Boolean literals - with word boundary check
  boolean_literal =
    choice([
      string("true") |> concat(lookahead_not(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))) |> replace(true),
      string("false") |> concat(lookahead_not(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))) |> replace(false)
    ])
    |> reduce(:build_boolean_literal_node)

  # Null literal - with word boundary check
  null_literal =
    string("null")
    |> concat(lookahead_not(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_])))
    |> replace(nil)
    |> reduce(:build_null_literal_node)

  # ============================================================================
  # VARIABLE PARSING
  # ============================================================================

  # Whitespace handling (moved up for use in variable parsing)
  optional_whitespace = repeat(ascii_char([?\s, ?\t, ?\n, ?\r]))

  # Identifier parsing - supports letters, numbers, underscores
  # Must start with letter or underscore, can contain numbers after first char
  identifier_start = ascii_char([?a..?z, ?A..?Z, ?_])
  identifier_char = ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_])
  
  # Basic identifier (user, name, index, etc.)
  basic_identifier =
    identifier_start
    |> repeat(identifier_char)
    |> reduce(:build_identifier)

  # Workflow variable identifier (starts with $)
  workflow_identifier =
    string("$")
    |> concat(basic_identifier)
    |> reduce(:build_workflow_identifier)

  # Combined identifier parser
  identifier =
    choice([
      workflow_identifier,
      basic_identifier
    ])

  # Property access parsing
  property_access =
    string(".")
    |> concat(basic_identifier)
    |> reduce(:build_property_access)

  # Array index parsing - supports literal numbers and simple identifiers
  array_index_content =
    choice([
      integer_number,  # Literal number index like [0], [123]
      identifier       # Simple variable index like [index], [i]
    ])

  array_index =
    ignore(string("["))
    |> ignore(optional_whitespace)
    |> concat(array_index_content)
    |> ignore(optional_whitespace)  
    |> ignore(string("]"))
    |> reduce(:build_array_index)

  # Variable access element - either property access or array index
  variable_access =
    choice([
      property_access,
      array_index
    ])

  # Variable path - identifier followed by zero or more property accesses or array indices
  variable_path =
    identifier
    |> repeat(variable_access)
    |> reduce(:build_variable_path)

  # ============================================================================
  # EXPRESSION PARSING WITH PRECEDENCE
  # ============================================================================

  # Primary expressions - literals with word boundaries, then variables
  primary_expression =
    choice([
      string_literal,
      number_literal,
      boolean_literal,
      null_literal,
      variable_path
    ])

  # Forward declare atom expression to include parentheses later
  defcombinatorp(:atom_expression,
    choice([
      primary_expression,
      ignore(string("("))
      |> ignore(optional_whitespace)
      |> parsec(:logical_or_expression)
      |> ignore(optional_whitespace)
      |> ignore(string(")"))
    ])
  )

  # Multiplicative expressions - *, /, % (highest arithmetic precedence)
  multiplicative_operator =
    choice([
      string("*"),
      string("/"),
      string("%")
    ])

  multiplicative_expression =
    parsec(:atom_expression)
    |> repeat(
      ignore(optional_whitespace)
      |> concat(multiplicative_operator)
      |> ignore(optional_whitespace)
      |> concat(parsec(:atom_expression))
    )
    |> reduce(:build_binary_operation)

  # Additive expressions - +, - (lowest arithmetic precedence)
  additive_operator =
    choice([
      string("+"),
      string("-")
    ])

  additive_expression =
    multiplicative_expression
    |> repeat(
      ignore(optional_whitespace)
      |> concat(additive_operator)
      |> ignore(optional_whitespace)
      |> concat(multiplicative_expression)
    )
    |> reduce(:build_binary_operation)

  # ============================================================================
  # COMPARISON EXPRESSION PARSING
  # ============================================================================

  # Equality operators - ==, !=
  equality_operator =
    choice([
      string("=="),
      string("!=")
    ])

  equality_expression =
    additive_expression
    |> repeat(
      ignore(optional_whitespace)
      |> concat(equality_operator)
      |> ignore(optional_whitespace)
      |> concat(additive_expression)
    )
    |> reduce(:build_binary_operation)

  # Relational operators - >, >=, <, <=
  relational_operator =
    choice([
      string(">="),
      string("<="),
      string(">"),
      string("<")
    ])

  relational_expression =
    equality_expression
    |> repeat(
      ignore(optional_whitespace)
      |> concat(relational_operator)
      |> ignore(optional_whitespace)
      |> concat(equality_expression)
    )
    |> reduce(:build_binary_operation)

  # ============================================================================
  # LOGICAL EXPRESSION PARSING
  # ============================================================================

  # Logical AND operator
  logical_and_expression =
    relational_expression
    |> repeat(
      ignore(optional_whitespace)
      |> string("and")
      |> ignore(optional_whitespace)
      |> concat(relational_expression)
    )
    |> reduce(:build_logical_operation)

  # Logical OR operator (lowest precedence)
  logical_or_expression =
    logical_and_expression
    |> repeat(
      ignore(optional_whitespace)
      |> string("or")
      |> ignore(optional_whitespace)
      |> concat(logical_and_expression)
    )
    |> reduce(:build_logical_operation)

  # ============================================================================
  # EXPRESSION BLOCK PARSING
  # ============================================================================

  # Any expression value (now supports boolean/comparison)
  expression_value = logical_or_expression

  # Expression block with {{ }} delimiters
  expression_block =
    ignore(string("{{"))
    |> ignore(optional_whitespace)
    |> concat(expression_value)
    |> ignore(optional_whitespace)
    |> ignore(string("}}"))
    |> reduce(:build_expression_node)

  # ============================================================================
  # TEXT PARSING (GROUP 1)
  # ============================================================================

  # Legacy text content parser (unused but kept for reference)

  # Combined content parser (text or expressions)
  template_content =
    choice([
      expression_block,
      utf8_string([not: ?{], min: 1) |> reduce(:build_text_node)
    ])

  # Main template parser - handles mixed content
  defparsec(:parse_template, repeat(template_content))
  
  # Parser for additive expressions (needed for recursive parsing)
  defparsec(:additive_expression, additive_expression)
  
  # Parser for logical OR expressions (needed for recursive parsing in parentheses)
  defparsec(:logical_or_expression, logical_or_expression)
  
  # Parser for testing string literals directly
  defparsec(:parse_string_literal_raw, string_literal)
  
  # Parser for testing number literals directly
  defparsec(:parse_number_literal_raw, number_literal)
  
  # Parser for testing boolean literals directly
  defparsec(:parse_boolean_literal_raw, boolean_literal)
  
  # Parser for testing null literals directly
  defparsec(:parse_null_literal_raw, null_literal)
  
  # Parser for testing expression blocks directly
  defparsec(:parse_expression_block_raw, expression_block)

  # Parser for testing identifiers directly
  defparsec(:parse_identifier_raw, identifier)

  # Parser for testing variable paths directly
  defparsec(:parse_variable_path_raw, variable_path)

  @doc """
  Parses a string literal and returns a clean result.
  
  ## Examples
  
      iex> Mau.Parser.parse_string_literal(~s("hello"))
      {:ok, {:literal, ["hello"], []}}
      
      iex> Mau.Parser.parse_string_literal("'world'")
      {:ok, {:literal, ["world"], []}}
  """
  def parse_string_literal(input) do
    case parse_string_literal_raw(input) do
      {:ok, [ast], "", _, _, _} ->
        {:ok, ast}
      {:ok, [_ast], remaining, _, _, _} ->
        {:error, "Unexpected input after string: #{remaining}"}
      {:error, reason, _remaining, _context, {line, column}, _offset} ->
        {:error, "Parse error at line #{line}, column #{column}: #{reason}"}
    end
  end

  @doc """
  Parses a number literal and returns a clean result.
  
  ## Examples
  
      iex> Mau.Parser.parse_number_literal("42")
      {:ok, {:literal, [42], []}}
      
      iex> Mau.Parser.parse_number_literal("3.14")
      {:ok, {:literal, [3.14], []}}
      
      iex> Mau.Parser.parse_number_literal("-123")
      {:ok, {:literal, [-123], []}}
  """
  def parse_number_literal(input) do
    case parse_number_literal_raw(input) do
      {:ok, [ast], "", _, _, _} ->
        {:ok, ast}
      {:ok, [_ast], remaining, _, _, _} ->
        {:error, "Unexpected input after number: #{remaining}"}
      {:error, reason, _remaining, _context, {line, column}, _offset} ->
        {:error, "Parse error at line #{line}, column #{column}: #{reason}"}
    end
  end

  @doc """
  Parses a boolean literal and returns a clean result.
  
  ## Examples
  
      iex> Mau.Parser.parse_boolean_literal("true")
      {:ok, {:literal, [true], []}}
      
      iex> Mau.Parser.parse_boolean_literal("false")
      {:ok, {:literal, [false], []}}
  """
  def parse_boolean_literal(input) do
    case parse_boolean_literal_raw(input) do
      {:ok, [ast], "", _, _, _} ->
        {:ok, ast}
      {:ok, [_ast], remaining, _, _, _} ->
        {:error, "Unexpected input after boolean: #{remaining}"}
      {:error, reason, _remaining, _context, {line, column}, _offset} ->
        {:error, "Parse error at line #{line}, column #{column}: #{reason}"}
    end
  end

  @doc """
  Parses a null literal and returns a clean result.
  
  ## Examples
  
      iex> Mau.Parser.parse_null_literal("null")
      {:ok, {:literal, [nil], []}}
  """
  def parse_null_literal(input) do
    case parse_null_literal_raw(input) do
      {:ok, [ast], "", _, _, _} ->
        {:ok, ast}
      {:ok, [_ast], remaining, _, _, _} ->
        {:error, "Unexpected input after null: #{remaining}"}
      {:error, reason, _remaining, _context, {line, column}, _offset} ->
        {:error, "Parse error at line #{line}, column #{column}: #{reason}"}
    end
  end

  @doc """
  Parses an expression block and returns a clean result.
  
  ## Examples
  
      iex> Mau.Parser.parse_expression_block(~s({{ "hello" }}))
      {:ok, {:expression, [{:literal, ["hello"], []}], []}}
      
      iex> Mau.Parser.parse_expression_block("{{42}}")
      {:ok, {:expression, [{:literal, [42], []}], []}}
      
      iex> Mau.Parser.parse_expression_block("{{ true }}")
      {:ok, {:expression, [{:literal, [true], []}], []}}
  """
  def parse_expression_block(input) do
    case parse_expression_block_raw(input) do
      {:ok, [ast], "", _, _, _} ->
        {:ok, ast}
      {:ok, [_ast], remaining, _, _, _} ->
        {:error, "Unexpected input after expression block: #{remaining}"}
      {:error, reason, _remaining, _context, {line, column}, _offset} ->
        {:error, "Parse error at line #{line}, column #{column}: #{reason}"}
    end
  end

  @doc """
  Parses an identifier and returns a clean result.
  
  ## Examples
  
      iex> Mau.Parser.parse_identifier("user")
      {:ok, "user"}
      
      iex> Mau.Parser.parse_identifier("$input")
      {:ok, "$input"}
      
      iex> Mau.Parser.parse_identifier("user_name")
      {:ok, "user_name"}
  """
  def parse_identifier(input) do
    case parse_identifier_raw(input) do
      {:ok, [identifier], "", _, _, _} ->
        {:ok, identifier}
      {:ok, [_identifier], remaining, _, _, _} ->
        {:error, "Unexpected input after identifier: #{remaining}"}
      {:error, reason, _remaining, _context, {line, column}, _offset} ->
        {:error, "Parse error at line #{line}, column #{column}: #{reason}"}
    end
  end

  @doc """
  Parses a variable path and returns a clean result.
  
  ## Examples
  
      iex> Mau.Parser.parse_variable_path("user")
      {:ok, {:variable, ["user"], []}}
      
      iex> Mau.Parser.parse_variable_path("user.name")
      {:ok, {:variable, ["user", {:property, "name"}], []}}
      
      iex> Mau.Parser.parse_variable_path("$input.data.field")
      {:ok, {:variable, ["$input", {:property, "data"}, {:property, "field"}], []}}
  """
  def parse_variable_path(input) do
    case parse_variable_path_raw(input) do
      {:ok, [path_segments], "", _, _, _} ->
        {:ok, path_segments}
      {:ok, [_path_segments], remaining, _, _, _} ->
        {:error, "Unexpected input after variable path: #{remaining}"}
      {:error, reason, _remaining, _context, {line, column}, _offset} ->
        {:error, "Parse error at line #{line}, column #{column}: #{reason}"}
    end
  end

  @doc """
  Parses a template string into an AST.
  
  Now handles mixed content: text and expression blocks.
  
  ## Examples
  
      iex> Mau.Parser.parse("Hello world")
      {:ok, [{:text, ["Hello world"], []}]}
      
      iex> Mau.Parser.parse("")
      {:ok, []}
      
      iex> Mau.Parser.parse(~s(Hello {{ "world" }}!))
      {:ok, [{:text, ["Hello "], []}, {:expression, [{:literal, ["world"], []}], []}, {:text, ["!"], []}]}
  """
  def parse(template) when is_binary(template) do
    case parse_template(template) do
      {:ok, nodes, "", _, _, _} ->
        {:ok, nodes}
      {:ok, _nodes, _remaining, _, _, _} ->
        # If there's remaining unparsed content, treat it as text
        case parse_template(template) do
          {:ok, parsed_nodes, "", _, _, _} ->
            {:ok, parsed_nodes}
          _ ->
            # Fallback: treat entire template as text if parsing fails
            {:ok, [Nodes.text_node(template)]}
        end
      {:error, reason, _remaining, _context, {line, column}, _offset} ->
        error = Mau.Error.syntax_error("Parse error: #{reason}", line: line, column: column)
        {:error, error}
    end
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
    string_value = parts 
    |> List.flatten() 
    |> :binary.list_to_bin()
    
    case Float.parse(string_value) do
      {float_val, ""} -> float_val
      {float_val, _rest} -> float_val
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

  # Text node helpers
  defp build_text_node([content]) do
    Nodes.text_node(content)
  end


  # Boolean and null literal helpers
  defp build_boolean_literal_node([boolean_value]) when is_boolean(boolean_value) do
    Nodes.literal_node(boolean_value)
  end

  defp build_null_literal_node([nil]) do
    Nodes.literal_node(nil)
  end

  # Expression block helpers
  defp build_expression_node([expression_ast]) do
    Nodes.expression_node(expression_ast)
  end

  # Variable identifier helpers
  defp build_identifier(chars) do
    chars |> List.to_string()
  end

  defp build_workflow_identifier(["$", identifier]) do
    "$" <> identifier
  end

  # Property access helpers
  defp build_property_access([".", property]) do
    {:property, property}
  end

  # Array index helpers
  defp build_array_index([index]) do
    {:index, index}
  end

  # Variable path helpers
  defp build_variable_path([identifier | accesses]) do
    path_segments = [identifier | accesses]
    Nodes.variable_node(path_segments)
  end

  # Arithmetic expression helpers
  defp build_binary_operation([left]) do
    # Single operand, no operation
    left
  end

  defp build_binary_operation([left | rest]) do
    # Build left-associative binary operations
    build_left_associative_ops(left, rest)
  end

  defp build_left_associative_ops(left, []) do
    left
  end

  defp build_left_associative_ops(left, [operator, right | rest]) do
    binary_op = Nodes.binary_op_node(operator, left, right)
    build_left_associative_ops(binary_op, rest)
  end

  # Logical operation helpers
  defp build_logical_operation([left]) do
    # Single operand, no operation
    left
  end

  defp build_logical_operation([left | rest]) do
    # Build left-associative logical operations
    build_left_associative_logical_ops(left, rest)
  end

  defp build_left_associative_logical_ops(left, []) do
    left
  end

  defp build_left_associative_logical_ops(left, [operator, right | rest]) do
    logical_op = Nodes.logical_op_node(operator, left, right)
    build_left_associative_logical_ops(logical_op, rest)
  end
end