# Elixir API Reference

Complete reference for the Mau template engine Elixir API.

## Overview

The Mau library provides a clean, functional API for template compilation and rendering. All functions use Elixir's standard error handling with `{:ok, result}` and `{:error, reason}` tuples.

## Main Module: Mau

The main entry point for all template operations.

### Mau.compile/2

Compiles a template string into an Abstract Syntax Tree (AST).

**Signature:**
```elixir
def compile(template, opts \\ []) :: {:ok, ast} | {:ok, ast, warnings} | {:error, Error.t()}
```

**Parameters:**
- `template` (string) - Template source code to compile
- `opts` (keyword list, optional):
  - `:strict_mode` - Return errors for invalid templates (default: false)
  - `:max_template_size` - Maximum allowed template size in bytes (default: 100,000)

**Return Values:**
- `{:ok, ast}` - Successfully compiled AST. Without strict mode, an invalid template compiles to a single text node holding its source.
- `{:ok, ast, []}` - Successfully compiled AST in strict mode
- `{:error, error}` - Size limit exceeded, or an invalid template in strict mode

**Examples:**

```elixir
# Simple compilation
{:ok, ast} = Mau.compile("Hello {{ name }}")

# With options
{:ok, ast, []} = Mau.compile(template, strict_mode: true)

# Error handling
case Mau.compile(invalid_template, strict_mode: true) do
  {:ok, ast, _warnings} -> IO.inspect(ast)
  {:error, error} -> IO.puts("Compilation failed: #{Mau.Error.format(error)}")
end
```

**See Also:**
- [AST Specification](ast-specification.md) - Structure of compiled templates

---

### Mau.render/3

Renders a template string or pre-compiled AST with the given context.

**Signature:**
```elixir
def render(template, context, opts \\ []) :: {:ok, result} | {:error, Error.t()}
```

**Parameters:**
- `template` (string or AST) - Template source or compiled AST
- `context` (map) - Data context for variable substitution
- `opts` (keyword list, optional):
  - `:preserve_types` - Preserve non-string types for single-value templates (default: false)
  - `:max_template_size` - Maximum template size in bytes (default: 100,000)
  - `:max_loop_iterations` - Maximum iterations in loops (default: 10,000)

**Return Values:**
- `{:ok, result}` - Rendered output (string, or original type with `preserve_types: true`)
- `{:error, error}` - Rendering error

**Examples:**

```elixir
# Basic rendering
{:ok, output} = Mau.render("Hello {{ name }}", %{"name" => "World"})
# Output: "Hello World"

# Rendering with pre-compiled AST
{:ok, ast} = Mau.compile(template)
{:ok, output} = Mau.render(ast, context)

# Preserving data types
{:ok, result} = Mau.render("{{ 42 }}", %{}, preserve_types: true)
# Result: 42 (integer, not "42" string)

# Boolean preservation
{:ok, result} = Mau.render("{{ user.active }}",
  %{"user" => %{"active" => true}},
  preserve_types: true)
# Result: true (boolean)

# Mixed content always returns string
{:ok, output} = Mau.render("Count: {{ items | length }}",
  %{"items" => [1, 2, 3]},
  preserve_types: true)
# Output: "Count: 3" (string)

# Error handling
case Mau.render(template, context) do
  {:ok, output} -> IO.puts(output)
  {:error, error} -> IO.puts("Render failed: #{Mau.Error.format(error)}")
end

# With options
{:ok, output} = Mau.render(template, context,
  preserve_types: true,
  max_loop_iterations: 5000)
```

**Behavior:**

- **Type Preservation**: When `preserve_types: true`:
  - Single-value templates render to their native type (number, boolean, etc.)
  - Mixed content (text + expressions) always renders to string
  - Undefined variables return nil

- **Invalid Templates**: Invalid syntax, unclosed blocks and stray block tags:
  - By default, the output is the original template string
  - With `strict_mode: true`, the result is `{:error, error}` of type `:syntax`

- **Render Errors**: Failures such as division by zero return `{:error, error}` in both modes

- **Undefined Variables**: Render as empty strings in both modes, and no error is returned

**See Also:**
- [Template Language Reference](template-language.md) - Template syntax
- [Filters List](filters-list.md) - Available filters

---

### Mau.render_map/3

Recursively renders template strings in nested map structures with support for transformation directives.

**Signature:**
```elixir
def render_map(nested_map, context, opts \\ []) :: {:ok, result} | {:error, Error.t()}
```

**Parameters:**
- `nested_map` (map) - Nested map structure containing template strings
- `context` (map) - Data context for variable substitution
- `opts` (keyword list, optional):
  - `:preserve_types` - Preserve data types in results (default: true)
  - `:max_template_size` - Maximum template size (default: 100,000)
  - `:max_loop_iterations` - Maximum loop iterations (default: 10,000)

**Return Values:**
- `{:ok, result}` - Rendered map with all template strings processed
- `{:error, error}` - Rendering error

**Directives:**

Map keys starting with `#` trigger transformation directives:

| Directive | Purpose | Syntax |
|-----------|---------|--------|
| `#map` | Iterate over collections | `"#map" => [collection, template]` |
| `#filter` | Filter collections | `"#filter" => [collection, condition]` |
| `#merge` | Combine maps | `"#merge" => [map1, map2, ...]` |
| `#if` | Conditional rendering | `"#if" => [condition, true_tmpl, false_tmpl]` |
| `#pick` | Extract specific keys | `"#pick" => [map, key_list]` |
| `#pipe` | Thread through transformations | `"#pipe" => [initial, directives]` |

**Examples:**

```elixir
# Simple map rendering
input = %{
  "greeting" => "Hello {{ name }}!",
  "count" => "{{ items | length }}"
}
context = %{"name" => "Alice", "items" => [1, 2, 3]}
{:ok, result} = Mau.render_map(input, context)
# Result: %{
#   "greeting" => "Hello Alice!",
#   "count" => "3"
# }

# Using #map directive
input = %{
  "users" => %{
    "#map" => [
      "{{$users}}",
      %{"name" => "{{$loop.item.name}}"}
    ]
  }
}
context = %{
  "$users" => [
    %{"name" => "Alice"},
    %{"name" => "Bob"}
  ]
}
{:ok, result} = Mau.render_map(input, context)

# Using #filter directive
input = %{
  "active_users" => %{
    "#filter" => [
      "{{$users}}",
      "{{$loop.item.active}}"
    ]
  }
}

# Using #merge directive
input = %{
  "profile" => %{
    "#merge" => [
      "{{$user}}",
      %{"verified" => true}
    ]
  }
}

# Using #if directive
input = %{
  "status" => %{
    "#if" => [
      "{{$premium}}",
      %{"level" => "premium"},
      %{"level" => "free"}
    ]
  }
}

# Using #pipe for data transformation
input = %{
  "result" => %{
    "#pipe" => [
      "{{$items}}",
      [
        %{"#filter" => "{{$loop.item.price > 100}}"},
        %{"#map" => %{"name" => "{{$loop.item.name}}"}}
      ]
    ]
  }
}

# Error handling
case Mau.render_map(nested_data, context) do
  {:ok, result} -> IO.inspect(result)
  {:error, error} -> IO.puts("Map render failed: #{Mau.Error.format(error)}")
end
```

**Context Variables in Directives:**

Special variables available in template strings within directives:

```
{{$self}}              # The piped value (in #pipe directive)
{{$loop.item}}         # Current item in #map or #filter
{{$loop.index}}        # Current item index (0-based)
{{$loop.first}}        # Is first item? (boolean)
{{$loop.parentloop}}   # Parent loop info (in nested loops)
```

**See Also:**
- [Map Directives Reference](map-directives.md) - Complete directive documentation

---

## Supporting Modules

### Mau.Error

Handles error types and messages.

**Functions:**

#### Mau.Error.runtime_error/1

Creates a runtime error with a custom message.

```elixir
Mau.Error.runtime_error("Template error message")
```

---

### Mau.FilterRegistry

Manages available filters (functions).

**Functions:**

#### Mau.FilterRegistry.apply/3

Applies a filter to a value.

**Signature:**
```elixir
def apply(filter_name, value, args \\ []) ::
  {:ok, result} | {:error, :filter_not_found | {:filter_error, reason}}
```

**Examples:**

```elixir
# Apply a simple filter
{:ok, result} = Mau.FilterRegistry.apply("upper_case", "hello", [])
# Result: "HELLO"

# Apply filter with arguments
{:ok, result} = Mau.FilterRegistry.apply("truncate", "Hello World", [8])
# Result: "Hello..."

# Error handling
case Mau.FilterRegistry.apply("upper_case", 123, []) do
  {:ok, result} -> IO.puts(result)
  {:error, :filter_not_found} -> IO.puts("Filter not found")
  {:error, {:filter_error, reason}} -> IO.puts("Filter error: #{reason}")
end
```

**Available Filters:**

All filters from the three filter modules:
- String filters: 6 filters
- Collection filters: 18 filters
- Math filters: 10 filters

See [Filters List](filters-list.md) for complete reference.

---

#### Mau.FilterRegistry.get/1

Gets a filter function by name.

**Signature:**
```elixir
def get(filter_name) :: {:ok, {module, function}} | {:error, :not_found}
```

**Examples:**

```elixir
# Get filter function
{:ok, {module, function}} = Mau.FilterRegistry.get("upper_case")

# Error handling
case Mau.FilterRegistry.get("upper_case") do
  {:ok, {mod, func}} -> :io.format("Filter: ~w:~w~n", [mod, func])
  {:error, :not_found} -> IO.puts("Filter not found")
end
```

---

### Mau.MapDirectives

Handles transformation directives in maps.

**Functions:**

#### Mau.MapDirectives.match_directive/1

Identifies if a map contains a supported directive.

**Signature:**
```elixir
def match_directive(map) :: {directive_type, args} | :none
```

**Examples:**

```elixir
# Check for directive
case Mau.MapDirectives.match_directive(%{"#map" => [collection, template]}) do
  {:map, args} -> IO.inspect(args)
  :none -> IO.puts("Not a directive")
end
```

---

#### Mau.MapDirectives.apply_directive/4

Applies a directive to transform data.

**Signature:**
```elixir
def apply_directive(directive, context, opts, render_fn) :: result
```

**Directives:**

- `:map` - Iterate over collection
- `:filter` - Filter collection items
- `:merge` - Merge maps
- `:if` - Conditional rendering
- `:pick` - Extract keys
- `:pipe` - Pipeline transformations

---

## Data Types

### AST (Abstract Syntax Tree)

Templates compile to AST represented as tuples.

**Node Structure:**
```elixir
{node_type, content, options}
```

**Node Types:**
- `:text` - Literal text content
- `:expression` - Variable interpolation
- `:tag` - Control flow (if/for)
- `:literal` - Constant values
- `:variable` - Variable reference
- `:binary_op` - Binary operations
- `:logical_op` - Logical operations
- `:call` - Function/filter calls

**Example:**
```elixir
{:ok, ast} = Mau.compile("Hello {{ name | upper_case }}")
# AST structure:
# [
#   {:text, ["Hello "], []},
#   {:expression,
#     {:call, ["upper_case",
#       {:variable, ["name"], []}
#     ], []},
#   []}
# ]
```

**See Also:**
- [AST Specification](ast-specification.md) - Complete AST documentation

---

### Context Map

The context is a standard Elixir map containing variables for template rendering.

**Structure:**
```elixir
%{
  "variable_name" => value,
  "user" => %{
    "name" => "Alice",
    "email" => "alice@example.com"
  },
  "$workflow_var" => workflow_value
}
```

**Variable Naming:**
- Regular variables: `"name"`, `"user"`, etc.
- Workflow variables: `"$input"`, `"$nodes"`, `"$variables"`, `"$context"`
- Both strings and atoms are supported as keys

**Examples:**

```elixir
# Simple context
context = %{"name" => "Alice", "age" => 30}

# Nested context
context = %{
  "user" => %{
    "name" => "Bob",
    "profile" => %{
      "bio" => "Developer"
    }
  }
}

# With workflow variables
context = %{
  "$input" => %{"email" => "user@example.com"},
  "$nodes" => %{
    "fetch_user" => %{"output" => user_data}
  },
  "$variables" => %{"api_key" => "secret"}
}
```

---

## Error Handling

All Mau functions follow Elixir's standard error handling pattern.

**Error Structure:**
```elixir
{:error, %Mau.Error{type: type, message: message, line: line, column: column}}
```

Errors can't be interpolated into a string directly. Use `error.message` or `Mau.Error.format(error)`.

**Error Types:**
- `:syntax` - Invalid templates, returned only with `strict_mode: true`. `line` and `column` are set for invalid syntax, but not for unclosed blocks or stray block tags.
- `:runtime` - Everything else, including filter errors, size limits (`max_template_size`) and loop limits (`max_loop_iterations`)

**Example Error Handling:**

```elixir
case Mau.render(template, context) do
  {:ok, output} ->
    IO.puts("Success: #{output}")

  {:error, error} ->
    IO.puts("Error: #{Mau.Error.format(error)}")
    # Log error, send to error tracking, etc.
end

# Treat invalid templates as errors
case Mau.render(template, context, strict_mode: true) do
  {:ok, output} -> output
  {:error, %Mau.Error{type: :syntax} = error} -> handle_invalid_template(error)
  {:error, error} -> handle_render_error(error)
end
```

Mau returns errors rather than raising them, so `rescue` isn't needed around `compile/2`, `render/3` or `render_map/3`.

---

## Options Reference

### Mau.compile/2 Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `strict_mode` | boolean | false | Return errors for invalid templates |
| `max_template_size` | integer | 100,000 | Maximum template size in bytes |

### Mau.render/3 Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `preserve_types` | boolean | false | Preserve non-string types for single values |
| `strict_mode` | boolean | false | Return errors for invalid templates |
| `max_template_size` | integer | 100,000 | Maximum template size in bytes |
| `max_loop_iterations` | integer | 10,000 | Maximum iterations in loops |

### Mau.render_map/3 Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `preserve_types` | boolean | true | Preserve non-string types in results |
| `strict_mode` | boolean | false | Fail the whole map if any value fails, instead of keeping that value's template string |
| `max_template_size` | integer | 100,000 | Maximum template size in bytes |
| `max_loop_iterations` | integer | 10,000 | Maximum iterations in loops |

---

## Common Patterns

### Compile Once, Render Many

For performance, compile templates once and reuse the AST:

```elixir
# Compile once
{:ok, template_ast} = Mau.compile(template_string)

# Render multiple times with different contexts
contexts = [
  %{"name" => "Alice"},
  %{"name" => "Bob"},
  %{"name" => "Charlie"}
]

results = Enum.map(contexts, fn context ->
  case Mau.render(template_ast, context) do
    {:ok, output} -> output
    {:error, _} -> nil
  end
end)
```

### Pipeline Processing

Render templates as part of data processing pipelines:

```elixir
data
|> Enum.map(&preprocess/1)
|> Enum.map(&render_with_context/1)
|> Enum.filter(&valid?/1)
|> Enum.map(&postprocess/1)

defp render_with_context(data) do
  case Mau.render(data.template, data.context) do
    {:ok, output} -> %{data | output: output}
    {:error, error} -> %{data | error: error}
  end
end
```

### Type-Safe Data Transformation

Use `preserve_types: true` for type-safe transformations:

```elixir
# Extract numeric values from templates
{:ok, price} = Mau.render("{{ product.price }}",
  %{"product" => %{"price" => 29.99}},
  preserve_types: true)

# Safely use as number
total = price * quantity  # No conversion needed

# Extract booleans
{:ok, is_active} = Mau.render("{{ user.active }}",
  context,
  preserve_types: true)

if is_active do
  # ...
end
```

---

## Performance Considerations

### Template Compilation

- **Compile once, render many times** - Compilation is the expensive operation
- **Reuse AST** - Pass compiled AST to render instead of template string
- **Cache compiled templates** - Store AST in ETS or application state

### Filter Performance

- **Filters are optimized** - Implemented in native Elixir
- **Avoid long chains** - Chain filters efficiently but readably
- **Consider custom filters** - For domain-specific high-performance transformations

### Loop Performance

- **Set `max_loop_iterations`** - Prevent runaway loops in user input
- **Use `#pipe` for complex transforms** - More efficient than nested `#map` directives
- **Profile with `:benchee`** - Measure performance of templates

---

## Version Compatibility

- **Elixir**: 1.12+
- **Erlang**: 23+
- **OTP**: 23+

---

## See Also

- [Template Language Reference](template-language.md) - Complete syntax documentation
- [Filters List](filters-list.md) - All available filters
- [Map Directives](map-directives.md) - Directive system reference
- [AST Specification](ast-specification.md) - AST structure details
- [Filters Guide](../guides/filters.md) - How to use filters effectively
- [Custom Filters](../advanced/custom-filters.md) - Extend with custom filters
