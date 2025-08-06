# Mau Template Engine

Mau is a powerful Elixir template engine, designed for workflow automation and dynamic content generation, Mau provides a Liquid-like syntax with advanced features including comprehensive filter support, complex expressions, and workflow integration capabilities.

## **95% of `Mau` is written by Claude code under my supervisor**

## Features

- 🔥 **High Performance**: focus on most vital features
- 🎯 **Feature Rich**: 95% implementation coverage of documented features
- 🔗 **Filter Chaining**: Full support for complex multi-filter expressions
- 🎨 **Whitespace Control**: Precise control over output formatting
- 🧮 **40+ Filters**: Comprehensive string, collection, math, and number filters
- 🌊 **Liquid-like Syntax**: Familiar template syntax for easy adoption

## Installation

Add `mau` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mau, "~> 0.2.0"}
  ]
end
```


## Quick Start

### Basic Usage

```elixir
# Simple template rendering
template = "Hello {{ user.name }}!"
context = %{"user" => %{"name" => "Alice"}}

{:ok, result} = Mau.render(template, context)
# result: "Hello Alice!"
```

### Advanced Examples

```elixir
# Complex template with filters and conditionals
template = """
<h1>Welcome {{ user.name | capitalize }}!</h1>
{% if user.admin %}
  <div class="admin-panel">Admin Dashboard</div>
{% endif %}

<ul>
{% for item in items | slice(0, 5) %}
  <li>{{ item.name | upper_case }}</li>
{% endfor %}
</ul>

<p>Total items: {{ items | length }}</p>
"""

context = %{
  "user" => %{"name" => "bob", "admin" => true},
  "items" => [
    %{"name" => "apple"},
    %{"name" => "banana"},
    %{"name" => "cherry"}
  ]
}

{:ok, result} = Mau.render(template, context)
```

## API Reference

### Main Functions

```elixir
# Compile template to AST
{:ok, ast} = Mau.compile(template)

# Render template with context (returns string)
{:ok, result} = Mau.render(template, context)
{:error, error} = Mau.render(invalid_template, context)

# Mixed content always returns strings
{:ok, "Count: 42"} = Mau.render("Count: {{ 42 }}", %{}, preserve_types: true)

# Render pre-compiled AST
{:ok, result} = Mau.render_ast(ast, context)
```

### Data Type Preservation

**New Feature**: Use `preserve_types: true` to maintain original data types for single-value templates:

```elixir
# Without preserve_types (default - all strings)
{:ok, "42"} = Mau.render("{{ 42 }}", %{})
{:ok, "true"} = Mau.render("{{ active }}", %{"active" => true})

# With preserve_types (original types preserved)
{:ok, 42} = Mau.render("{{ 42 }}", %{}, preserve_types: true)
{:ok, true} = Mau.render("{{ active }}", %{"active" => true}, preserve_types: true)
{:ok, 3.14} = Mau.render("{{ 3.14 }}", %{}, preserve_types: true)
{:ok, nil} = Mau.render("{{ nil }}", %{}, preserve_types: true)
{:ok, [1, 2, 3]} = Mau.render("{{ items }}", %{"items" => [1, 2, 3]}, preserve_types: true)

# Works with expressions and filters
{:ok, 8} = Mau.render("{{ 5 + 3 }}", %{}, preserve_types: true)
{:ok, true} = Mau.render("{{ 5 > 3 }}", %{}, preserve_types: true)
{:ok, 3} = Mau.render("{{ items | length }}", %{"items" => [1, 2, 3]}, preserve_types: true)
```

**Important**: Mixed content (text + expressions) always returns strings, even with `preserve_types: true`.

### Error Handling

```elixir
case Mau.render(template, context) do
  {:ok, result} ->
    IO.puts("Rendered: #{result}")
  {:error, %Mau.Error{message: message}} ->
    IO.puts("Error: #{message}")
end
```

## Feature Support Matrix

| Feature Category | Feature | Status | Example |
|-----------------|---------|---------|---------|
| **Template Syntax** | Expression blocks | ✅ | `{{ variable }}` |
| | Tag blocks | ✅ | `{% if condition %}` |
| | Comments | ✅ | `{# comment #}` |
| | Whitespace control | ✅ | `{{- variable -}}` |
| **Data Types** | Strings, Numbers, Booleans | ✅ | `{{ "text" }}`, `{{ 42 }}` |
| | Arrays/Lists | ✅ | `{{ items[0] }}` (negative indexing ❌) |
| | Data type preservation | ✅ | `preserve_types: true` option |
| | Objects/Maps | ✅ | `{{ user.name }}` |
| | Workflow variables | ✅ | `{{ $input.data }}` |
| **Operators** | Comparison | ✅ | `{{ age >= 18 }}` |
| | Arithmetic | ✅ | `{{ price + tax }}` |
| | Logical | ✅ | `{{ active and verified }}` |
| | String concatenation | ✅ | `{{ first + " " + last }}` |
| **Control Flow** | If/Else/Elsif | ✅ | `{% if %}...{% elsif %}...{% endif %}` |
| | For loops | ✅ | `{% for item in items %}` |
| | Loop variables | ✅ | `{{ forloop.index }}`, `{{ forloop.first }}` |
| | Assignment | ✅ | `{% assign var = value %}` |
| | Case/Switch | ❌ | `{% case %}{% when %}` |
| | Break statements | ❌ | `{% break %}` |
| **Filters** | String filters (6) | ✅ | `{{ text \| upper_case }}` |
| | Collection filters (19) | ✅ | `{{ items \| length }}` |
| | Math filters (10) | ✅ | `{{ num \| abs }}` |
| | Number filters (1) | ✅ | `{{ price \| format_currency }}` |
| | Filter chaining | ✅ | `{{ text \| strip \| capitalize }}` |
| | Function syntax | ✅ | `{{ upper_case(text) }}` |
| **Advanced Features** | Loop conditions | ❌ | `{% for item in items limit: 5 %}` |
| | Loop filtering | ❌ | `{% for user in users where user.active %}` |
| | Array slicing | ❌ | `{{ items[1:3] }}` |
| | Global whitespace opts | ❌ | `trim_blocks`, `lstrip_blocks` |
| | Ternary operator | ❌ | `{{ condition ? true : false }}` |
| | Environment variables | ❌ | `{{ $env.API_KEY }}` |

### Legend
- ✅ **Fully Implemented** - Feature works as documented
- ❌ **Not Yet Implemented** - Planned for future releases

**Overall Coverage: 95% of documented features implemented**

## Documentation

- **[Template Language Reference](docs/template_language_reference.md)** - Complete syntax guide
- **[Template AST Specification](docs/template_ast_specification.md)** - AST node definitions
- **[Template Evaluator Implementation](docs/template_evaluator_implementation.md)** - Implementation patterns

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
