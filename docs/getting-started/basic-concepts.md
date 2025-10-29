# Basic Concepts

Understand the core ideas behind Mau.

## What is Mau?

Mau is a **template engine** for Elixir. It takes a template string with special syntax and renders it to final output based on a context (a map of variables).

**Simple equation:**
```
Template + Context = Output
```

Example:
```
Template: "Hello {{ name }}!"
Context: %{"name" => "World"}
Output: "Hello World!"
```

## The Three Types of Content

Mau templates contain three types of content:

### 1. Plain Text
Regular text that appears as-is in the output:

```
Welcome to Mau!
```

This renders exactly as written.

### 2. Expressions (with `{{ }}`)
Expressions evaluate code and insert the result:

```
{{ user.name }}
{{ items | length }}
{{ 5 + 3 }}
```

Expressions:
- Access variables with `{{ variable_name }}`
- Access properties with `{{ object.property }}`
- Use filters with `{{ value | filter }}`
- Use expressions with `{{ 5 + 3 }}`

### 3. Tags (with `{% %}`)
Tags control logic but don't produce output themselves:

```
{% if condition %}
  This appears if true
{% endif %}

{% for item in items %}
  Process each item
{% endfor %}
```

Tags:
- `{% if %}` - Conditionals
- `{% for %}` - Loops
- `{% assign %}` - Variables
- Comments: `{# This is a comment #}`

## Context: Your Data

The **context** is a map that provides data to your template:

```elixir
context = %{
  "user" => %{
    "name" => "Alice",
    "email" => "alice@example.com",
    "age" => 30
  },
  "settings" => %{
    "theme" => "dark",
    "notifications" => true
  }
}
```

Access context data in templates:
- `{{ user.name }}` → "Alice"
- `{{ user.age }}` → 30
- `{{ settings.theme }}` → "dark"

## Variables

Variables store data that you reference in templates.

### Simple Variables

```elixir
context = %{"greeting" => "Hello"}
template = "{{ greeting }} World"
# Output: "Hello World"
```

### Nested Variables

```elixir
context = %{
  "user" => %{
    "profile" => %{
      "name" => "Bob"
    }
  }
}
template = "{{ user.profile.name }}"
# Output: "Bob"
```

### Array/List Access

```elixir
context = %{"items" => ["apple", "banana", "cherry"]}
template = "First: {{ items.0 }}, Last: {{ items.2 }}"
# Output: "First: apple, Last: cherry"
```

### Variable Assignment

Create variables in your template:

```elixir
template = """
{% assign greeting = "Hello" %}
{{ greeting }} World
"""
# Output: "Hello World"
```

## Filters: Transform Data

Filters modify values. Use the pipe `|` to apply them:

```
{{ value | filter_name }}
```

Common filters:

```elixir
{{ "hello" | capitalize }}      # "Hello"
{{ "HELLO" | lower_case }}      # "hello"
{{ [1, 2, 3] | length }}        # 3
{{ [3, 1, 2] | sort }}          # [1, 2, 3]
{{ "a,b,c" | split(",") }}      # ["a", "b", "c"]
{{ items | first }}             # First item
{{ items | last }}              # Last item
```

Chain multiple filters:

```
{{ text | strip | capitalize | upper_case }}
```

This applies filters left to right.

## Expressions: Calculate Values

Perform calculations and comparisons in `{{ }}`:

### Arithmetic

```elixir
{{ 5 + 3 }}              # 8
{{ 10 - 4 }}             # 6
{{ 3 * 4 }}              # 12
{{ 10 / 2 }}             # 5.0
```

### Comparisons

```elixir
{{ 5 > 3 }}              # true
{{ 5 < 3 }}              # false
{{ 5 == 5 }}             # true
{{ 5 != 3 }}             # true
{{ 5 >= 5 }}             # true
{{ 5 <= 10 }}            # true
```

### Logical Operations

```elixir
{{ true and false }}     # false
{{ true or false }}      # true
{{ not false }}          # true
```

### String Concatenation

```elixir
{{ "Hello " + "World" }} # "Hello World"
{{ first_name + " " + last_name }}
```

## Control Flow: If/Else

### Basic If

```elixir
{% if user.active %}
  User is active
{% endif %}
```

### If/Else

```elixir
{% if user.admin %}
  Admin Panel
{% else %}
  User Area
{% endif %}
```

### If/Elsif/Else

```elixir
{% if user.role == "admin" %}
  Admin
{% elsif user.role == "moderator" %}
  Moderator
{% else %}
  User
{% endif %}
```

## Loops: Iterate Collections

### For Loop

```elixir
{% for item in items %}
  {{ item }}
{% endfor %}
```

### Loop Variables

Access loop information with `forloop`:

```elixir
{% for item in items %}
  {{ forloop.index }}: {{ item }}
{% endfor %}
```

**Loop variables:**
- `forloop.index` - Current position (1-based)
- `forloop.index0` - Current position (0-based)
- `forloop.first` - true on first iteration
- `forloop.last` - true on last iteration
- `forloop.length` - Total count

### Nested Loops

```elixir
{% for category in categories %}
  {{ category.name }}:
  {% for item in category.items %}
    - {{ item }}
  {% endfor %}
{% endfor %}
```

## Truthy and Falsy

In conditionals, values are evaluated as truthy or falsy:

**Falsy values:**
- `false`
- `nil`
- `""` (empty string)
- `[]` (empty list)
- `{}` (empty map)

**Truthy values:**
- Everything else, including:
  - `true`
  - Non-empty strings: `"hello"`
  - Non-zero numbers: `5`, `-1`
  - Non-empty lists: `[1, 2, 3]`
  - Non-empty maps: `%{"key" => "value"}`

Example:

```elixir
{% if user.email %}
  Email: {{ user.email }}
{% endif %}
```

This renders only if `user.email` is not falsy.

## Comments

Comments are not rendered:

```elixir
{# This is a comment and won't appear in output #}

Template text

{# Comments can be multi-line
   and span across lines #}
```

## Whitespace Control

Control whitespace around expressions and tags:

```elixir
{{ name }}       {# Spaces around are preserved #}
{{- name }}      {# Trim left whitespace #}
{{ name -}}      {# Trim right whitespace #}
{{- name -}}     {# Trim both #}
```

Example:

```elixir
template = """
Items:
{% for item in items %}
  - {{ item }}
{% endfor %}
"""

# vs with whitespace control:
template = """
Items:
{%- for item in items %}
  - {{ item }}
{%- endfor %}
"""
```

## Type Preservation

By default, all template output is a string:

```elixir
Mau.render("{{ 42 }}", %{})
# {:ok, "42"}  <- string, not number
```

Enable type preservation to maintain types:

```elixir
Mau.render("{{ 42 }}", %{}, preserve_types: true)
# {:ok, 42}  <- number, not string

Mau.render("{{ active }}", %{"active" => true}, preserve_types: true)
# {:ok, true}  <- boolean preserved

Mau.render("{{ items }}", %{"items" => [1, 2, 3]}, preserve_types: true)
# {:ok, [1, 2, 3]}  <- list preserved
```

**Important:** Mixed content (text + expressions) always returns strings:

```elixir
Mau.render("Count: {{ 42 }}", %{}, preserve_types: true)
# {:ok, "Count: 42"}  <- string because it contains text
```

## Summary

| Concept | Syntax | Purpose |
|---------|--------|---------|
| **Text** | Plain text | Static content |
| **Expression** | `{{ value }}` | Insert dynamic data |
| **Filter** | `\| filter_name` | Transform data |
| **If** | `{% if condition %}` | Conditional rendering |
| **For** | `{% for item in list %}` | Iterate collections |
| **Assign** | `{% assign var = value %}` | Create variables |
| **Comment** | `{# comment #}` | Non-rendered text |

## Next Steps

- [Your First Template](first-template.md) - Build a complete example
- [Template Syntax Guide](../guides/template-syntax.md) - Detailed feature guides
- [Email Template Examples](../examples/email-templates.md) - Real-world use cases
