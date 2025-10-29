# Variables Guide

Master variable access and assignment in templates.

## What are Variables?

Variables store data that you access in templates. They come from two sources:

1. **Context** - Data passed to the template
2. **Template Assignment** - Variables created in the template itself

## Accessing Variables from Context

The context is a map of data available to your template:

```elixir
context = %{
  "user" => %{"name" => "Alice"},
  "items" => [1, 2, 3]
}

Mau.render("{{ user.name }}", context)
# Output: "Alice"
```

### Simple Variable Access

```
{{ variable_name }}
```

Example:

```
context = %{"greeting" => "Hello"}
template = "{{ greeting }}"
# Output: "Hello"
```

### Property Access

Access properties with dot notation:

```
{{ user.name }}
{{ user.profile.email }}
{{ user.profile.contact.phone }}
```

Works with any nesting depth:

```
context = %{
  "user" => %{
    "name" => "Alice",
    "profile" => %{
      "contact" => %{
        "phone" => "555-1234"
      }
    }
  }
}

{{ user.profile.contact.phone }}
# Output: "555-1234"
```

### Array Access

Access array elements by index (0-based):

```
{{ items.0 }}    # First item
{{ items.1 }}    # Second item
{{ items.5 }}    # Sixth item
```

Example:

```
context = %{
  "colors" => ["red", "green", "blue"]
}

{{ colors.0 }}   # "red"
{{ colors.2 }}   # "blue"
```

### Mixed Nesting

Combine object and array access:

```
{{ categories.0.name }}
{{ users.2.profile.email }}
```

Example:

```
context = %{
  "categories" => [
    %{"name" => "Books"},
    %{"name" => "Videos"}
  ]
}

{{ categories.0.name }}    # "Books"
{{ categories.1.name }}    # "Videos"
```

## Undefined Variables

Accessing undefined variables returns empty string:

```
context = %{"greeting" => "Hello"}

{{ undefined_var }}    # Renders as "" (empty)
{{ greeting }}         # Renders as "Hello"
```

Safe navigation example:

```
{% if user.email %}
  Email: {{ user.email }}
{% else %}
  Email not provided
{% endif %}
```

## Creating Variables with Assign

Create or modify variables within templates using `{% assign %}`:

### Basic Assignment

```
{% assign greeting = "Hello" %}
{{ greeting }}    # Output: "Hello"
```

### Assigning Literal Values

```
{% assign name = "Alice" %}
{% assign age = 30 %}
{% assign active = true %}
{% assign items = [] %}
```

### Assigning from Other Variables

```
{% assign first_item = items.0 %}
{{ first_item }}
```

### Assigning from Expressions

```
{% assign total = price | plus(tax) %}
Total: {{ total }}
```

### Assigning from Filters

```
{% assign first_name = user.name | split(" ") | first %}
{{ first_name }}
```

## Variable Scope

Variables are available from the point of assignment onward:

```
Start: {{ greeting }}        {# Empty, not assigned yet #}

{% assign greeting = "Hello" %}

After: {{ greeting }}        {# "Hello", now assigned #}
```

### Loop Scope

Loop variables are available inside the loop and accessible via `forloop`:

```
{% for item in items %}
  Item: {{ item }}           {# Access current item #}
  Index: {{ forloop.index }} {# Access loop variable #}
{% endfor %}

Outside: {{ item }}          {# Still accessible #}
```

Variables created before the loop are accessible inside:

```
{% assign prefix = "Item: " %}
{% for item in items %}
  {{ prefix }}{{ item }}     {# Can use prefix inside loop #}
{% endfor %}
```

### Conditional Scope

Variables assigned in if branches are accessible after:

```
{% if condition %}
  {% assign greeting = "Hello" %}
{% endif %}

{{ greeting }}               {# Still accessible #}
```

## Common Patterns

### Store Calculated Value

```
{% assign item_count = items | length %}
You have {{ item_count }} items
```

### Extract from List

```
{% assign first = items | first %}
{% assign last = items | last %}

First: {{ first }}, Last: {{ last }}
```

### Format Data

```
{% assign full_name = user.first_name | plus(" ") | plus(user.last_name) %}
Name: {{ full_name }}
```

### Store Filter Result

```
{% assign sorted = items | sort %}
{% assign unique = sorted | uniq %}
```

### Conditional Assignment

```
{% if user.admin %}
  {% assign role = "Administrator" %}
{% elsif user.moderator %}
  {% assign role = "Moderator" %}
{% else %}
  {% assign role = "User" %}
{% endif %}

Role: {{ role }}
```

### Build Strings

```
{% assign greeting = "Welcome, " %}
{% assign greeting = greeting | plus(user.name) %}
{{ greeting }}    # "Welcome, Alice"
```

## Accessing Context Variables

Special context variables available in some contexts:

### Loop Context in Map Directives

When using map directives with `#map` or `#filter`:

```
%{
  "users" => %{
    "#map" => [
      "{{$users}}",
      %{"name" => "{{$loop.item.name}}"}
    ]
  }
}
```

**Available loop variables:**
- `$loop.item` - Current item
- `$loop.index` - Current index
- `$loop.parentloop` - Parent loop (in nested maps)

### Workflow Variables

In workflow contexts, special variables are available:

```
{{ $input }}        # Workflow input
{{ $nodes }}        # Node execution results
{{ $variables }}    # Workflow variables
{{ $context }}      # Execution context
```

## Type Preservation

By default, all rendered output is a string. Use `preserve_types: true` to maintain types:

```elixir
Mau.render("{{ count }}", %{"count" => 42})
# {:ok, "42"}  <- String

Mau.render("{{ count }}", %{"count" => 42}, preserve_types: true)
# {:ok, 42}  <- Number
```

This preserves types for single-value templates. Mixed content always returns strings:

```
Mau.render("Count: {{ 42 }}", %{}, preserve_types: true)
# {:ok, "Count: 42"}  <- Still a string (mixed content)
```

## Variable Naming

Variable names can contain letters, numbers, and underscores:

```
{{ user }}
{{ user_name }}
{{ firstName }}    {# Also works, no special camelCase handling #}
{{ user_1 }}
```

### Reserved Names

Some names have special meaning and should be avoided:

```
{% for item in items %}
  {{ item }}       {# OK - loop variable #}
  {{ forloop }}    {# OK - loop metadata #}
{% endfor %}
```

## Safe Variable Access

### Check Before Access

```
{% if user %}
  Name: {{ user.name }}
{% endif %}
```

### Use Filters Safely

```
{% if items %}
  Count: {{ items | length }}
{% else %}
  No items
{% endif %}
```

### Provide Defaults

```
{% assign name = user.name %}
{% if name %}
  Hello {{ name }}
{% else %}
  Hello Guest
{% endif %}
```

## Examples

### Complete Profile Example

```
{% assign full_name = user.first_name | plus(" ") | plus(user.last_name) %}
{% assign user_count = users | length %}
{% assign is_admin = user.role == "admin" %}

Profile:
- Name: {{ full_name }}
- Email: {{ user.email }}
- Admin: {{ is_admin }}
- Total Users: {{ user_count }}
```

### List Processing

```
{% assign active_users = users | where("active") %}
{% assign user_names = active_users | map("name") | sort %}

Active users: {{ user_names | join(", ") }}
Count: {{ user_names | length }}
```

### Calculated Values

```
{% assign subtotal = 100 %}
{% assign tax_rate = 0.08 %}
{% assign tax = subtotal | times(tax_rate) | round(2) %}
{% assign total = subtotal | plus(tax) %}

Subtotal: ${{ subtotal }}
Tax: ${{ tax }}
Total: ${{ total }}
```

### Loop with Variables

```
{% assign colors = "red,green,blue" | split(",") %}

{% for color in colors %}
  {% assign index = forloop.index %}
  {% assign is_first = forloop.first %}

  {% if is_first %}First: {% endif %}{{ color }}
{% endfor %}
```

## Troubleshooting

### Variable Not Displaying

**Problem:** Variable renders as empty string

**Solutions:**
1. Check variable exists in context
2. Check variable name spelling
3. Use if statement to debug:

```
{% if user %}User defined{% else %}User undefined{% endif %}
{% if user.name %}Name defined{% else %}Name undefined{% endif %}
```

### Type Confusion

**Problem:** Numbers render as strings

**Solution:** Use `preserve_types: true` option

```elixir
Mau.render("{{ count }}", %{"count" => 42}, preserve_types: true)
```

### Scope Issues

**Problem:** Variable not accessible after assignment

**Solution:** Assign before use

```
{% assign var = "value" %}
{{ var }}    # Now available
```

## Summary

| Operation | Syntax | Example |
|-----------|--------|---------|
| Access | `{{ var }}` | `{{ user }}` |
| Property | `{{ obj.prop }}` | `{{ user.name }}` |
| Array | `{{ array.0 }}` | `{{ items.0 }}` |
| Assign | `{% assign x = y %}` | `{% assign name = "Alice" %}` |
| Expression | `{% assign x = y \| filter %}` | `{% assign count = items \| length %}` |
| Conditional | `{% if var %}` | Check if defined |

## See Also

- [Template Syntax Guide](template-syntax.md) - Variable syntax details
- [Filters Guide](filters.md) - Using filters with variables
- [Control Flow Guide](control-flow.md) - Using variables in conditionals
