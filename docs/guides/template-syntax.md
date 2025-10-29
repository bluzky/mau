# Template Syntax Guide

Deep dive into Mau template syntax and language features.

## Overview

Mau templates use a simple three-part syntax:
- **Text** - Raw content (no special syntax)
- **Expressions** - `{{ ... }}` for dynamic values
- **Tags** - `{% ... %}` for control flow

## Expressions: `{{ }}`

Expressions evaluate code and insert results into the output.

### Variable Access

Access variables from context:

```
{{ user }}
{{ user.name }}
{{ user.profile.name }}
{{ items.0 }}
```

Nested property access works with both objects and arrays:

```elixir
context = %{
  "user" => %{"name" => "Alice"},
  "items" => ["a", "b", "c"]
}

{{ user.name }}      # "Alice"
{{ items.0 }}        # "a"
{{ items.2 }}        # "c"
```

### Arithmetic Expressions

Perform calculations:

```
{{ 5 + 3 }}          # 8
{{ 10 - 4 }}         # 6
{{ 3 * 4 }}          # 12
{{ 20 / 4 }}         # 5.0
{{ 17 % 5 }}         # 2 (modulo)
```

### String Concatenation

Combine strings with `+`:

```
{{ "Hello " + "World" }}     # "Hello World"
{{ first_name + " " + last_name }}
{{ "Item: " + item }}
```

### Comparison Operators

Compare values:

```
{{ 5 > 3 }}          # true
{{ 5 < 3 }}          # false
{{ 5 == 5 }}         # true
{{ 5 != 3 }}         # true
{{ 5 >= 5 }}         # true
{{ 5 <= 10 }}        # true
```

String comparison:

```
{{ "apple" == "apple" }}     # true
{{ "abc" < "def" }}          # true (alphabetical)
```

### Logical Operators

Combine conditions:

```
{{ true and false }}         # false
{{ true or false }}          # true
{{ not false }}              # true
{{ (5 > 3) and (10 < 20) }}  # true
```

### Filters

Transform values with filters (pipe `|`):

```
{{ user.name | capitalize }}
{{ text | upper_case | strip }}
{{ items | length }}
```

Multiple filters chain left-to-right:

```
{{ "  hello world  " | strip | capitalize }}
# 1. Strip: "hello world"
# 2. Capitalize: "Hello world"
# Result: "Hello world"
```

### Parentheses and Precedence

Use parentheses to control evaluation order:

```
{{ (5 + 3) * 2 }}    # (5 + 3) first = 16, not (5 + 6) = 11
{{ (true or false) and (5 > 3) }}
```

### Literal Values

Include literal values directly:

```
{{ "hello" }}        # String literal
{{ 42 }}             # Number literal
{{ 3.14 }}           # Float literal
{{ true }}           # Boolean
{{ false }}
{{ nil }}            # Null value
{{ [] }}             # Empty array
{{ {} }}             # Empty object
```

### Function Syntax (Alternative to Pipes)

Use function syntax as alternative to pipes:

```
{{ upper_case(name) }}           # Same as: {{ name | upper_case }}
{{ capitalize(user.name) }}      # Same as: {{ user.name | capitalize }}
```

With arguments:

```
{{ join(items, ", ") }}          # Same as: {{ items | join(", ") }}
{{ slice(items, 0, 3) }}         # Same as: {{ items | slice(0, 3) }}
```

## Tags: `{% %}`

Tags execute logic but don't produce output.

### If/Elsif/Else

Conditional rendering:

```
{% if condition %}
  Content when true
{% endif %}
```

With else:

```
{% if age >= 18 %}
  You can vote
{% else %}
  Too young
{% endif %}
```

With elsif:

```
{% if score >= 90 %}
  Grade: A
{% elsif score >= 80 %}
  Grade: B
{% elsif score >= 70 %}
  Grade: C
{% else %}
  Grade: F
{% endif %}
```

### For Loops

Iterate over collections:

```
{% for item in items %}
  {{ item }}
{% endfor %}
```

Access current item with variable name:

```
{% for user in users %}
  Name: {{ user.name }}
  Email: {{ user.email }}
{% endfor %}
```

Nested loops:

```
{% for category in categories %}
  Category: {{ category.name }}
  {% for item in category.items %}
    - {{ item }}
  {% endfor %}
{% endfor %}
```

### Loop Variables

Access loop metadata with `forloop`:

```
{% for item in items %}
  {{ forloop.index }}: {{ item }}
{% endfor %}
```

**Available variables:**
- `forloop.index` - Position (1-based)
- `forloop.index0` - Position (0-based)
- `forloop.first` - Boolean, true on first iteration
- `forloop.last` - Boolean, true on last iteration
- `forloop.length` - Total count

Example with loop variables:

```
{% for item in items %}
  {% if forloop.first %}
    First item: {{ item }}
  {% elsif forloop.last %}
    Last item: {{ item }}
  {% else %}
    Item {{ forloop.index }} of {{ forloop.length }}: {{ item }}
  {% endif %}
{% endfor %}
```

### Variable Assignment

Create or modify variables:

```
{% assign greeting = "Hello" %}
{{ greeting }} World
```

Assign from expressions:

```
{% assign total = items | length %}
Total items: {{ total }}
```

Assign from other variables:

```
{% assign first_item = items.0 %}
First: {{ first_item }}
```

### Comments

Comments are not rendered:

```
{# This is a comment #}

{# Multi-line comment
   spanning multiple lines
   in the template #}
```

Comments inside tags:

```
{% if user.active %}  {# Only show if active #}
  {{ user.name }}
{% endif %}
```

## Whitespace Handling

By default, whitespace around expressions and tags is preserved.

### Trimming Whitespace

Use `-` to trim whitespace:

```
{{ value }}       {# Preserves space #}
{{- value }}      {# Trim left #}
{{ value -}}      {# Trim right #}
{{- value -}}     {# Trim both #}
```

Example:

```
{%- if condition -%}
  Content
{%- endif -%}
```

This removes newlines and spaces around the tag.

### Common Whitespace Pattern

Remove unwanted newlines in loops:

```
{% for item in items -%}
  {{ item }}
{%- endfor %}
```

## Advanced Features

### Deeply Nested Access

Access any level of nesting:

```
{{ user.profile.contact.email }}
{{ data.categories.0.items.5.name }}
```

### Array Indexing

Access array elements by index (0-based):

```
{{ items.0 }}      # First
{{ items.1 }}      # Second
{{ items.2 }}      # Third
```

### Property with Numbers

Mix text and numbers:

```
{{ field_1 }}
{{ object[key] }}   # Note: bracket notation not fully supported
```

### Expression in Loop

Use full expressions in loops:

```
{% for item in items %}
  {% if item.price > 100 %}
    Expensive: {{ item.name }}
  {% endif %}
{% endfor %}
```

### Filter with Arguments

Pass arguments to filters:

```
{{ text | slice(0, 10) }}
{{ items | join(", ") }}
{{ items | sort | slice(0, 5) }}
```

## Data Types

### Strings

Use double quotes:

```
{{ "hello" }}
{{ 'hello' }}      # Single quotes also work
```

Escape quotes:

```
{{ "He said \"Hello\"" }}
```

### Numbers

Integers and floats:

```
{{ 42 }}
{{ 3.14 }}
{{ -5 }}
{{ 1e3 }}          # Scientific notation (1000)
```

### Booleans

```
{{ true }}
{{ false }}
{{ true and false }}
{{ not true }}
```

### Null

```
{{ nil }}
```

### Arrays

```
{{ [] }}           # Empty array
{{ [1, 2, 3] }}    # Array literal
{{ items.0 }}      # Access first
```

### Objects/Maps

```
{{ {} }}           # Empty map
{{ %{"key" => "value"} }}   # Map literal (in code)
```

## Escaping and Special Cases

### Special Characters

Regular text with special characters is safe:

```
Hello (world) [note] & special © symbols
```

### Quotes in Strings

```
{{ "It's working" }}
{{ "He said \"Hi\"" }}
```

## Common Patterns

### Conditional Rendering

```
{% if value %}
  Show when truthy
{% endif %}
```

### Alternative Text

```
{% if user.bio %}
  {{ user.bio }}
{% else %}
  No bio provided
{% endif %}
```

### Inline If (Using Text)

```
Status: {% if active %}Online{% else %}Offline{% endif %}
```

### Combining Operators

```
{% if user.active and user.verified %}
  Fully verified user
{% endif %}
```

### Safe Property Access

```
{% if user.profile %}
  {{ user.profile.name }}
{% endif %}
```

## Gotchas and Edge Cases

### Falsy Values

These are falsy:
- `nil`
- `false`
- `""` (empty string)
- `[]` (empty list)
- `{}` (empty map)

Everything else is truthy.

### Type Coercion

Comparison is strict:

```
{{ "42" == 42 }}   # false (string vs number)
{{ 0 == false }}   # false (number vs boolean)
```

### Whitespace in Expressions

Whitespace is ignored inside expressions:

```
{{ user . name }}    # OK (unusual but works)
{{ 5 + 3 }}          # OK
```

### Undefined Variables

Undefined variables render as empty strings:

```
{{ undefined_var }}  # Renders as ""
```

## Summary

| Feature | Syntax | Example |
|---------|--------|---------|
| Variable | `{{ var }}` | `{{ user.name }}` |
| Filter | `\| filter` | `\| capitalize` |
| Arithmetic | `+ - * /` | `{{ 5 + 3 }}` |
| Comparison | `> < == !=` | `{{ age > 18 }}` |
| Logic | `and or not` | `{{ active and verified }}` |
| If | `{% if %}...{% endif %}` | Check condition |
| For | `{% for x in y %}...{% endfor %}` | Iterate |
| Assign | `{% assign x = y %}` | Create variable |
| Comment | `{# text #}` | Non-rendered text |
| Trim | `{{- -}}` | Remove whitespace |

## See Also

- [Filters Guide](filters.md) - Filter reference
- [Control Flow Guide](control-flow.md) - Advanced conditionals
- [Whitespace Control Guide](whitespace-control.md) - Detailed whitespace handling
- [Variables Guide](variables.md) - Variable access patterns
