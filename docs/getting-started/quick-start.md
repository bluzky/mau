# Quick Start

Get rendering in 5 minutes.

## Your First Template

The simplest Mau template is just plain text:

```elixir
{:ok, result} = Mau.render("Hello world", %{})
# result: "Hello world"
```

## Adding Variables

Use `{{ }}` to interpolate variables:

```elixir
template = "Hello {{ name }}!"
context = %{"name" => "Alice"}

{:ok, result} = Mau.render(template, context)
# result: "Hello Alice!"
```

## Accessing Properties

Access nested properties with dot notation:

```elixir
template = "{{ user.name }} is {{ user.age }} years old"
context = %{
  "user" => %{
    "name" => "Bob",
    "age" => 30
  }
}

{:ok, result} = Mau.render(template, context)
# result: "Bob is 30 years old"
```

## Using Filters

Transform values with filters using the pipe `|` syntax:

```elixir
template = "Welcome {{ user.name | capitalize }}!"
context = %{"user" => %{"name" => "alice"}}

{:ok, result} = Mau.render(template, context)
# result: "Welcome Alice!"
```

Chain multiple filters:

```elixir
template = "{{ message | strip | upper_case }}"
context = %{"message" => "  hello world  "}

{:ok, result} = Mau.render(template, context)
# result: "HELLO WORLD"
```

## Conditionals

Use `{% if %}` for conditional rendering:

```elixir
template = """
{% if user.active %}
  {{ user.name }} is active
{% endif %}
"""

context = %{"user" => %{"name" => "Charlie", "active" => true}}

{:ok, result} = Mau.render(template, context)
# result: "  Charlie is active\n"
```

Use `{% else %}` and `{% elsif %}`:

```elixir
template = """
{% if user.role == "admin" %}
  Admin Dashboard
{% elsif user.role == "user" %}
  User Dashboard
{% else %}
  Guest Area
{% endif %}
"""

context = %{"user" => %{"role" => "user"}}

{:ok, result} = Mau.render(template, context)
# result: "  User Dashboard\n"
```

## Loops

Iterate with `{% for %}`:

```elixir
template = """
<ul>
{% for item in items %}
  <li>{{ item.name }}</li>
{% endfor %}
</ul>
"""

context = %{
  "items" => [
    %{"name" => "Apple"},
    %{"name" => "Banana"},
    %{"name" => "Cherry"}
  ]
}

{:ok, result} = Mau.render(template, context)
```

Access loop information with `forloop`:

```elixir
template = """
{% for item in items %}
  {{ forloop.index }}: {{ item }}
{% endfor %}
"""

context = %{"items" => ["a", "b", "c"]}

{:ok, result} = Mau.render(template, context)
# result: "  1: a\n  2: b\n  3: c\n"
```

## Advanced: Map Directives

Transform nested maps with powerful directives:

```elixir
input = %{
  "users" => %{
    "#map" => [
      "{{$users}}",
      %{"name" => "{{$loop.item.name}}", "email" => "{{$loop.item.email}}"}
    ]
  }
}

context = %{
  "$users" => [
    %{"name" => "John", "email" => "john@example.com"},
    %{"name" => "Jane", "email" => "jane@example.com"}
  ]
}

{:ok, result} = Mau.render_map(input, context)
# result: %{
#   "users" => [
#     %{"name" => "John", "email" => "john@example.com"},
#     %{"name" => "Jane", "email" => "jane@example.com"}
#   ]
# }
```

## Common Operations

### Check Length of List

```elixir
template = "Items: {{ items | length }}"
context = %{"items" => [1, 2, 3]}

{:ok, result} = Mau.render(template, context)
# result: "Items: 3"
```

### Get First Item

```elixir
template = "First: {{ items | first }}"
context = %{"items" => ["a", "b", "c"]}

{:ok, result} = Mau.render(template, context)
# result: "First: a"
```

### Join List Items

```elixir
template = "Tags: {{ tags | join(', ') }}"
context = %{"tags" => ["elixir", "erlang", "otp"]}

{:ok, result} = Mau.render(template, context)
# result: "Tags: elixir, erlang, otp"
```

### Sort a List

```elixir
template = "{{ items | sort | join(', ') }}"
context = %{"items" => [3, 1, 2]}

{:ok, result} = Mau.render(template, context)
# result: "1, 2, 3"
```

## Next Steps

- [Basic Concepts](basic-concepts.md) - Learn core concepts
- [Your First Template](first-template.md) - Build a complete example
- [Template Language Reference](../reference/template-language.md) - Explore specific features
- [Email Templates Example](../examples/email-templates.md) - See real-world use cases

## Key Takeaways

✅ Use `{{ }}` for variables
✅ Use `{% %}` for control flow
✅ Chain filters with `|`
✅ Use `{{ }}` for arithmetic: `{{ 5 + 3 }}`
✅ Use `{{ }}` for comparisons: `{{ age > 18 }}`
✅ Filters transform data: `{{ text | upper_case }}`

You're ready to start using Mau! Try building a simple template and experiment with different features.
