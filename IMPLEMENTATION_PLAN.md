# Mau Template Engine Implementation Plan

## Overview

This document outlines the detailed implementation plan for the Mau template engine, which supports the Prana template language syntax. The engine will provide three main public methods with comprehensive error handling and performance optimization.

## Public API Design

### 1. `Mau.compile/2`

**Signature:**
```elixir
@spec compile(template :: String.t(), opts :: keyword()) :: 
  {:ok, ast :: term()} | 
  {:ok, ast :: term(), warnings :: [term()]} |
  {:error, error_details :: term()}
```

**Options:**
- `:strict_mode` - boolean, default `false`
- `:trim_blocks` - boolean, default `false`
- `:lstrip_blocks` - boolean, default `false`

**Behavior:**
- **Ease mode** (`strict_mode: false`): Return `{:ok, ast, warnings}` with warnings for incomplete/malformed expressions
- **Strict mode** (`strict_mode: true`): Return `{:ok, ast, []}` for valid templates, `{:error, details}` for any syntax errors
- Parse template string into AST following the specification in `docs/template_ast_specification.md`

### 2. `Mau.render/3`

**Signature:**
```elixir
@spec render(template :: String.t() | ast :: term(), context :: map(), opts :: keyword()) :: 
  {:ok, result :: String.t() | term()} | 
  {:error, error_details :: term()}
```

**Behavior:**
- Accept either template string or pre-compiled AST
- **Pure expression** (`{{ exp }}`): Return `{:ok, evaluated_value}`
- **Mixed content**: Return `{:ok, rendered_string}`
- Handle variable interpolation, control flow, and filters

### 3. `Mau.render_map/3`

**Signature:**
```elixir
@spec render_map(nested_map :: map(), context :: map(), opts :: keyword()) :: 
  {:ok, result_map :: map()} | 
  {:error, error_details :: term()}
```

**Behavior:**
- Recursively traverse nested map structure
- Render any string values that contain template syntax
- Leave non-template strings unchanged
- Preserve map structure and non-string values

## Implementation Architecture

### Phase 1: Core Infrastructure (Week 1-2)

#### 1.1 Project Structure
```
lib/
├── mau.ex                           # Main public API
├── mau/
│   ├── lexer.ex                     # Tokenization
│   ├── parser.ex                    # AST generation
│   ├── evaluator.ex                 # Expression evaluation
│   ├── renderer.ex                  # Template rendering
│   ├── filter_registry.ex           # Filter system
│   ├── ast/
│   │   ├── nodes.ex                 # AST node helpers
│   │   └── validator.ex             # AST validation
│   ├── filters/
│   │   ├── string_filters.ex
│   │   ├── number_filters.ex
│   │   ├── collection_filters.ex
│   │   └── math_filters.ex
│   └── error.ex                     # Error handling
```

#### 1.2 Error Handling System
```elixir
defmodule Mau.Error do
  defstruct [:type, :message, :line, :column, :source_file, :context]
  
  @type t :: %__MODULE__{
    type: :syntax | :runtime | :type | :undefined_variable,
    message: String.t(),
    line: integer() | nil,
    column: integer() | nil,
    source_file: String.t() | nil,
    context: map()
  }
end
```

### Phase 2: Parser Implementation with NimbleParsec (Week 2)

#### 2.1 NimbleParsec Setup
```elixir
# mix.exs - Add dependency
defp deps do
  [
    {:nimble_parsec, "~> 1.4"}
  ]
end
```

#### 2.2 Parser Architecture with NimbleParsec
- **Single-pass parsing** using NimbleParsec combinators
- **Context-aware** parsing for different template sections
- **Error recovery** and position tracking
- **Modular combinators** for reusable parsing logic

```elixir
defmodule Mau.Parser do
  import NimbleParsec
  
  # Basic delimiters
  expression_open = string("{{") |> optional(string("-")) |> tag(:expr_open)
  expression_close = optional(string("-")) |> string("}}") |> tag(:expr_close)
  tag_open = string("{%") |> optional(string("-")) |> tag(:tag_open)
  tag_close = optional(string("-")) |> string("%}") |> tag(:tag_close)
  comment_open = string("{#") |> tag(:comment_open)
  comment_close = string("#}") |> tag(:comment_close)
  
  # Text content (everything that's not template syntax)
  text_content = 
    utf8_string([not: ?{], min: 1)
    |> reduce({:text_node, []})
  
  # Template structure
  defparsec :template,
    repeat(choice([
      parsec(:expression),
      parsec(:tag),
      parsec(:comment),
      text_content
    ]))
  
  # Expression parsing {{ ... }}
  defparsec :expression,
    expression_open
    |> parsec(:expression_content)
    |> expression_close
    |> reduce({:expression_node, []})
  
  # Tag parsing {% ... %}
  defparsec :tag,
    tag_open
    |> parsec(:tag_content)
    |> tag_close
    |> reduce({:tag_node, []})
    
  # Comment parsing {# ... #}
  defparsec :comment,
    comment_open
    |> utf8_string([not: ?#], min: 0)
    |> comment_close
    |> ignore()
end
```

#### 2.3 Expression Parsing Combinators
```elixir
defmodule Mau.Parser.Expressions do
  import NimbleParsec
  
  # Identifiers and literals
  identifier = 
    ascii_char([?a..?z, ?A..?Z, ?$, ?_])
    |> repeat(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_, ?$]))
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:identifier)
  
  # String literals
  string_literal =
    choice([
      ignore(string("\""))
      |> utf8_string([not: ?\"], min: 0)
      |> ignore(string("\""))
      |> unwrap_and_tag(:string),
      
      ignore(string("'"))
      |> utf8_string([not: ?'], min: 0)
      |> ignore(string("'"))
      |> unwrap_and_tag(:string)
    ])
  
  # Number literals
  number_literal =
    optional(string("-"))
    |> integer(min: 1)
    |> optional(string(".") |> integer(min: 1))
    |> reduce({:parse_number, []})
    |> unwrap_and_tag(:number)
  
  # Boolean literals
  boolean_literal =
    choice([
      string("true") |> replace(true),
      string("false") |> replace(false)
    ])
    |> unwrap_and_tag(:boolean)
  
  # Null literal
  null_literal =
    choice([
      string("null"),
      string("nil")
    ])
    |> replace(nil)
    |> unwrap_and_tag(:null)
  
  # Property access with dots and brackets
  property_access =
    identifier
    |> repeat(choice([
      ignore(string(".")) |> concat(identifier),
      ignore(string("[")) |> parsec(:expression_content) |> ignore(string("]"))
    ]))
    |> tag(:variable)
  
  # Function calls (both direct and pipe syntax)
  function_call =
    identifier
    |> ignore(string("("))
    |> optional(parsec(:argument_list))
    |> ignore(string(")"))
    |> tag(:call)
  
  # Pipe operations
  pipe_operation =
    parsec(:primary_expression)
    |> repeat(
      ignore(string("|"))
      |> ignore(optional(ascii_string([?\s, ?\t], min: 1)))
      |> choice([
        function_call,
        identifier |> tag(:filter)
      ])
    )
    |> reduce({:build_pipe_chain, []})
  
  # Binary operations with precedence
  defparsec :expression_content,
    parsec(:logical_or_expression)
  
  defparsec :logical_or_expression,
    parsec(:logical_and_expression)
    |> repeat(
      ignore(ascii_string([?\s, ?\t], min: 0))
      |> string("or")
      |> ignore(ascii_string([?\s, ?\t], min: 0))
      |> parsec(:logical_and_expression)
    )
    |> reduce({:build_binary_op, [:or]})
  
  defparsec :logical_and_expression,
    parsec(:equality_expression)
    |> repeat(
      ignore(ascii_string([?\s, ?\t], min: 0))
      |> string("and")
      |> ignore(ascii_string([?\s, ?\t], min: 0))
      |> parsec(:equality_expression)
    )
    |> reduce({:build_binary_op, [:and]})
  
  defparsec :equality_expression,
    parsec(:relational_expression)
    |> repeat(
      ignore(ascii_string([?\s, ?\t], min: 0))
      |> choice([string("=="), string("!=")])
      |> ignore(ascii_string([?\s, ?\t], min: 0))
      |> parsec(:relational_expression)
    )
    |> reduce({:build_binary_op, []})
  
  defparsec :relational_expression,
    parsec(:additive_expression)
    |> repeat(
      ignore(ascii_string([?\s, ?\t], min: 0))
      |> choice([string("<="), string(">="), string("<"), string(">")])
      |> ignore(ascii_string([?\s, ?\t], min: 0))
      |> parsec(:additive_expression)
    )
    |> reduce({:build_binary_op, []})
  
  defparsec :additive_expression,
    parsec(:multiplicative_expression)
    |> repeat(
      ignore(ascii_string([?\s, ?\t], min: 0))
      |> choice([string("+"), string("-")])
      |> ignore(ascii_string([?\s, ?\t], min: 0))
      |> parsec(:multiplicative_expression)
    )
    |> reduce({:build_binary_op, []})
  
  defparsec :multiplicative_expression,
    parsec(:unary_expression)
    |> repeat(
      ignore(ascii_string([?\s, ?\t], min: 0))
      |> choice([string("*"), string("/"), string("%")])
      |> ignore(ascii_string([?\s, ?\t], min: 0))
      |> parsec(:unary_expression)
    )
    |> reduce({:build_binary_op, []})
  
  defparsec :unary_expression,
    choice([
      string("not") |> ignore(ascii_string([?\s, ?\t], min: 1)) |> parsec(:primary_expression) |> tag(:not),
      string("-") |> parsec(:primary_expression) |> tag(:unary_minus),
      pipe_operation
    ])
  
  defparsec :primary_expression,
    choice([
      ignore(string("(")) |> parsec(:expression_content) |> ignore(string(")")),
      function_call,
      property_access,
      string_literal,
      number_literal,
      boolean_literal,
      null_literal
    ])
    |> ignore(optional(ascii_string([?\s, ?\t], min: 1)))
end
```

#### 2.4 Tag Parsing Combinators
```elixir
defmodule Mau.Parser.Tags do
  import NimbleParsec
  import Mau.Parser.Expressions
  
  # Control flow tags
  if_tag =
    string("if")
    |> ignore(ascii_string([?\s, ?\t], min: 1))
    |> parsec(:expression_content)
    |> tag(:if_condition)
  
  elsif_tag =
    string("elsif")
    |> ignore(ascii_string([?\s, ?\t], min: 1))
    |> parsec(:expression_content)
    |> tag(:elsif_condition)
  
  else_tag = string("else") |> tag(:else)
  endif_tag = string("endif") |> tag(:endif)
  
  for_tag =
    string("for")
    |> ignore(ascii_string([?\s, ?\t], min: 1))
    |> identifier
    |> ignore(ascii_string([?\s, ?\t], min: 1))
    |> string("in")
    |> ignore(ascii_string([?\s, ?\t], min: 1))
    |> parsec(:expression_content)
    |> optional(parsec(:for_options))
    |> tag(:for_loop)
  
  for_options =
    repeat(
      ignore(ascii_string([?\s, ?\t], min: 1))
      |> choice([
        string("limit:") |> ignore(ascii_string([?\s, ?\t], min: 0)) |> integer(min: 1) |> unwrap_and_tag(:limit),
        string("offset:") |> ignore(ascii_string([?\s, ?\t], min: 0)) |> integer(min: 1) |> unwrap_and_tag(:offset)
      ])
    )
  
  endfor_tag = string("endfor") |> tag(:endfor)
  
  assign_tag =
    string("assign")
    |> ignore(ascii_string([?\s, ?\t], min: 1))
    |> identifier
    |> ignore(ascii_string([?\s, ?\t], min: 0))
    |> ignore(string("="))
    |> ignore(ascii_string([?\s, ?\t], min: 0))
    |> parsec(:expression_content)
    |> tag(:assign)
  
  defparsec :tag_content,
    choice([
      if_tag, elsif_tag, else_tag, endif_tag,
      for_tag, endfor_tag,
      assign_tag
    ])
    |> ignore(optional(ascii_string([?\s, ?\t], min: 1)))
end
```

### Phase 3: AST Transformation and Validation (Week 3)

#### 3.1 AST Node Construction Helpers
```elixir
defmodule Mau.AST.Nodes do
  # Transform NimbleParsec output into spec-compliant AST
  def text_node(content, opts \\ []) do
    {:text, [content], opts}
  end
  
  def literal_node(value, opts \\ []) do
    {:literal, [value], opts}
  end
  
  def expression_node(expr, opts \\ []) do
    {:expression, [expr], opts}
  end
  
  def tag_node(subtype, params, body, opts \\ []) do
    {:tag, [subtype, params, body], opts}
  end
  
  def variable_expr(path, opts \\ []) when is_list(path) do
    {:variable, path, opts}
  end
  
  def binary_op_expr(op, left, right, opts \\ []) do
    {:binary_op, [op, left, right], opts}
  end
  
  def logical_op_expr(op, left, right, opts \\ []) do
    {:logical_op, [op, left, right], opts}
  end
  
  def call_expr(func_name, args, opts \\ []) do
    {:call, [func_name, args], opts}
  end
end
```

#### 3.2 NimbleParsec Reducer Functions
```elixir
defmodule Mau.Parser.Reducers do
  alias Mau.AST.Nodes
  
  # Transform parser output into AST nodes
  def text_node([content]) when is_binary(content) do
    Nodes.text_node(content)
  end
  
  def expression_node([{:expr_open, trim_left}, expr, {:expr_close, trim_right}]) do
    opts = build_trim_opts(trim_left, trim_right)
    Nodes.expression_node(expr, opts)
  end
  
  def tag_node([{:tag_open, trim_left}, tag_content, {:tag_close, trim_right}]) do
    opts = build_trim_opts(trim_left, trim_right)
    case tag_content do
      {:if_condition, condition} -> Nodes.tag_node(:if, condition, [], opts)
      {:for_loop, [var_name, collection | loop_opts]} -> 
        Nodes.tag_node(:for, [var_name, collection, [], loop_opts], [], opts)
      {:assign, [var_name, value]} -> 
        Nodes.tag_node(:assign, [var_name, value, []], [], opts)
    end
  end
  
  def build_binary_op([left | rest]) do
    Enum.reduce(rest, left, fn [op, right], acc ->
      op_atom = case op do
        "==" -> :==
        "!=" -> :!=
        ">=" -> :>=
        "<=" -> :<=
        ">" -> :>
        "<" -> :<
        "+" -> :+
        "-" -> :-
        "*" -> :*
        "/" -> :/
        "%" -> :%
        "and" -> :and
        "or" -> :or
      end
      
      if op_atom in [:and, :or] do
        Nodes.logical_op_expr(op_atom, acc, right)
      else
        Nodes.binary_op_expr(op_atom, acc, right)
      end
    end)
  end
  
  def build_pipe_chain([base | filters]) do
    Enum.reduce(filters, base, fn filter, acc ->
      case filter do
        {:filter, name} -> Nodes.call_expr(name, [acc])
        {:call, [name | args]} -> Nodes.call_expr(name, [acc | args])
      end
    end)
  end
  
  def parse_number([sign, integer, decimal]) do
    num_str = "#{sign || ""}#{integer}#{decimal || ""}"
    case Float.parse(num_str) do
      {num, ""} -> if String.contains?(num_str, "."), do: num, else: trunc(num)
      _ -> raise "Invalid number: #{num_str}"
    end
  end
  
  defp build_trim_opts(trim_left, trim_right) do
    []
    |> maybe_add_opt(:trim_left, trim_left)
    |> maybe_add_opt(:trim_right, trim_right)
  end
  
  defp maybe_add_opt(opts, _key, nil), do: opts
  defp maybe_add_opt(opts, key, _value), do: [{key, true} | opts]
end
```

#### 3.3 Block Structure Parsing
```elixir
defmodule Mau.Parser.BlockParser do
  # Post-process flat tag list into nested block structure
  def build_block_structure(ast_nodes) do
    {result, _stack} = build_blocks(ast_nodes, [])
    result
  end
  
  defp build_blocks([], stack), do: {[], stack}
  
  defp build_blocks([node | rest], stack) do
    case node do
      {:tag, [:if, condition, [], opts], _} ->
        {body, remaining, new_stack} = collect_if_block(rest, [])
        if_node = {:tag, [:if, [{condition, body}], opts], []}
        {tail, final_stack} = build_blocks(remaining, stack)
        {[if_node | tail], final_stack}
      
      {:tag, [:for, [var_name, collection, [], loop_opts], [], opts], _} ->
        {body, remaining, new_stack} = collect_until_tag(rest, :endfor, [])
        for_node = {:tag, [:for, [var_name, collection, body, loop_opts], opts], []}
        {tail, final_stack} = build_blocks(remaining, stack)
        {[for_node | tail], final_stack}
      
      {:tag, [:assign, params, [], opts], _} ->
        assign_node = {:tag, [:assign, params, [], opts], []}
        {tail, final_stack} = build_blocks(rest, stack)
        {[assign_node | tail], final_stack}
      
      other ->
        {tail, final_stack} = build_blocks(rest, stack)
        {[other | tail], final_stack}
    end
  end
  
  defp collect_if_block(nodes, current_clauses) do
    collect_if_block(nodes, current_clauses, [])
  end
  
  defp collect_if_block([{:tag, [:elsif, condition, [], _], _} | rest], clauses, current_body) do
    new_clause = {List.last(clauses)[:condition] || :if, Enum.reverse(current_body)}
    collect_if_block(rest, [new_clause | clauses], [])
  end
  
  defp collect_if_block([{:tag, [:else, [], [], _], _} | rest], clauses, current_body) do
    new_clause = {List.last(clauses)[:condition] || :if, Enum.reverse(current_body)}
    {else_body, remaining, _} = collect_until_tag(rest, :endif, [])
    final_clauses = [new_clause | clauses] ++ [{:else, else_body}]
    {Enum.reverse(final_clauses), remaining, []}
  end
  
  defp collect_if_block([{:tag, [:endif, [], [], _], _} | rest], clauses, current_body) do
    final_clause = {List.last(clauses)[:condition] || :if, Enum.reverse(current_body)}
    {Enum.reverse([final_clause | clauses]), rest, []}
  end
  
  defp collect_if_block([node | rest], clauses, current_body) do
    collect_if_block(rest, clauses, [node | current_body])
  end
  
  defp collect_until_tag([], _end_tag, acc), do: {Enum.reverse(acc), [], []}
  
  defp collect_until_tag([{:tag, [end_tag, [], [], _], _} | rest], end_tag, acc) do
    {Enum.reverse(acc), rest, []}
  end
  
  defp collect_until_tag([node | rest], end_tag, acc) do
    collect_until_tag(rest, end_tag, [node | acc])
  end
end
```

### Phase 4: Evaluator/Renderer Implementation (Week 4)

#### 4.1 Context Management
```elixir
defmodule Mau.Context do
  defstruct [:variables, :strict_mode, :filters, :metadata]
  
  def new(variables \\ %{}, opts \\ [])
  def get_variable(context, path)
  def set_variable(context, name, value)
  def merge_loop_context(context, var_name, item, loop_metadata)
end
```

#### 4.2 Expression Evaluator
```elixir
defmodule Mau.Evaluator do
  @spec evaluate_expression(expr :: term(), context :: Context.t()) :: 
    {:ok, term()} | {:error, Mau.Error.t()}
    
  def evaluate_expression({:variable, path, opts}, context)
  def evaluate_expression({:literal, [value], opts}, context)
  def evaluate_expression({:binary_op, [op, left, right], opts}, context)
  def evaluate_expression({:logical_op, [op, left, right], opts}, context)
  def evaluate_expression({:call, [func_name, args], opts}, context)
end
```

#### 4.3 Template Renderer
```elixir
defmodule Mau.Renderer do
  @spec render_ast(ast :: [term()], context :: Context.t()) :: 
    {:ok, String.t()} | {:error, Mau.Error.t()}
    
  def render_node({:text, [content], opts}, context)
  def render_node({:expression, [expr], opts}, context)
  def render_node({:tag, [tag_name | params], opts}, context)
  
  # Tag renderers
  def render_tag(:if, clauses, context)
  def render_tag(:for, [var_name, collection_expr, body, loop_opts], context)
  def render_tag(:assign, [var_name, value_expr, []], context)
end
```

### Phase 5: Filter System (Week 5)

#### 5.1 Filter Registry
```elixir
defmodule Mau.FilterRegistry do
  @spec register_filter(name :: String.t(), function :: function()) :: :ok
  @spec apply_filter(name :: String.t(), value :: term(), args :: [term()]) :: 
    {:ok, term()} | {:error, String.t()}
    
  def register_builtin_filters()
  def apply_filter(name, value, args)
end
```

#### 5.2 Built-in Filters Implementation
```elixir
# String filters
def upper_case(value, []), do: {:ok, String.upcase(to_string(value))}
def truncate(value, [length]), do: {:ok, String.slice(to_string(value), 0, length)}

# Collection filters  
def length(value, []) when is_list(value), do: {:ok, Enum.count(value)}
def first(value, []) when is_list(value), do: {:ok, List.first(value)}

# Math filters
def round(value, [precision]) when is_number(value), do: {:ok, Float.round(value, precision)}
```

### Phase 6: Public API Implementation (Week 6)

#### 6.1 Main Module
```elixir
defmodule Mau do
  alias Mau.Parser
  alias Mau.Parser.BlockParser
  alias Mau.Evaluator
  alias Mau.Renderer
  alias Mau.Context
  
  @spec compile(String.t(), keyword()) :: 
    {:ok, term()} | {:ok, term(), [term()]} | {:error, term()}
  def compile(template, opts \\ []) do
    case Parser.template(template) do
      {:ok, parsed_nodes, "", _, _, _} ->
        # Transform flat nodes into nested block structure
        ast = BlockParser.build_block_structure(parsed_nodes)
        
        if opts[:strict_mode] do
          case validate_ast(ast) do
            :ok -> {:ok, ast, []}
            {:error, errors} -> {:error, errors}
          end
        else
          # Extract warnings from parsing but continue
          warnings = extract_warnings(ast)
          {:ok, ast, warnings}
        end
      
      {:ok, _, remaining, _, _, _} ->
        {:error, %Mau.Error{
          type: :syntax,
          message: "Unexpected content: #{inspect(remaining)}",
          line: nil,
          column: nil
        }}
      
      {:error, reason, remaining, _, {line, column}, _} ->
        {:error, %Mau.Error{
          type: :syntax,
          message: "Parse error: #{inspect(reason)}",
          line: line,
          column: column,
          context: %{remaining: remaining}
        }}
    end
  end
  
  @spec render(String.t() | term(), map(), keyword()) :: 
    {:ok, String.t() | term()} | {:error, term()}
  def render(template_or_ast, context \\ %{}, opts \\ [])
  
  def render(template, context, opts) when is_binary(template) do
    case compile(template, opts) do
      {:ok, ast, _warnings} -> render(ast, context, opts)
      {:error, error} -> {:error, error}
    end
  end
  
  def render(ast, context, opts) do
    mau_context = Context.new(context, opts)
    
    case detect_template_type(ast) do
      :pure_expression -> 
        # Single expression, return raw value
        case Evaluator.evaluate_expression(ast, mau_context) do
          {:ok, value} -> {:ok, value}
          {:error, error} -> {:error, error}
        end
        
      :mixed_content ->
        # Template with text and expressions, return string
        case Renderer.render_ast(ast, mau_context) do
          {:ok, result} -> {:ok, result}
          {:error, error} -> {:error, error}
        end
    end
  end
  
  @spec render_map(map(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def render_map(nested_map, context \\ %{}, opts \\ []) do
    render_map_recursive(nested_map, context, opts)
  end
  
  defp render_map_recursive(map, context, opts) when is_map(map) do
    results = 
      map
      |> Enum.map(fn {key, value} ->
        case render_value(value, context, opts) do
          {:ok, rendered_value} -> {:ok, {key, rendered_value}}
          {:error, error} -> {:error, error}
        end
      end)
    
    case Enum.find(results, &match?({:error, _}, &1)) do
      {:error, error} -> {:error, error}
      nil -> {:ok, Map.new(Enum.map(results, fn {:ok, pair} -> pair end))}
    end
  end
  
  defp render_value(value, context, opts) when is_binary(value) do
    if contains_template_syntax?(value) do
      render(value, context, opts)
    else
      {:ok, value}
    end
  end
  
  defp render_value(value, context, opts) when is_map(value) do
    render_map_recursive(value, context, opts)
  end
  
  defp render_value(value, _context, _opts), do: {:ok, value}
end
```

#### 6.2 Template Detection Utilities
```elixir
defp detect_template_type([{:expression, _expr, _opts}]), do: :pure_expression
defp detect_template_type(_ast), do: :mixed_content

defp contains_template_syntax?(string) do
  String.contains?(string, ["{{", "{%", "{#"])
end
```

## Testing Strategy

### Unit Tests
- **Lexer tests**: Token generation for all syntax elements
- **Parser tests**: AST generation for complex templates  
- **Evaluator tests**: Expression evaluation with various data types
- **Filter tests**: All built-in filters with edge cases
- **Error handling**: Comprehensive error scenario testing

### Integration Tests
- **Full pipeline**: Template string → AST → rendered output
- **Context handling**: Variable scoping, assignments, loops
- **Performance**: Large templates and deep nesting
- **Edge cases**: Malformed templates, missing variables

### Property-Based Testing
- **Round-trip testing**: Parse → render → parse consistency
- **Fuzzing**: Random template generation for robustness

## Performance Considerations

### Optimization Strategies
1. **AST Caching**: Cache compiled templates by content hash
2. **Context Pooling**: Reuse context objects for similar renders
3. **Filter Memoization**: Cache expensive filter operations
4. **Tail Call Optimization**: Optimize recursive AST traversal

### Memory Management
- **Streaming**: Support for large template processing
- **Lazy Evaluation**: Defer complex operations when possible
- **Resource Limits**: Configurable limits for recursion depth, loop iterations

## Incremental Implementation by Template Feature Groups

### Development Approach
- **Test-Driven Development**: Each feature group requires 100% passing tests before moving to next
- **Incremental Building**: Each group builds upon previous groups
- **Parser + Evaluator**: Implement both parsing and evaluation for each group
- **Comprehensive Testing**: Unit tests, integration tests, and edge cases for each group

### Group 1: Text and Basic Infrastructure (Week 1)
**Goal**: Handle plain text templates and basic project setup

**Features:**
- Plain text rendering (no template syntax)
- Project structure and dependencies
- Error handling framework
- Basic AST structure

**Parser Requirements:**
```elixir
# Basic text parsing
defparsec :template, repeat(parsec(:text_content))
defparsec :text_content, utf8_string([not: ?{], min: 1) |> reduce({:text_node, []})
```

**Evaluator Requirements:**
```elixir
def render_node({:text, [content], _opts}, _context), do: {:ok, content}
```

**Test Cases:**
```elixir
test "renders plain text" do
  assert Mau.render("Hello World", %{}) == {:ok, "Hello World"}
end

test "renders text with special characters" do
  assert Mau.render("Hello! @#$%^&*()", %{}) == {:ok, "Hello! @#$%^&*()"}
end

test "handles empty text" do
  assert Mau.render("", %{}) == {:ok, ""}
end

test "handles multiline text" do
  text = "Line 1\nLine 2\nLine 3"
  assert Mau.render(text, %{}) == {:ok, text}
end
```

**Success Criteria:**
- [x] All text rendering tests pass
- [x] Project compiles without warnings
- [x] Basic error handling works

---

### Group 2: Literal Expressions (Week 2)
**Goal**: Parse and evaluate literal values in expressions

**Features:**
- String literals: `{{ "hello" }}`, `{{ 'world' }}`
- Number literals: `{{ 42 }}`, `{{ 3.14 }}`, `{{ -17 }}`
- Boolean literals: `{{ true }}`, `{{ false }}`
- Null literals: `{{ null }}`, `{{ nil }}`

**Parser Requirements:**
```elixir
# Expression parsing
defparsec :expression,
  string("{{")
  |> ignore(optional(ascii_string([?\s, ?\t], min: 1)))
  |> parsec(:literal_expression)
  |> ignore(optional(ascii_string([?\s, ?\t], min: 1)))
  |> string("}}")
  |> reduce({:expression_node, []})

defparsec :literal_expression,
  choice([
    parsec(:string_literal),
    parsec(:number_literal),
    parsec(:boolean_literal),
    parsec(:null_literal)
  ])

# String literals with escape sequences
defparsec :string_literal,
  choice([
    ignore(string("\"")) |> parsec(:double_quoted_content) |> ignore(string("\"")) |> tag(:string),
    ignore(string("'")) |> parsec(:single_quoted_content) |> ignore(string("'")) |> tag(:string)
  ])

# Number parsing with proper float/int distinction  
defparsec :number_literal,
  optional(string("-"))
  |> integer(min: 1)
  |> optional(string(".") |> integer(min: 1))
  |> optional(choice([string("e"), string("E")]) |> optional(choice([string("+"), string("-")])) |> integer(min: 1))
  |> reduce({:parse_number, []})
  |> tag(:number)
```

**Evaluator Requirements:**
```elixir
def evaluate_expression({:literal, [value], _opts}, _context), do: {:ok, value}

def render_node({:expression, [expr], _opts}, context) do
  case evaluate_expression(expr, context) do
    {:ok, value} -> {:ok, to_string(value)}
    {:error, reason} -> {:error, reason}
  end
end
```

**Test Cases:**
```elixir
# String literals
test "renders double quoted strings" do
  assert Mau.render(~s|{{ "hello world" }}|, %{}) == {:ok, "hello world"}
end

test "renders single quoted strings" do
  assert Mau.render("{{ 'hello world' }}", %{}) == {:ok, "hello world"}
end

test "handles empty strings" do
  assert Mau.render(~s|{{ "" }}|, %{}) == {:ok, ""}
end

test "handles string with escaped quotes" do
  assert Mau.render(~s|{{ "say \"hello\"" }}|, %{}) == {:ok, ~s|say "hello"|
end

# Number literals
test "renders positive integers" do
  assert Mau.render("{{ 42 }}", %{}) == {:ok, "42"}
end

test "renders negative integers" do
  assert Mau.render("{{ -17 }}", %{}) == {:ok, "-17"}
end

test "renders floats" do
  assert Mau.render("{{ 3.14159 }}", %{}) == {:ok, "3.14159"}
end

test "renders scientific notation" do
  assert Mau.render("{{ 1.5e-10 }}", %{}) == {:ok, "1.5e-10"}
end

test "renders zero" do
  assert Mau.render("{{ 0 }}", %{}) == {:ok, "0"}
end

# Boolean literals
test "renders true" do
  assert Mau.render("{{ true }}", %{}) == {:ok, "true"}
end

test "renders false" do
  assert Mau.render("{{ false }}", %{}) == {:ok, "false"}
end

# Null literals
test "renders null" do
  assert Mau.render("{{ null }}", %{}) == {:ok, ""}
end

test "renders nil" do
  assert Mau.render("{{ nil }}", %{}) == {:ok, ""}
end

# Mixed content
test "renders text with literals" do
  assert Mau.render(~s|Hello {{ "world" }}!|, %{}) == {:ok, "Hello world!"}
end

test "renders multiple expressions" do
  assert Mau.render("{{ 1 }} + {{ 2 }} = {{ 3 }}", %{}) == {:ok, "1 + 2 = 3"}
end

# Pure expression detection
test "returns raw value for pure expression" do
  assert Mau.render("{{ 42 }}", %{}) == {:ok, 42}  # Raw integer, not string
end

test "returns string for mixed content" do
  assert Mau.render("Value: {{ 42 }}", %{}) == {:ok, "Value: 42"}  # String result
end
```

**Success Criteria:**
- [x] All literal parsing tests pass
- [x] All literal evaluation tests pass  
- [x] Pure expression vs mixed content detection works
- [x] Proper type preservation (numbers stay numbers in pure expressions)

---

### Group 3: Variable Expressions (Week 3)
**Goal**: Parse and evaluate variable access with path traversal

**Features:**
- Simple variables: `{{ name }}`, `{{ $input }}`
- Object property access: `{{ user.name }}`, `{{ $input.email }}`
- Nested property access: `{{ user.profile.settings.theme }}`
- Array indexing: `{{ users[0] }}`, `{{ items[index] }}`
- Mixed access: `{{ $nodes.api_call.response.data.users[0].name }}`

**Parser Requirements:**
```elixir
# Variable path parsing
defparsec :variable_expression,
  parsec(:identifier)
  |> repeat(choice([
    ignore(string(".")) |> parsec(:identifier),
    ignore(string("[")) |> parsec(:array_index) |> ignore(string("]"))
  ]))
  |> reduce({:build_variable_path, []})
  |> tag(:variable)

defparsec :identifier,
  ascii_char([?a..?z, ?A..?Z, ?$, ?_])
  |> repeat(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_, ?$]))
  |> reduce({List, :to_string, []})

defparsec :array_index,
  choice([
    parsec(:number_literal),
    parsec(:variable_expression)
  ])
```

**Evaluator Requirements:**
```elixir
def evaluate_expression({:variable, path, opts}, context) do
  case extract_variable_value(path, context) do
    {:ok, value} -> {:ok, value}
    {:error, _} when opts[:strict_mode] == false -> {:ok, nil}
    {:error, reason} -> {:error, reason}
  end
end

defp extract_variable_value([key], context) when is_binary(key) do
  case Map.get(context, key) do
    nil -> {:error, "Variable '#{key}' not found"}
    value -> {:ok, value}
  end
end

defp extract_variable_value([key | rest], context) when is_binary(key) do
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
    value when is_list(value) -> extract_from_list(rest, value)
    _ -> {:error, "Cannot access property on non-object value"}
  end
end
```

**Test Cases:**
```elixir
# Simple variables
test "renders simple variable" do
  context = %{"name" => "Alice"}
  assert Mau.render("{{ name }}", context) == {:ok, "Alice"}
end

test "renders workflow variables with $" do
  context = %{"$input" => "data"}
  assert Mau.render("{{ $input }}", context) == {:ok, "data"}
end

test "handles undefined variable in ease mode" do
  assert Mau.render("{{ undefined }}", %{}) == {:ok, ""}
end

test "handles undefined variable in strict mode" do
  opts = [strict_mode: true]
  assert {:error, _} = Mau.render("{{ undefined }}", %{}, opts)
end

# Object property access
test "renders object property" do
  context = %{"user" => %{"name" => "Bob"}}
  assert Mau.render("{{ user.name }}", context) == {:ok, "Bob"}
end

test "renders nested properties" do
  context = %{
    "user" => %{
      "profile" => %{
        "settings" => %{"theme" => "dark"}
      }
    }
  }
  assert Mau.render("{{ user.profile.settings.theme }}", context) == {:ok, "dark"}
end

test "handles missing property in ease mode" do
  context = %{"user" => %{}}
  assert Mau.render("{{ user.name }}", context) == {:ok, ""}
end

# Array indexing
test "renders array element by index" do
  context = %{"users" => ["Alice", "Bob", "Charlie"]}
  assert Mau.render("{{ users[0] }}", context) == {:ok, "Alice"}
  assert Mau.render("{{ users[2] }}", context) == {:ok, "Charlie"}
end

test "handles negative array index" do
  context = %{"users" => ["Alice", "Bob", "Charlie"]}
  assert Mau.render("{{ users[-1] }}", context) == {:ok, "Charlie"}
end

test "handles out of bounds array access" do
  context = %{"users" => ["Alice"]}
  assert Mau.render("{{ users[5] }}", context) == {:ok, ""}
end

test "renders array element property" do
  context = %{
    "users" => [
      %{"name" => "Alice", "age" => 30},
      %{"name" => "Bob", "age" => 25}
    ]
  }
  assert Mau.render("{{ users[0].name }}", context) == {:ok, "Alice"}
  assert Mau.render("{{ users[1].age }}", context) == {:ok, "25"}
end

# Dynamic indexing
test "renders with variable index" do
  context = %{
    "users" => ["Alice", "Bob", "Charlie"],
    "index" => 1
  }
  assert Mau.render("{{ users[index] }}", context) == {:ok, "Bob"}
end

# Complex workflow variables
test "renders complex workflow path" do
  context = %{
    "$nodes" => %{
      "api_call" => %{
        "response" => %{
          "data" => %{
            "users" => [
              %{"name" => "API User", "id" => 123}
            ]
          }
        }
      }
    }
  }
  assert Mau.render("{{ $nodes.api_call.response.data.users[0].name }}", context) == {:ok, "API User"}
end

# Mixed variable and literal content
test "renders mixed variable and text" do
  context = %{"name" => "Alice", "age" => 30}
  assert Mau.render("Hello {{ name }}, you are {{ age }} years old!", context) == {:ok, "Hello Alice, you are 30 years old!"}
end

# Variable types preservation
test "preserves variable types in pure expressions" do
  context = %{"count" => 42, "active" => true, "data" => nil}
  assert Mau.render("{{ count }}", context) == {:ok, 42}
  assert Mau.render("{{ active }}", context) == {:ok, true}
  assert Mau.render("{{ data }}", context) == {:ok, nil}
end
```

**Success Criteria:**
- [x] All variable access patterns work correctly
- [x] Proper error handling for undefined variables
- [x] Array indexing with bounds checking
- [x] Dynamic indexing with variables
- [x] Complex nested path traversal
- [x] Type preservation in pure expressions

---

### Group 4: Arithmetic Expressions (Week 4)
**Goal**: Parse and evaluate arithmetic operations with proper precedence

**Features:**
- Basic operators: `+`, `-`, `*`, `/`, `%`
- Operator precedence: `*` and `/` before `+` and `-`
- Parentheses: `{{ (a + b) * c }}`
- String concatenation: `{{ "Hello " + name }}`
- Mixed operands: `{{ count + 1 }}`

**Parser Requirements:**
```elixir
# Arithmetic expression parsing with precedence
defparsec :expression_content, parsec(:additive_expression)

defparsec :additive_expression,
  parsec(:multiplicative_expression)
  |> repeat(
    ignore(optional(ascii_string([?\s, ?\t], min: 1)))
    |> choice([string("+"), string("-")])
    |> ignore(optional(ascii_string([?\s, ?\t], min: 1)))
    |> parsec(:multiplicative_expression)
  )
  |> reduce({:build_binary_op, []})

defparsec :multiplicative_expression,
  parsec(:unary_expression)
  |> repeat(
    ignore(optional(ascii_string([?\s, ?\t], min: 1)))
    |> choice([string("*"), string("/"), string("%")])
    |> ignore(optional(ascii_string([?\s, ?\t], min: 1)))
    |> parsec(:unary_expression)
  )
  |> reduce({:build_binary_op, []})

defparsec :unary_expression,
  choice([
    string("-") |> parsec(:primary_expression) |> tag(:unary_minus),
    parsec(:primary_expression)
  ])

defparsec :primary_expression,
  choice([
    ignore(string("(")) |> parsec(:expression_content) |> ignore(string(")")),
    parsec(:variable_expression),
    parsec(:literal_expression)
  ])
```

**Evaluator Requirements:**
```elixir
def evaluate_expression({:binary_op, [operator, left_expr, right_expr], _opts}, context) do
  with {:ok, left} <- evaluate_expression(left_expr, context),
       {:ok, right} <- evaluate_expression(right_expr, context) do
    apply_binary_operation(operator, left, right)
  end
end

defp apply_binary_operation(:+, left, right) when is_number(left) and is_number(right) do
  {:ok, left + right}
end

defp apply_binary_operation(:+, left, right) do
  # String concatenation
  {:ok, to_string(left) <> to_string(right)}
end

defp apply_binary_operation(:-, left, right) when is_number(left) and is_number(right) do
  {:ok, left - right}
end

defp apply_binary_operation(:*, left, right) when is_number(left) and is_number(right) do
  {:ok, left * right}
end

defp apply_binary_operation(:/, left, right) when is_number(left) and is_number(right) and right != 0 do
  {:ok, left / right}
end

defp apply_binary_operation(:/, _left, 0) do
  {:error, "Division by zero"}
end

defp apply_binary_operation(:%, left, right) when is_integer(left) and is_integer(right) and right != 0 do
  {:ok, rem(left, right)}
end

defp apply_binary_operation(op, left, right) do
  {:error, "Unsupported operation #{op} with #{inspect(left)} and #{inspect(right)}"}
end
```

**Test Cases:**
```elixir
# Basic arithmetic
test "addition" do
  assert Mau.render("{{ 2 + 3 }}", %{}) == {:ok, 5}
end

test "subtraction" do
  assert Mau.render("{{ 10 - 4 }}", %{}) == {:ok, 6}
end

test "multiplication" do
  assert Mau.render("{{ 6 * 7 }}", %{}) == {:ok, 42}
end

test "division" do
  assert Mau.render("{{ 15 / 3 }}", %{}) == {:ok, 5.0}
end

test "modulo" do
  assert Mau.render("{{ 17 % 5 }}", %{}) == {:ok, 2}
end

# Float arithmetic
test "float operations" do
  assert Mau.render("{{ 3.14 + 2.86 }}", %{}) == {:ok, 6.0}
  assert Mau.render("{{ 10.5 / 2.5 }}", %{}) == {:ok, 4.2}
end

# Operator precedence
test "multiplication before addition" do
  assert Mau.render("{{ 2 + 3 * 4 }}", %{}) == {:ok, 14}  # 2 + (3 * 4)
end

test "division before subtraction" do
  assert Mau.render("{{ 10 - 8 / 2 }}", %{}) == {:ok, 6.0}  # 10 - (8 / 2)
end

test "left associativity" do
  assert Mau.render("{{ 10 - 5 - 2 }}", %{}) == {:ok, 3}  # (10 - 5) - 2
  assert Mau.render("{{ 12 / 3 / 2 }}", %{}) == {:ok, 2.0}  # (12 / 3) / 2
end

# Parentheses override precedence
test "parentheses change precedence" do
  assert Mau.render("{{ (2 + 3) * 4 }}", %{}) == {:ok, 20}
  assert Mau.render("{{ 2 * (3 + 4) }}", %{}) == {:ok, 14}
end

test "nested parentheses" do
  assert Mau.render("{{ ((2 + 3) * 4) - 5 }}", %{}) == {:ok, 15}
end

# Unary minus
test "unary minus" do
  assert Mau.render("{{ -5 }}", %{}) == {:ok, -5}
  assert Mau.render("{{ -(3 + 2) }}", %{}) == {:ok, -5}
end

test "unary minus with variables" do
  context = %{"x" => 10}
  assert Mau.render("{{ -x }}", context) == {:ok, -10}
end

# String concatenation
test "string concatenation with +" do
  assert Mau.render(~s|{{ "Hello " + "World" }}|, %{}) == {:ok, "Hello World"}
end

test "string and number concatenation" do
  assert Mau.render(~s|{{ "Count: " + 42 }}|, %{}) == {:ok, "Count: 42"}
end

test "mixed concatenation" do
  context = %{"name" => "Alice", "age" => 30}
  assert Mau.render(~s|{{ "Name: " + name + ", Age: " + age }}|, context) == {:ok, "Name: Alice, Age: 30"}
end

# Variables in arithmetic
test "arithmetic with variables" do
  context = %{"a" => 10, "b" => 5}
  assert Mau.render("{{ a + b }}", context) == {:ok, 15}
  assert Mau.render("{{ a * b - 2 }}", context) == {:ok, 48}
end

test "complex expression with variables" do
  context = %{"price" => 100, "tax_rate" => 0.08, "discount" => 10}
  assert Mau.render("{{ (price - discount) * (1 + tax_rate) }}", context) == {:ok, 97.2}
end

# Error cases
test "division by zero error" do
  assert {:error, _} = Mau.render("{{ 5 / 0 }}", %{})
end

test "modulo by zero error" do
  assert {:error, _} = Mau.render("{{ 5 % 0 }}", %{})
end

test "invalid operation" do
  assert {:error, _} = Mau.render("{{ true + false }}", %{})
end

# Mixed content with arithmetic
test "arithmetic in mixed content" do
  context = %{"items" => 5, "price" => 10}
  assert Mau.render("Total: ${{ items * price }}", context) == {:ok, "Total: $50"}
end
```

**Success Criteria:**
- [x] All basic arithmetic operations work
- [x] Operator precedence follows mathematical rules
- [x] Parentheses correctly override precedence
- [x] Unary minus works in all contexts
- [x] String concatenation with + operator
- [x] Mixed type concatenation (auto string conversion)
- [x] Variables work in arithmetic expressions
- [x] Proper error handling for invalid operations

---

### Group 5: Boolean and Comparison Expressions (Week 5)
**Goal**: Parse and evaluate boolean logic and comparison operations

**Features:**
- Comparison operators: `==`, `!=`, `>`, `>=`, `<`, `<=`
- Logical operators: `and`, `or`, `not`
- Boolean evaluation in different contexts
- Truthiness rules for non-boolean values

**Test Cases:**
```elixir
# Comparison operations
test "equality comparison" do
  assert Mau.render("{{ 5 == 5 }}", %{}) == {:ok, true}
  assert Mau.render("{{ 5 == 3 }}", %{}) == {:ok, false}
  assert Mau.render(~s|{{ "hello" == "hello" }}|, %{}) == {:ok, true}
end

test "inequality comparison" do
  assert Mau.render("{{ 5 != 3 }}", %{}) == {:ok, true}
  assert Mau.render("{{ 5 != 5 }}", %{}) == {:ok, false}
end

test "relational comparisons" do
  assert Mau.render("{{ 10 > 5 }}", %{}) == {:ok, true}
  assert Mau.render("{{ 10 >= 10 }}", %{}) == {:ok, true}
  assert Mau.render("{{ 3 < 7 }}", %{}) == {:ok, true}
  assert Mau.render("{{ 5 <= 5 }}", %{}) == {:ok, true}
end

# Logical operations
test "logical and" do
  assert Mau.render("{{ true and true }}", %{}) == {:ok, true}
  assert Mau.render("{{ true and false }}", %{}) == {:ok, false}
  assert Mau.render("{{ false and true }}", %{}) == {:ok, false}
end

test "logical or" do
  assert Mau.render("{{ true or false }}", %{}) == {:ok, true}
  assert Mau.render("{{ false or false }}", %{}) == {:ok, false}
end

test "logical not" do
  assert Mau.render("{{ not true }}", %{}) == {:ok, false}
  assert Mau.render("{{ not false }}", %{}) == {:ok, true}
end

# Complex boolean expressions
test "complex boolean logic" do
  context = %{"age" => 25, "active" => true, "role" => "admin"}
  assert Mau.render("{{ age >= 18 and active }}", context) == {:ok, true}
  assert Mau.render("{{ role == \"admin\" or role == \"moderator\" }}", context) == {:ok, true}
end

# Truthiness
test "truthiness of values" do
  context = %{
    "empty_string" => "",
    "non_empty_string" => "hello",
    "zero" => 0,
    "positive_number" => 42,
    "empty_list" => [],
    "non_empty_list" => [1, 2, 3],
    "null_value" => nil
  }
  
  assert Mau.render("{{ not empty_string }}", context) == {:ok, true}
  assert Mau.render("{{ not non_empty_string }}", context) == {:ok, false}
  assert Mau.render("{{ not zero }}", context) == {:ok, true}
  assert Mau.render("{{ not positive_number }}", context) == {:ok, false}
  assert Mau.render("{{ not empty_list }}", context) == {:ok, true}
  assert Mau.render("{{ not non_empty_list }}", context) == {:ok, false}
  assert Mau.render("{{ not null_value }}", context) == {:ok, true}
end
```

---

### Group 6: Filter Expressions (Week 6)
**Goal**: Parse and evaluate filter applications

**Features:**
- Pipe syntax: `{{ name | upper_case }}`
- Function syntax: `{{ upper_case(name) }}`
- Filters with arguments: `{{ text | truncate(50) }}`
- Chained filters: `{{ name | upper_case | truncate(10) }}`

**Test Cases:**
```elixir
# Basic filters
test "upper_case filter" do
  context = %{"name" => "alice"}
  assert Mau.render("{{ name | upper_case }}", context) == {:ok, "ALICE"}
  assert Mau.render("{{ upper_case(name) }}", context) == {:ok, "ALICE"}
end

test "filters with arguments" do
  context = %{"text" => "Hello World"}
  assert Mau.render("{{ text | truncate(5) }}", context) == {:ok, "Hello"}
  assert Mau.render("{{ truncate(text, 5) }}", context) == {:ok, "Hello"}
end

test "chained filters" do
  context = %{"name" => "alice bob"}
  assert Mau.render("{{ name | upper_case | truncate(5) }}", context) == {:ok, "ALICE"}
end
```

---

### Group 7: Assignment Tags (Week 7)
**Goal**: Parse and evaluate assignment operations

**Features:**
- Basic assignment: `{% assign name = "value" %}`
- Expression assignment: `{% assign total = price + tax %}`
- Assignment with variable scope

---

### Group 8: Conditional Tags (Week 8)
**Goal**: Parse and evaluate if/elsif/else constructs

**Features:**
- Simple if: `{% if condition %}...{% endif %}`
- If/else: `{% if condition %}...{% else %}...{% endif %}`
- If/elsif/else chains

---

### Group 9: Loop Tags (Week 9)
**Goal**: Parse and evaluate for loops

**Features:**
- Basic loops: `{% for item in items %}...{% endfor %}`
- Loop with options: `{% for item in items limit: 5 %}...{% endfor %}`
- Loop variables (forloop.index, etc.)

---

### Group 10: Whitespace Control (Week 10)
**Goal**: Handle whitespace trimming

**Features:**
- Trim left: `{{- expression }}`, `{%- tag %}`
- Trim right: `{{ expression -}}`, `{% tag -%}`
- Complex whitespace scenarios

---

### Implementation Rules

**Before starting each group:**
1. Create test file: `test/mau/group_X_test.exs`
2. Write all test cases for the group (Red phase)
3. Implement parser changes needed
4. Implement evaluator changes needed
5. Run tests until all pass (Green phase)
6. Refactor if needed (Refactor phase)
7. Only move to next group when 100% tests pass

**Each group deliverables:**
- Parser combinators for new syntax
- Evaluator functions for new operations  
- Comprehensive test suite (unit + integration)
- Updated AST node types if needed
- Documentation for new features

## Success Criteria

1. **API Compliance**: All three methods work as specified
2. **Syntax Support**: Full Prana template language implementation
3. **Error Handling**: Graceful degradation and helpful error messages
4. **Performance**: Handle templates up to 1MB with reasonable performance
5. **Test Coverage**: >95% code coverage with comprehensive edge case testing
6. **Documentation**: Complete API documentation with examples

## Risk Mitigation

### Technical Risks
- **Parser Complexity**: Start with simple recursive descent, optimize later
- **Performance**: Implement basic version first, profile and optimize
- **Memory Usage**: Add streaming support if needed

### Implementation Risks
- **Scope Creep**: Strictly follow AST specification
- **Timeline**: Prioritize core functionality over advanced features
- **Quality**: Implement comprehensive testing from day one