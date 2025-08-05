defmodule Mau.Parser do
  @moduledoc """
  Parser for the Mau template engine using NimbleParsec.

  Handles parsing of template strings into AST nodes.
  Supports plain text parsing and string literals with escape sequences.
  """

  import NimbleParsec
  alias Mau.AST.Nodes
  alias Mau.Parser.Literal
  alias Mau.Parser.Variable

  # ============================================================================
  # LITERAL PARSING (DELEGATED TO LITERAL MODULE)
  # ============================================================================

  # Use the Literal module for all literal parsing
  string_literal = Literal.string_literal()

  number_literal = Literal.number_literal()

  boolean_literal = Literal.boolean_literal()
  null_literal = Literal.null_literal()

  # ============================================================================
  # VARIABLE PARSING (DELEGATED TO VARIABLE MODULE)
  # ============================================================================

  # Whitespace handling (delegated to Literal module)
  optional_whitespace = Literal.optional_whitespace()
  required_whitespace = Literal.required_whitespace()

  # Use the Variable module for identifier parsing
  identifier = Variable.identifier()

  # Keep internal identifier helpers for combinator use
  identifier_start = ascii_char([?a..?z, ?A..?Z, ?_])
  identifier_char = ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_])

  # Basic identifier (user, name, index, etc.) - kept for internal combinator use
  basic_identifier =
    identifier_start
    |> repeat(identifier_char)
    |> reduce(:build_identifier)

  # Workflow variable identifier (starts with $) - kept for internal combinator use
  workflow_identifier =
    string("$")
    |> concat(basic_identifier)
    |> reduce(:build_workflow_identifier)

  # Atom literal - :atom_name (delegated to Literal module)
  atom_literal = Literal.atom_literal()

  # Keep internal property access and array index parsing for combinator use
  property_access =
    string(".")
    |> concat(basic_identifier)
    |> reduce(:build_property_access)

  # Array index parsing - supports literals and variable expressions (forward declared)
  array_index =
    ignore(string("["))
    |> ignore(optional_whitespace)
    |> parsec(:array_index_content)
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

  # Array index content - now that variable_path is defined
  defcombinatorp(
    :array_index_content,
    choice([
      # Literal number index like [0], [123], [-1]
      number_literal,
      # Literal string key like ["key"], ["name"]
      string_literal,
      # Literal atom key like [:key], [:name]
      atom_literal,
      # Variable expression like [key], [index], [user.id]
      variable_path
    ])
  )

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
      atom_literal,
      variable_path
    ])

  # Forward declare atom expression to include parentheses and function calls
  # We avoid circular dependencies by using additive_expression instead of logical_or_expression
  defcombinatorp(
    :atom_expression,
    choice([
      # Function call syntax: func(arg1, arg2) - must come before primary_expression
      basic_identifier
      |> ignore(optional_whitespace)
      |> ignore(string("("))
      |> ignore(optional_whitespace)
      |> optional(parsec(:argument_list))
      |> ignore(optional_whitespace)
      |> ignore(string(")"))
      |> reduce(:build_function_call),

      # Parentheses with full expression support
      ignore(string("("))
      |> ignore(optional_whitespace)
      # Use pipe_expression for full expression support in parentheses
      |> parsec(:pipe_expression)
      |> ignore(optional_whitespace)
      |> ignore(string(")")),
      primary_expression
    ])
  )

  # ============================================================================
  # FUNCTION CALL AND FILTER PARSING
  # ============================================================================

  # Argument list for function calls - uses primary expressions to avoid circular dependencies
  defcombinatorp(
    :argument_list,
    primary_expression
    |> repeat(
      ignore(optional_whitespace)
      |> ignore(string(","))
      |> ignore(optional_whitespace)
      |> concat(primary_expression)
    )
    |> reduce(:build_argument_list)
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
  # UNARY EXPRESSION PARSING
  # ============================================================================

  # Unary expressions - not
  unary_expression =
    choice([
      # not expression - must use lookahead to ensure word boundary
      string("not")
      |> lookahead_not(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))
      |> ignore(required_whitespace)
      |> concat(parsec(:unary_expression))
      |> reduce(:build_unary_operation),

      # No unary operator
      relational_expression
    ])

  # ============================================================================
  # LOGICAL EXPRESSION PARSING
  # ============================================================================

  # Logical AND operator
  logical_and_expression =
    unary_expression
    |> repeat(
      ignore(optional_whitespace)
      |> string("and")
      |> ignore(optional_whitespace)
      |> concat(unary_expression)
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
  # TAG BLOCK PARSING
  # ============================================================================
  # 
  # Generic tag parsing infrastructure designed to minimize boilerplate when adding new tags.
  # 
  # To add a new tag type:
  # 1. Create a combinator following the existing patterns
  # 2. Add it to the `tag_content` choice list
  # 3. Add a case clause to `build_tag/2` for the tag's argument structure
  # 4. Add a case clause to `build_tag_node/1` for AST construction (or use generic fallback)
  # 5. Add rendering logic to `render_tag_with_context/3` in the renderer
  #
  # Example for a new "include" tag: {% include "template.html" %}
  #   include_tag = 
  #     ignore(string("include"))
  #     |> ignore(required_whitespace)
  #     |> concat(string_literal)
  #     |> reduce({:build_tag, [:include]})

  # Generic tag parser helpers - combinators for common patterns

  # Assignment tag parsing - {% assign variable = expression %}
  assign_tag =
    ignore(string("assign"))
    |> ignore(required_whitespace)
    |> concat(basic_identifier)
    |> ignore(optional_whitespace)
    |> ignore(string("="))
    |> ignore(optional_whitespace)
    |> concat(parsec(:pipe_expression))
    |> reduce({:build_tag, [:assign]})

  # If tag parsing - {% if condition %}
  if_tag =
    ignore(string("if"))
    |> ignore(required_whitespace)
    |> concat(parsec(:pipe_expression))
    |> reduce({:build_tag, [:if]})

  # Elsif tag parsing - {% elsif condition %}
  elsif_tag =
    ignore(string("elsif"))
    |> ignore(required_whitespace)
    |> concat(parsec(:pipe_expression))
    |> reduce({:build_tag, [:elsif]})

  # Else tag parsing - {% else %}
  else_tag =
    ignore(string("else"))
    |> reduce({:build_tag, [:else]})

  # Endif tag parsing - {% endif %}
  endif_tag =
    ignore(string("endif"))
    |> reduce({:build_tag, [:endif]})

  # For tag parsing - {% for item in collection %}
  for_tag =
    ignore(string("for"))
    |> ignore(required_whitespace)
    |> concat(basic_identifier)
    |> ignore(required_whitespace)
    |> ignore(string("in"))
    |> ignore(required_whitespace)
    |> concat(parsec(:pipe_expression))
    |> reduce({:build_tag, [:for]})

  # Endfor tag parsing - {% endfor %}
  endfor_tag =
    ignore(string("endfor"))
    |> reduce({:build_tag, [:endfor]})

  # Tag content - assignment, conditional, and loop tags
  tag_content =
    choice([
      assign_tag,
      if_tag,
      elsif_tag,
      else_tag,
      endif_tag,
      for_tag,
      endfor_tag
    ])

  # Tag block with {% %} delimiters (with optional trim)
  # Ordered by specificity to avoid ambiguous matches
  tag_block =
    choice([
      # Both trim: {%- tag -%} (most specific - must come first)
      ignore(string("{%-"))
      |> ignore(optional_whitespace)
      |> concat(tag_content)
      |> ignore(optional_whitespace)
      |> ignore(string("-%}"))
      |> reduce({:build_tag_node_with_trim, [:both_trim]}),

      # Left trim: {%- tag %}
      ignore(string("{%-"))
      |> ignore(optional_whitespace)
      |> concat(tag_content)
      |> ignore(optional_whitespace)
      |> ignore(string("%}"))
      |> reduce({:build_tag_node_with_trim, [:left_trim]}),

      # Right trim: {% tag -%}
      ignore(string("{%"))
      |> ignore(optional_whitespace)
      |> concat(tag_content)
      |> ignore(optional_whitespace)
      |> ignore(string("-%}"))
      |> reduce({:build_tag_node_with_trim, [:right_trim]}),

      # No trim: {% tag %}
      ignore(string("{%"))
      |> ignore(optional_whitespace)
      |> concat(tag_content)
      |> ignore(optional_whitespace)
      |> ignore(string("%}"))
      |> reduce({:build_tag_node_with_trim, [:no_trim]})
    ])

  # ============================================================================
  # COMMENT BLOCK PARSING
  # ============================================================================

  # Comment content - anything up to #}
  comment_content =
    repeat(
      choice([
        # Match # that's not followed by }
        string("#") |> lookahead_not(string("}")),
        # Match anything that's not #
        utf8_char(not: ?#)
      ])
    )
    |> reduce(:build_comment_content)

  # Comment block with {# #} delimiters
  comment_block =
    ignore(string("{#"))
    |> concat(comment_content)
    |> ignore(string("#}"))
    |> reduce(:build_comment_node)

  # ============================================================================
  # EXPRESSION BLOCK PARSING
  # ============================================================================

  # Pipe filter - can be either a simple identifier or a function call
  pipe_filter =
    choice([
      # Function call syntax: filter(arg1, arg2)
      basic_identifier
      |> ignore(optional_whitespace)
      |> ignore(string("("))
      |> ignore(optional_whitespace)
      |> optional(parsec(:argument_list))
      |> ignore(optional_whitespace)
      |> ignore(string(")"))
      |> reduce(:build_pipe_function_call),

      # Simple identifier: filter
      basic_identifier
    ])

  # Forward declare pipe expression to break circular dependency
  defcombinatorp(
    :pipe_expression,
    logical_or_expression
    |> repeat(
      ignore(optional_whitespace)
      |> ignore(string("|"))
      |> ignore(optional_whitespace)
      |> concat(pipe_filter)
    )
    |> reduce(:build_pipe_expression)
  )

  # Any expression value (now supports pipes)
  expression_value = parsec(:pipe_expression)

  # Expression block with {{ }} delimiters (with optional trim)
  # Ordered by specificity to avoid ambiguous matches
  expression_block =
    choice([
      # Both trim: {{- expr -}} (most specific - must come first)
      ignore(string("{{-"))
      |> ignore(optional_whitespace)
      |> concat(expression_value)
      |> ignore(optional_whitespace)
      |> ignore(string("-}}"))
      |> reduce({:build_expression_node_with_trim, [:both_trim]}),

      # Left trim: {{- expr }}
      ignore(string("{{-"))
      |> ignore(optional_whitespace)
      |> concat(expression_value)
      |> ignore(optional_whitespace)
      |> ignore(string("}}"))
      |> reduce({:build_expression_node_with_trim, [:left_trim]}),

      # Right trim: {{ expr -}}
      ignore(string("{{"))
      |> ignore(optional_whitespace)
      |> concat(expression_value)
      |> ignore(optional_whitespace)
      |> ignore(string("-}}"))
      |> reduce({:build_expression_node_with_trim, [:right_trim]}),

      # No trim: {{ expr }}
      ignore(string("{{"))
      |> ignore(optional_whitespace)
      |> concat(expression_value)
      |> ignore(optional_whitespace)
      |> ignore(string("}}"))
      |> reduce({:build_expression_node_with_trim, [:no_trim]})
    ])

  # ============================================================================
  # TEXT PARSING (GROUP 1)
  # ============================================================================

  # Legacy text content parser (unused but kept for reference)

  # Text content that handles { characters not part of template constructs
  text_content =
    choice([
      # Text that doesn't contain any { characters  
      utf8_string([not: ?{], min: 1),
      # Handle { character that's not part of a template construct
      string("{")
      |> lookahead_not(choice([string("%"), string("{"), string("#")]))
      |> concat(repeat(utf8_char(not: ?{)))
      |> reduce(:join_chars)
    ])
    |> reduce(:build_text_node)

  # Combined content parser (text, expressions, tags, or comments)
  template_content =
    choice([
      comment_block,
      tag_block,
      expression_block,
      text_content
    ])

  # Main template parser - handles mixed content
  defparsec(:parse_template, repeat(template_content))

  # Parser for additive expressions (needed for recursive parsing)
  defparsec(:additive_expression, additive_expression)

  # Parser for logical OR expressions (needed for recursive parsing in parentheses)
  defparsec(:logical_or_expression, logical_or_expression)

  # Parser for unary expressions (needed for recursive parsing)
  defparsec(:unary_expression, unary_expression)

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

  # String literal helpers (kept for internal combinator use)
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

  # Number literal helpers (kept for internal combinator use)
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

  # Boolean and null literal helpers (kept for internal combinator use)
  defp build_boolean_literal_node([boolean_value]) when is_boolean(boolean_value) do
    Nodes.literal_node(boolean_value)
  end

  defp build_null_literal_node([nil]) do
    Nodes.literal_node(nil)
  end

  # Atom literal helpers (kept for internal combinator use)
  defp build_atom_literal([":" | atom_chars]) do
    atom_name = atom_chars |> List.to_string()
    Nodes.atom_literal_node(atom_name)
  end

  # Text node helpers
  defp join_chars(chars) when is_list(chars) do
    :binary.list_to_bin(chars)
  end

  defp build_text_node([content]) do
    Nodes.text_node(content)
  end


  # Unified trim handler for expression nodes
  defp build_expression_node_with_trim([expression_ast], trim_variant) do
    trim_opts = build_trim_opts(trim_variant)
    Nodes.expression_node(expression_ast, trim_opts)
  end

  # Helper to convert trim variant atoms to keyword lists
  defp build_trim_opts(trim_variant) do
    case trim_variant do
      [:both_trim] -> [trim_left: true, trim_right: true]
      [:left_trim] -> [trim_left: true]
      [:right_trim] -> [trim_right: true]
      [:no_trim] -> []
      # Handle cases where the atom comes directly (legacy compatibility)
      :both_trim -> [trim_left: true, trim_right: true]
      :left_trim -> [trim_left: true]
      :right_trim -> [trim_right: true]
      :no_trim -> []
    end
  end

  # Comment node builders
  defp build_comment_content(chars) do
    IO.iodata_to_binary(chars)
  end

  defp build_comment_node([content]) do
    Nodes.comment_node(content, [])
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

  # Unary operation helpers
  defp build_unary_operation(["not", operand]) do
    Nodes.unary_op_node("not", operand)
  end

  # Function call helpers
  defp build_function_call([function_name | args]) do
    argument_list =
      case args do
        [arg_list] -> arg_list
        [] -> []
      end

    Nodes.call_node(function_name, argument_list)
  end

  defp build_argument_list([first_arg | rest_args]) do
    [first_arg | rest_args]
  end

  # Pipe function call helpers
  defp build_pipe_function_call([function_name | args]) do
    argument_list =
      case args do
        [arg_list] -> arg_list
        [] -> []
      end

    # Return a tuple that indicates this is a function call with arguments
    {:pipe_function_call, function_name, argument_list}
  end

  # Pipe expression helpers
  defp build_pipe_expression([value]) do
    # No pipes, return the value as-is
    value
  end

  defp build_pipe_expression([value | filters]) do
    # Apply filters from left to right using nested call nodes
    apply_filters_to_value(value, filters)
  end

  defp apply_filters_to_value(value, []) do
    value
  end

  defp apply_filters_to_value(value, [filter | rest_filters]) do
    call_node =
      case filter do
        {:pipe_function_call, function_name, args} ->
          # Function call with arguments: value | filter(arg1, arg2)
          # The value becomes the first argument
          Nodes.call_node(function_name, [value | args])

        filter_name when is_binary(filter_name) ->
          # Simple filter: value | filter
          Nodes.call_node(filter_name, [value])
      end

    apply_filters_to_value(call_node, rest_filters)
  end

  # Generic tag builder helpers
  defp build_tag(args, tag_type) do
    case {tag_type, args} do
      # Assignment tag: {% assign var = expr %}
      {:assign, [variable_name, expression]} ->
        {:assign, variable_name, expression}

      # Conditional tags with expressions: {% if condition %}, {% elsif condition %}
      {tag_type, [condition]} when tag_type in [:if, :elsif] ->
        {tag_type, condition}

      # Conditional tags without parameters: {% else %}, {% endif %}
      {tag_type, []} when tag_type in [:else, :endif] ->
        {tag_type}

      # For loop tag: {% for item in collection %}
      {:for, [loop_variable, collection_expression]} ->
        {:for, loop_variable, collection_expression}

      # Loop termination tag: {% endfor %}
      {:endfor, []} ->
        {:endfor}

      # Fallback for unknown patterns
      {tag_type, args} ->
        {tag_type, args}
    end
  end

  # Unified trim handler for tag nodes
  defp build_tag_node_with_trim([tag_data], trim_variant) do
    trim_opts = build_trim_opts(trim_variant)

    case tag_data do
      {:assign, variable_name, expression} ->
        Nodes.tag_node(:assign, [variable_name, expression], trim_opts)

      {tag_type, condition} when tag_type in [:if, :elsif] ->
        Nodes.tag_node(tag_type, [condition], trim_opts)

      {tag_type} when tag_type in [:else, :endif, :endfor] ->
        Nodes.tag_node(tag_type, [], trim_opts)

      {:for, loop_variable, collection_expression} ->
        Nodes.tag_node(:for, [loop_variable, collection_expression], trim_opts)

      # Generic fallback for future tag types
      {tag_type, params} when is_list(params) ->
        Nodes.tag_node(tag_type, params, trim_opts)

      {tag_type, param} ->
        Nodes.tag_node(tag_type, [param], trim_opts)
    end
  end
end
