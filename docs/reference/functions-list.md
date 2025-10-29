# Built-in Functions Reference

Complete reference of all built-in functions available in Mau templates.

## Overview

In Mau, **filters and functions are the same thing**. Any filter can be used as a function call. Mau provides 40+ built-in functions organized into four categories:

- **String functions** (6) - Text manipulation
- **Collection functions** (18) - List and map operations
- **Math functions** (10) - Numerical operations
- **Type conversion** (via filters) - Dynamic typing

## Function Syntax

Functions can be called in two ways:

**Pipe syntax** (recommended):
```liquid
{{ value | function_name }}
{{ value | function_name: arg1, arg2 }}
```

**Function call syntax**:
```liquid
{{ function_name(value) }}
{{ function_name(value, arg1, arg2) }}
```

Both syntaxes are equivalent.

## Common Functions

### Type Conversion Functions

While Mau doesn't have explicit type conversion functions, values are automatically converted as needed:

```liquid
{{ "42" | abs }}           # String converts to number: 42
{{ 42 | upper_case }}      # Number converts to string: "42"
{{ list | length }}        # List length: integer
```

### Truthiness Testing

Test values for truthiness in conditionals:

```liquid
{% if value %}
  {{ value }} is truthy
{% endif %}
```

**Falsy values:**
- `nil` / `null`
- `false`
- Empty strings `""`
- Empty lists `[]`
- Empty maps `{}`

**Truthy values:**
- `true`
- Non-zero numbers (including `0.0`)
- Non-empty strings
- Non-empty lists
- Non-empty maps

### Value Checking Functions

Check if values match patterns:

```liquid
{{ value == "expected" }}     # Equality check
{{ value != "unexpected" }}   # Inequality check
{{ value > 10 }}              # Numeric comparison
{{ value and other_value }}   # Logical AND
{{ value or other_value }}    # Logical OR
{{ not value }}               # Logical NOT
```

## String Functions

### capitalize

Capitalizes the first letter of each word.

```liquid
{{ "hello world" | capitalize }}
# Output: "Hello World"
```

See [filters list](filters-list.md#capitalize) for details.

---

### default

Returns a default value if input is nil or empty.

```liquid
{{ missing_var | default: "Anonymous" }}
# Output: "Anonymous"
```

See [filters list](filters-list.md#default) for details.

---

### lower_case

Converts string to lowercase.

```liquid
{{ "HELLO" | lower_case }}
# Output: "hello"
```

See [filters list](filters-list.md#lower_case) for details.

---

### strip

Removes leading and trailing whitespace.

```liquid
{{ "  hello  " | strip }}
# Output: "hello"
```

See [filters list](filters-list.md#strip) for details.

---

### truncate

Truncates string to specified length.

```liquid
{{ "Hello World" | truncate: 8 }}
# Output: "Hello..."
```

See [filters list](filters-list.md#truncate) for details.

---

### upper_case

Converts string to uppercase.

```liquid
{{ "hello" | upper_case }}
# Output: "HELLO"
```

See [filters list](filters-list.md#upper_case) for details.

---

## Collection Functions

### compact

Removes nil values from a list.

```liquid
{{ values | compact }}
# Input: [1, nil, 2, nil, 3]
# Output: [1, 2, 3]
```

See [filters list](filters-list.md#compact) for details.

---

### contains

Checks if collection contains a value.

```liquid
{{ items | contains: "apple" }}
# Output: true
```

See [filters list](filters-list.md#contains) for details.

---

### dump

Formats data structure for debugging.

```liquid
{{ user | dump }}
# Output: "%{\"name\" => \"Alice\", \"age\" => 30}"
```

See [filters list](filters-list.md#dump) for details.

---

### filter

Filters list of maps by field value.

```liquid
{{ users | filter: "status", "active" }}
# Returns users where status == "active"
```

See [filters list](filters-list.md#filter) for details.

---

### first

Returns first element of collection.

```liquid
{{ items | first }}
# Input: ["a", "b", "c"]
# Output: "a"
```

See [filters list](filters-list.md#first) for details.

---

### flatten

Flattens nested lists.

```liquid
{{ matrix | flatten }}
# Input: [[1, 2], [3, 4]]
# Output: [1, 2, 3, 4]
```

See [filters list](filters-list.md#flatten) for details.

---

### group_by

Groups list of maps by field value.

```liquid
{{ users | group_by: "department" }}
# Groups users by department
```

See [filters list](filters-list.md#group_by) for details.

---

### join

Joins list elements into string.

```liquid
{{ tags | join: ", " }}
# Input: ["ruby", "python", "javascript"]
# Output: "ruby, python, javascript"
```

See [filters list](filters-list.md#join) for details.

---

### keys

Returns all keys from a map.

```liquid
{{ user | keys }}
# Input: %{"name" => "Alice", "email" => "alice@example.com"}
# Output: ["name", "email"]
```

See [filters list](filters-list.md#keys) for details.

---

### last

Returns last element of collection.

```liquid
{{ items | last }}
# Input: ["a", "b", "c"]
# Output: "c"
```

See [filters list](filters-list.md#last) for details.

---

### length

Returns number of elements in collection.

```liquid
{{ items | length }}
# Input: ["a", "b", "c"]
# Output: 3
```

See [filters list](filters-list.md#length) for details.

---

### map

Extracts field values from maps in a list.

```liquid
{{ users | map: "email" }}
# Extracts email from each user
```

See [filters list](filters-list.md#map) for details.

---

### reject

Filters list, removing items that match condition.

```liquid
{{ users | reject: "status", "inactive" }}
# Returns users where status != "inactive"
```

See [filters list](filters-list.md#reject) for details.

---

### reverse

Reverses order of collection.

```liquid
{{ items | reverse }}
# Input: [1, 2, 3]
# Output: [3, 2, 1]
```

See [filters list](filters-list.md#reverse) for details.

---

### slice

Returns slice of collection.

```liquid
{{ items | slice: 1, 2 }}
# Returns 2 elements starting at index 1
```

See [filters list](filters-list.md#slice) for details.

---

### sort

Sorts collection in ascending order.

```liquid
{{ numbers | sort }}
# Input: [3, 1, 4, 1, 5]
# Output: [1, 1, 3, 4, 5]
```

See [filters list](filters-list.md#sort) for details.

---

### sum

Sums numeric values in list.

```liquid
{{ prices | sum }}
# Input: [10, 20, 30]
# Output: 60
```

See [filters list](filters-list.md#sum) for details.

---

### uniq

Returns unique elements from list.

```liquid
{{ items | uniq }}
# Input: [1, 2, 2, 3, 3, 3]
# Output: [1, 2, 3]
```

See [filters list](filters-list.md#uniq) for details.

---

### values

Returns all values from a map.

```liquid
{{ user | values }}
# Input: %{"name" => "Alice", "email" => "alice@example.com"}
# Output: ["Alice", "alice@example.com"]
```

See [filters list](filters-list.md#values) for details.

---

## Math Functions

### abs

Returns absolute value of number.

```liquid
{{ -42 | abs }}
# Output: 42
```

See [filters list](filters-list.md#abs) for details.

---

### ceil

Rounds number up to nearest integer.

```liquid
{{ 3.2 | ceil }}
# Output: 4
```

See [filters list](filters-list.md#ceil) for details.

---

### clamp

Clamps number between min and max.

```liquid
{{ score | clamp: 0, 100 }}
# Returns score bounded by 0-100
```

See [filters list](filters-list.md#clamp) for details.

---

### floor

Rounds number down to nearest integer.

```liquid
{{ 3.9 | floor }}
# Output: 3
```

See [filters list](filters-list.md#floor) for details.

---

### max

Returns maximum value.

```liquid
{{ prices | max }}
# Returns highest price in list
```

See [filters list](filters-list.md#max) for details.

---

### min

Returns minimum value.

```liquid
{{ prices | min }}
# Returns lowest price in list
```

See [filters list](filters-list.md#min) for details.

---

### mod

Returns remainder of division.

```liquid
{{ 17 | mod: 5 }}
# Output: 2 (remainder)
```

See [filters list](filters-list.md#mod) for details.

---

### power

Raises number to specified power.

```liquid
{{ 2 | power: 3 }}
# Output: 8 (2³)
```

See [filters list](filters-list.md#power) for details.

---

### round

Rounds number to nearest integer.

```liquid
{{ 3.14159 | round: 2 }}
# Output: 3.14
```

See [filters list](filters-list.md#round) for details.

---

### sqrt

Returns square root of number.

```liquid
{{ 16 | sqrt }}
# Output: 4
```

See [filters list](filters-list.md#sqrt) for details.

---

## Function Composition

Functions are most powerful when composed together:

### Chaining Functions

```liquid
{{ price | round: 2 | abs }}
```

### Using in Conditionals

```liquid
{% if items | length > 5 %}
  Too many items!
{% endif %}
```

### Using in Assignments

```liquid
{% assign total = prices | sum %}
Total price: {{ total }}
```

### Complex Expressions

```liquid
{{ items
  | filter: "available", true
  | map: "price"
  | sum
  | round: 2
}}
```

## Differences from Other Template Languages

### Syntax Flexibility

Mau allows both pipe and function call syntax:

```liquid
{# Pipe syntax (preferred in Mau) #}
{{ value | upper_case | truncate: 20 }}

{# Function call syntax (also works) #}
{{ upper_case(truncate(value, 20)) }}
```

### Type Coercion

Mau automatically converts types as needed:

```liquid
{{ "42" + 8 }}         # Converts string to number: 50
{{ 42 | upper_case }}  # Converts number to string: "42"
```

### Nil-Safe Access

Undefined values gracefully degrade:

```liquid
{{ user.address.city }}
# Returns nil if user, address, or city don't exist
```

## Error Handling

When functions encounter errors:

**Type Errors:**
```liquid
{{ "not a number" | abs }}
# Error: abs can only be applied to numbers
```

**Missing Arguments:**
```liquid
{{ items | truncate }}
# Error: truncate requires a length parameter
```

**Division by Zero:**
```liquid
{{ 10 | mod: 0 }}
# Error: mod by zero is undefined
```

## Performance Considerations

### Function Performance

1. **Filters are optimized** - Use filters in templates for best performance
2. **Short-circuit evaluation** - Logical operators stop early when result is determined
3. **Lazy evaluation** - Expressions only evaluated when needed

### Best Practices

```liquid
{# Good: Simple operations #}
{{ value | upper_case | truncate: 20 }}

{# Still good: Single complex filter #}
{{ items | group_by: "category" }}

{# Be careful: Very long chains may impact performance #}
{{ items | filter: "x", 1 | map: "y" | filter: "z", 2 | sum }}
```

## Extending with Custom Functions

Create custom filters to extend Mau with domain-specific functions:

```elixir
defmodule MyFilters do
  def spec do
    %{
      category: :custom,
      filters: %{
        "my_function" => %{
          description: "My custom function",
          function: {__MODULE__, :my_function}
        }
      }
    }
  end

  def my_function(value, args) do
    {:ok, "result"}
  end
end
```

See [Custom Filters Guide](../advanced/custom-filters.md) for more details.

## Quick Reference Table

| Function | Category | Use Case |
|----------|----------|----------|
| `upper_case`, `lower_case` | String | Change text case |
| `capitalize`, `truncate` | String | Format text |
| `strip`, `default` | String | Clean input |
| `length`, `first`, `last` | Collection | Access collection |
| `sort`, `reverse`, `uniq` | Collection | Sort/deduplicate |
| `filter`, `reject`, `map` | Collection | Transform lists |
| `join`, `slice`, `flatten` | Collection | Restructure |
| `sum`, `max`, `min` | Math | Aggregate numbers |
| `abs`, `ceil`, `floor`, `round` | Math | Round numbers |
| `power`, `sqrt`, `mod`, `clamp` | Math | Math operations |

## See Also

- [Filters List](filters-list.md) - Complete filters reference with examples
- [Filters Guide](../guides/filters.md) - How to use and chain filters
- [Template Syntax](../guides/template-syntax.md) - Template language basics
- [Custom Filters](../advanced/custom-filters.md) - Create your own functions
- [Control Flow](../guides/control-flow.md) - Using functions in conditionals
