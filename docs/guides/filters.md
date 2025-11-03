# Filters Guide

Master using filters to transform data in templates.

## What are Filters?

Filters transform values using the pipe `|` syntax:

```
{{ value | filter_name }}
```

Filters take a value and optionally arguments, returning a transformed result.

## Filter Syntax

### Basic Filter

```
{{ "hello" | capitalize }}    # "Hello"
```

### Filter with Arguments

```
{{ items | slice(0, 3) }}
{{ text | join(", ") }}
```

### Chaining Filters

Apply multiple filters in sequence:

```
{{ text | strip | capitalize | upper_case }}
```

Filters execute left-to-right:
1. `strip` - Remove whitespace
2. `capitalize` - First letter uppercase
3. `upper_case` - All uppercase

### Function Syntax

Use function syntax as alternative to pipes:

```
{{ capitalize(text) }}           # Same as {{ text | capitalize }}
{{ slice(items, 0, 3) }}         # Same as {{ items | slice(0, 3) }}
{{ join(items, ", ") }}          # Same as {{ items | join(", ") }}
```

## String Filters

Transform and manipulate strings.

### capitalize

Capitalize first character:

```
{{ "hello world" | capitalize }}     # "Hello world"
{{ "HELLO" | capitalize }}           # "HELLO" (already uppercase)
```

### upcase (upper_case)

Convert to uppercase:

```
{{ "hello" | upper_case }}           # "HELLO"
{{ "Hello World" | upper_case }}     # "HELLO WORLD"
```

### downcase (lower_case)

Convert to lowercase:

```
{{ "HELLO" | lower_case }}           # "hello"
{{ "Hello World" | lower_case }}     # "hello world"
```

### strip

Remove leading and trailing whitespace:

```
{{ "  hello  " | strip }}            # "hello"
{{ "  hello world  " | strip }}      # "hello world"
```

### strip_newlines

Remove newline characters:

```
{{ "hello\nworld" | strip_newlines }}     # "helloworld"
{{ "line1\nline2\nline3" | strip_newlines }}  # "line1line2line3"
```

### split

Split string into array:

```
{{ "apple,banana,cherry" | split(",") }}    # ["apple", "banana", "cherry"]
{{ "a.b.c" | split(".") }}                  # ["a", "b", "c"]
```

### join

Join array into string:

```
{{ items | join(", ") }}           # "apple, banana, cherry"
{{ items | join(" | ") }}          # "apple | banana | cherry"
{{ items | join("") }}             # "applebananaacherry"
```

### reverse

Reverse a string or array:

```
{{ "hello" | reverse }}            # "olleh"
{{ items | reverse }}              # Reversed array
```

### slice

Extract substring or array portion:

```
{{ "hello" | slice(0, 3) }}        # "hel"
{{ items | slice(0, 2) }}          # First 2 items
{{ items | slice(1, 3) }}          # Items at index 1-2
```

### truncate

Shorten string with ellipsis:

```
{{ "hello world" | truncate(5) }}      # "he..."
{{ text | truncate(20) }}              # Truncate at 20 chars
{{ text | truncate(20, "...") }}       # Custom suffix
```

### replace

Replace text:

```
{{ "hello world" | replace("world", "there") }}    # "hello there"
{{ "a,b,c" | replace(",", "-") }}                  # "a-b-c"
```

## Array/Collection Filters

Work with lists and collections.

### length

Get array length:

```
{{ items | length }}               # Number of items
{{ items | length | plus(1) }}     # Chain with other filters
```

### first

Get first item:

```
{{ items | first }}                # First item
{{ ["a", "b", "c"] | first }}      # "a"
```

### last

Get last item:

```
{{ items | last }}                 # Last item
{{ ["a", "b", "c"] | last }}       # "c"
```

### join

Join items with separator (see String Filters above):

```
{{ items | join(", ") }}           # "a, b, c"
```

### map

Transform each item (creates new array):

```
{{ users | map("name") }}          # Extract name from each user
```

With property access:

```
context = %{
  "users" => [
    %{"name" => "Alice", "age" => 30},
    %{"name" => "Bob", "age" => 25}
  ]
}

{{ users | map("name") }}          # ["Alice", "Bob"]
```

### sort

Sort array:

```
{{ items | sort }}                 # [1, 2, 3, 4, 5]
{{ names | sort }}                 # ["Alice", "Bob", "Charlie"]
```

### reverse

Reverse array (see String Filters above):

```
{{ items | reverse }}              # Reversed
```

### uniq

Remove duplicates:

```
{{ [1, 2, 2, 3, 3, 3] | uniq }}   # [1, 2, 3]
```

### compact

Remove nil/empty values:

```
{{ [1, nil, 2, nil, 3] | compact }}  # [1, 2, 3]
```

### where

Filter by property value:

```
{{ users | where("active") }}      # Users where active is truthy
{{ items | where("status", "active") }}  # Items where status == "active"
```

### group_by

Group items by property:

```
{{ users | group_by("role") }}     # Group by role
```

### size

Get collection size (alias for length):

```
{{ items | size }}                 # Same as length
```

## Math Filters

Perform mathematical operations.

### plus

Add to a number:

```
{{ 5 | plus(3) }}                  # 8
{{ price | plus(tax) }}            # Add tax
```

### minus

Subtract from a number:

```
{{ 10 | minus(3) }}                # 7
{{ price | minus(discount) }}      # Apply discount
```

### times

Multiply a number:

```
{{ 5 | times(3) }}                 # 15
{{ price | times(quantity) }}      # Total price
```

### divided_by

Divide a number:

```
{{ 20 | divided_by(4) }}           # 5
{{ total | divided_by(count) }}    # Average
```

### modulo

Get remainder:

```
{{ 17 | modulo(5) }}               # 2
{{ index | modulo(2) }}            # 0 or 1
```

### abs

Absolute value:

```
{{ -5 | abs }}                     # 5
{{ -3.14 | abs }}                  # 3.14
```

### ceil

Round up:

```
{{ 3.2 | ceil }}                   # 4
{{ 3.0 | ceil }}                   # 3
```

### floor

Round down:

```
{{ 3.8 | floor }}                  # 3
{{ 3.2 | floor }}                  # 3
```

### round

Round to nearest:

```
{{ 3.14159 | round(2) }}           # 3.14
{{ 3.5 | round }}                  # 4
```

## Type Filters

Work with different data types.

### size

Get size of collection or string:

```
{{ items | size }}                 # Count
{{ text | size }}                  # String length
```

### string

Convert to string:

```
{{ 42 | string }}                  # "42"
{{ true | string }}                # "true"
```

## Filter Combinations

### Example 1: Format Product List

```
{{ products | map("name") | sort | join(", ") }}
```

1. Extract names: `["b", "c", "a"]`
2. Sort: `["a", "b", "c"]`
3. Join: `"a, b, c"`

### Example 2: Process User Names

```
{{ users | map("name") | join(", ") | capitalize }}
```

1. Extract names: `["alice", "bob"]`
2. Join: `"alice, bob"`
3. Capitalize: `"Alice, bob"`

### Example 3: Clean Text

```
{{ text | strip | replace("  ", " ") | capitalize }}
```

1. Strip whitespace
2. Replace double spaces
3. Capitalize

### Example 4: Truncate Long List

```
{{ items | slice(0, 5) | join(", ") | truncate(30) }}
```

1. Take first 5
2. Join with comma
3. Truncate at 30 chars

## Advanced Patterns

### Safe Navigation

Combine with if for safe access:

```
{% if items %}
  {{ items | join(", ") }}
{% else %}
  No items
{% endif %}
```

### Conditional Formatting

```
{{ price | plus(tax) | round(2) }}
{{ description | truncate(100) }}
{{ date | format_date("%Y-%m-%d") }}
```

### Filtering and Mapping

```
{{ users | where("active") | map("name") | join(", ") }}
```

This:
1. Filters to active users
2. Extracts names
3. Joins with comma

### Counted Operations

```
Items: {{ items | length }}
Sorted: {{ items | sort | join(", ") }}
Unique: {{ items | uniq | length }}
```

## Troubleshooting

### Filter Not Found

If a filter doesn't exist:
- Check spelling
- Ensure it's a built-in filter
- For custom filters, verify configuration

### Unexpected Results

- Test individual filters first
- Check order of filter chain
- Verify data types

### Type Errors

```
{# Wrong type #}
{{ "hello" | plus(5) }}        # Error: can't add to string

{# Correct #}
{{ 5 | plus(3) }}              # Works
```

## Filter Reference

| Filter | Input | Output | Example |
|--------|-------|--------|---------|
| capitalize | string | string | `"hello" → "Hello"` |
| upper_case | string | string | `"hello" → "HELLO"` |
| lower_case | string | string | `"HELLO" → "hello"` |
| strip | string | string | `"  x  " → "x"` |
| split | string | array | `"a,b" → ["a","b"]` |
| join | array | string | `["a","b"] → "a,b"` |
| length | array/string | number | `[1,2,3] → 3` |
| first | array | any | `[1,2,3] → 1` |
| last | array | any | `[1,2,3] → 3` |
| sort | array | array | `[3,1,2] → [1,2,3]` |
| reverse | array/string | array/string | `[1,2,3] → [3,2,1]` |
| uniq | array | array | `[1,1,2] → [1,2]` |
| plus | number | number | `5 + 3 → 8` |
| minus | number | number | `10 - 3 → 7` |
| times | number | number | `5 * 3 → 15` |
| abs | number | number | `-5 → 5` |

## See Also

- [Template Language Reference](../reference/template-language.md) - Filter syntax details
- [Email Templates Examples](../examples/email-templates.md) - Real-world filter usage
- [Reference](../reference/filters-list.md) - Complete filter list
