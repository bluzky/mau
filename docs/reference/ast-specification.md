# Template AST Specification

This document defines the Abstract Syntax Tree (AST) structure for Prana's template engine V3.

## Overview

The Prana template AST uses a unified tuple format for all nodes:

```elixir
{type :: atom(), parts :: list(), opts :: keyword()}
```

Where:
- `type` - The node type (`:text`, `:literal`, `:expression`, `:tag`)
- `parts` - Type-specific data as a list  
- `opts` - Optional metadata as a keyword list

## Core Node Types

### 1. Text Nodes

Represent raw, static text content from the template source.

**Format:**
```elixir
{:text, [string_content], opts}
```

**Parameters:**
- `string_content` - Raw text content as it appears in the template

**Examples:**
```elixir
# Template text: "Hello World"
{:text, ["Hello World"], []}

# Whitespace and newlines
{:text, ["\n  "], []}

# With source location
{:text, ["Welcome!"], [line: 5, column: 10]}
```

### 2. Literal Nodes

Represent constant values within expressions (numbers, strings, booleans, nil).

**Format:**
```elixir
{:literal, [value], opts}
```

**Parameters:**
- `value` - Any constant value (string, number, boolean, nil)

**Examples:**
```elixir
# Number in expression: 42
{:literal, [42], []}

# String in expression: "admin"
{:literal, ["admin"], []}

# Boolean: true
{:literal, [true], []}

# Null value
{:literal, [nil], []}
```

### 3. Expression Nodes

Represent variable interpolation and expressions in `{{ }}` blocks.

**Format:**
```elixir
{:expression, [expression_tuple], opts}
```

**Parameters:**
- `expression_tuple` - A parsed expression tuple (see Expression Types below)

**Examples:**
```elixir
# {{ $input.name }}
{:expression, [{:variable, ["$input", "name"], []}], []}

# {{- user.age >= 18 -}}
{:expression, [{:binary_op, [:>=, 
  {:variable, ["user", "age"], []}, 
  {:literal, [18], []}
], []}], [trim_left: true, trim_right: true]}
```

### 4. Tag Nodes

Represent control flow and other template tags in `{% %}` blocks.

**Format:**
```elixir
{:tag, [subtype, condition_or_params, body], opts}
```

**Parameters:**
- `subtype` - Tag type (`:if`, `:for`, `:assign`, etc.)
- `condition_or_params` - Parsed expression or parameters for the tag
- `body` - List of child AST nodes

**Examples:**
```elixir
# {% if user.active %}Content{% endif %}
{:tag, [:if, {:variable, ["user", "active"], []}, [
  {:text, ["Content"], []}
]], []}

# {%- for item in items -%}
{:tag, [:for, {:for_loop, ["item", {:variable, ["items"], []}, []], []}, [
  # body nodes...
]], [trim_left: true, trim_right: true]}
```

## Expression Types

All expressions use the unified tuple format and can be nested within each other.

### Variable Access

Access variables and object properties.

**Format:**
```elixir
{:variable, [path_segments], opts}
```

**Examples:**
```elixir
# $input
{:variable, ["$input"], []}

# user.name
{:variable, ["user", "name"], []}

# $input.users[0].email
{:variable, ["$input", "users", 0, "email"], []}

# $nodes.api_call.response.data
{:variable, ["$nodes", "api_call", "response", "data"], []}
```

### Binary Operations

Comparison and arithmetic operations between two expressions.

**Format:**
```elixir
{:binary_op, [operator, left_expr, right_expr], opts}
```

**Supported Operators:**
- Comparison: `:==`, `:!=`, `:>`, `:>=`, `:<`, `:<=`
- Arithmetic: `:+`, `:-`, `:*`, `:/`, `:%`
- String: `:contains`

**Examples:**
```elixir
# user.age >= 18
{:binary_op, [:>=, 
  {:variable, ["user", "age"], []}, 
  {:literal, [18], []}
], []}

# user.role == "admin"
{:binary_op, [:==,
  {:variable, ["user", "role"], []},
  {:literal, ["admin"], []}
], []}

# name contains "John"
{:binary_op, [:contains,
  {:variable, ["name"], []},
  {:literal, ["John"], []}
], []}
```

### Logical Operations

Boolean operations between expressions.

**Format:**
```elixir
{:logical_op, [operator, left_expr, right_expr], opts}
```

**Supported Operators:**
- `:and` - Logical AND
- `:or` - Logical OR

**Examples:**
```elixir
# user.active and user.age >= 18
{:logical_op, [:and,
  {:variable, ["user", "active"], []},
  {:binary_op, [:>=, 
    {:variable, ["user", "age"], []}, 
    {:literal, [18], []}
  ], []}
], []}

# role == "admin" or role == "moderator"
{:logical_op, [:or,
  {:binary_op, [:==, {:variable, ["role"], []}, {:literal, ["admin"], []}], []},
  {:binary_op, [:==, {:variable, ["role"], []}, {:literal, ["moderator"], []}], []}
], []}
```

### Call Expressions

Apply filters/functions using either pipe or function call syntax. Both syntaxes are unified into a single `:call` node where the function name is followed by all arguments in order.

**Format:**
```elixir
{:call, [function_name, arguments_list], opts}
```

**Examples:**

**Pipe Syntax Transformations:**
```elixir
# user.name | upper_case
{:call, ["upper_case", [{:variable, ["user", "name"], []}]], []}

# user.bio | truncate(50)
{:call, ["truncate", [
  {:variable, ["user", "bio"], []},
  {:literal, [50], []}
]], []}

# price | format_currency("USD") | round(2)
# Becomes nested calls:
{:call, ["round", [
  {:call, ["format_currency", [
    {:variable, ["price"], []},
    {:literal, ["USD"], []}
  ]], []},
  {:literal, [2], []}
]], []}
```

**Function Call Syntax:**
```elixir
# capitalize(user.name)
{:call, ["capitalize", [{:variable, ["user", "name"], []}]], []}

# truncate(user.bio, 50)
{:call, ["truncate", [
  {:variable, ["user", "bio"], []},
  {:literal, [50], []}
]], []}

# format_currency(price, "USD")
{:call, ["format_currency", [
  {:variable, ["price"], []},
  {:literal, ["USD"], []}
]], []}
```

### Array Literals

Array literals allow inline array construction within templates.

**Format:**
```elixir
{:literal, [array_elements], opts}
```

Where `array_elements` is a list of AST expression nodes that will be evaluated.

**Examples:**
```elixir
# Empty array: []
{:literal, [[]], []}

# Number array: [1, 2, 3]
{:literal, [
  [{:literal, [1], []}, {:literal, [2], []}, {:literal, [3], []}]
], []}

# String array: ["a", "b", "c"]
{:literal, [
  [{:literal, ["a"], []}, {:literal, ["b"], []}, {:literal, ["c"], []}]
], []}

# Mixed type array: [1, "two", true]
{:literal, [
  [{:literal, [1], []}, {:literal, ["two"], []}, {:literal, [true], []}]
], []}

# Array with variables: [user.name, user.email]
{:literal, [
  [{:variable, ["user", "name"], []}, {:variable, ["user", "email"], []}]
], []}

# Nested arrays: [[1, 2], [3, 4]]
{:literal, [
  [
    {:literal, [[{:literal, [1], []}, {:literal, [2], []}]], []},
    {:literal, [[{:literal, [3], []}, {:literal, [4], []}]], []}
  ]
], []}
```


## Tag Subtypes

### Control Flow Tags

**If/Elsif/Else:**
```elixir
# {% if condition %}...{% endif %}
{:tag, [:if, [
  {condition_expr, body_nodes}
]], opts}

# {% if a %}b{% elsif c %}d{% else %}e{% endif %}
{:tag, [:if, [
  {{:variable, ["a"], []}, [{:text, ["b"], []}]},
  {{:variable, ["c"], []}, [{:text, ["d"], []}]},
  {:else, [{:text, ["e"], []}]}
]], opts}

# Complex example with multiple elsif clauses
# {% if user.role == "admin" %}Admin{% elsif user.role == "mod" %}Moderator{% elsif user.active %}User{% else %}Guest{% endif %}
{:tag, [:if, [
  {{:binary_op, [:==, {:variable, ["user", "role"], []}, {:literal, ["admin"], []}], []}, [{:text, ["Admin"], []}]},
  {{:binary_op, [:==, {:variable, ["user", "role"], []}, {:literal, ["mod"], []}], []}, [{:text, ["Moderator"], []}]},
  {{:variable, ["user", "active"], []}, [{:text, ["User"], []}]},
  {:else, [{:text, ["Guest"], []}]}
]], opts}
```

**For Loops:**
```elixir
# {% for item in collection %}...{% endfor %}
{:tag, [:for, "item", {:variable, ["collection"], []}, body_nodes, []], opts}

# {% for user in users limit: 5 offset: 10 %}...{% endfor %}
{:tag, [:for, "user", {:variable, ["users"], []}, body_nodes, [limit: 5, offset: 10]], opts}

# {% for item in items limit: 20 %}...{% endfor %}
{:tag, [:for, "item", {:variable, ["items"], []}, body_nodes, [limit: 20]], opts}
```

### Utility Tags

**Assignment:**
```elixir
# {% assign name = value %}
{:tag, [:assign, "name", value_expr, []], opts}

# {% assign total = price + tax %}
{:tag, [:assign, "total", {:binary_op, [:+, 
  {:variable, ["price"], []}, 
  {:variable, ["tax"], []}
], []}, []], opts}
```

## Options (Keyword Lists)

All AST nodes support optional metadata via keyword lists.

### Whitespace Control Options

**trim_left** - `boolean()`
Remove whitespace before this node (from `{%-` or `{{-` syntax).

**trim_right** - `boolean()`  
Remove whitespace after this node (from `-%}` or `-}}` syntax).

**Examples:**
```elixir
# {%- if condition -%}
{:tag, [:if, condition, body], [trim_left: true, trim_right: true]}

# {{- variable -}}
{:expression, [variable_expr], [trim_left: true, trim_right: true]}
```

### Source Location Options

**line** - `integer()`
Source line number for error reporting.

**column** - `integer()`
Source column number for error reporting.

**source_file** - `String.t()`
Source template file path.

**Examples:**
```elixir
{:text, ["Hello"], [line: 1, column: 1]}
{:literal, [42], [line: 3, column: 15]}
{:expression, [expr], [line: 5, column: 10, source_file: "user.liquid"]}
```

### Performance Options

**cache_key** - `String.t()`
Cache key for expression evaluation.

**static** - `boolean()`
Mark expression as static (no variable dependencies).

**Examples:**
```elixir
{:literal, ["constant"], [static: true]}
{:expression, [complex_expr], [cache_key: "user_permissions_check"]}
```

### Error Handling Options

**strict_mode** - `boolean()`
Controls error handling behavior for incomplete expressions and undefined variables.

- `true` - Return errors for incomplete expressions and undefined variables
- `false` (default) - Graceful degradation (render incomplete expressions as-is, treat undefined variables as nil)

**Examples:**
```elixir
# With strict_mode: true, {{ undefined_var }} would error
{:expression, [{:variable, ["undefined_var"], []}], [strict_mode: true]}

# With strict_mode: false, incomplete {{ variable would render as-is
{:expression, [{:variable, ["variable"], []}], [strict_mode: false]}
```

## Complete AST Examples

### Simple Template
```liquid
Hello {{ user.name }}!
```

**AST:**
```elixir
[
  {:text, ["Hello "], []},
  {:expression, [{:variable, ["user", "name"], []}], []},
  {:text, ["!"], []}
]
```

### Conditional with Whitespace Control
```liquid
Users:
{%- for user in users -%}
  {{- user.name -}}
{%- endfor -%}
```

**AST:**
```elixir
[
  {:text, ["Users:\n"], []},
  {:tag, [:for, "user", {:variable, ["users"], []}, [
    {:text, ["\n  "], []},
    {:expression, [{:variable, ["user", "name"], []}], [trim_left: true, trim_right: true]},
    {:text, ["\n"], []}
  ], []], [trim_left: true, trim_right: true]}
]
```

### Complex Conditional Logic
```liquid
{% if user.age >= 18 and user.role == "admin" %}
  Welcome {{ user.name | upper_case }}!
{% endif %}
```

**AST:**
```elixir
[
  {:tag, [:if, [
    {{:logical_op, [:and,
      {:binary_op, [:>=, 
        {:variable, ["user", "age"], []}, 
        {:literal, [18], []}
      ], []},
      {:binary_op, [:==,
        {:variable, ["user", "role"], []},
        {:literal, ["admin"], []}
      ], []}
    ], []}, [
      {:text, ["\n  Welcome "], []},
      {:expression, [{:call, ["upper_case", [
        {:variable, ["user", "name"], []}
      ]], []}], []},
      {:text, ["!\n"], []}
    ]}
  ]], []}
]
```

## Implementation Guidelines

### AST Node Creation

**Use helper functions for creating nodes:**
```elixir
defmodule Prana.Template.V3.AST do
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

  def variable_expr(path, opts \\ []) do
    {:variable, path, opts}
  end
end
```

## Expression Types Reference

### Supported Filter Names

**String Filters:** `upper_case`, `lower_case`, `capitalize`, `truncate`, `default`

**Number Filters:** `round`, `format_currency`

**Collection Filters:** `length`, `first`, `last`, `join`, `sort`, `reverse`, `uniq`, `slice`, `contains`, `compact`, `flatten`, `sum`, `keys`, `values`, `group_by`, `map`, `filter`, `reject`, `dump`

**Math Filters:** `abs`, `ceil`, `floor`, `max`, `min`, `power`, `sqrt`, `mod`, `clamp`

## Future Extensions

Planned additions to the AST specification:

- **Object literals** - `{:object, [key_value_pairs], opts}` for inline map construction
- **Ternary operators** - `{:ternary, [condition, if_true, if_false], opts}`
- **Case/when statements** - `{:case, [switch_expr, when_clauses], opts}`
- **Custom tag extensions** - Plugin system for custom tag types

## Version History

- **v1.1** - Added array literal support with inline array construction
- **v1.0** - Initial AST specification with unified tuple format
- **v1.0** - Added whitespace control options
- **v1.0** - Defined expression type hierarchy
- **v1.0** - Specified tag subtypes and for loop parameters