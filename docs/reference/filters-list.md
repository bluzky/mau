# Complete Filters Reference

Comprehensive alphabetical reference of all available filters in Mau template engine.

## Overview

Mau provides 40+ built-in filters organized into four categories:
- **String filters** (6 filters) - Text manipulation and formatting
- **Collection filters** (18 filters) - List and map operations
- **Math filters** (10 filters) - Numerical operations
- **Type filters** (6 filters) - Type conversion and checking

## Filter Syntax

All filters use the pipe syntax:

```
{{ value | filter_name }}
{{ value | filter_name: arg1, arg2 }}
{{ value | filter1 | filter2 | filter3 }}
```

Filters can be chained to combine multiple operations.

---

## String Filters

String filters manipulate and format text values.

### capitalize

Capitalizes the first letter of each word in a string.

**Syntax:**
```
{{ value | capitalize }}
```

**Examples:**
```
{{ "hello world" | capitalize }}
# Output: "Hello World"

{{ "élixir programming" | capitalize }}
# Output: "Élixir Programming"
```

**Returns:** Capitalized string

**See Also:** [`upper_case`](#upper_case), [`lower_case`](#lower_case)

---

### default

Returns the input value, or a default value if input is nil or empty string.

**Syntax:**
```
{{ value | default: fallback_value }}
```

**Parameters:**
- `fallback_value` - The value to use if input is nil or empty

**Examples:**
```
{{ author | default: "Anonymous" }}
# If author is nil: "Anonymous"
# If author is "John": "John"

{{ bio | default: "No bio provided" }}
# If bio is empty string: "No bio provided"
```

**Returns:** Original value or fallback value

**Note:** Only triggers on nil or empty string (""), not other falsy values like 0 or false

**See Also:** [`contains`](#contains)

---

### lower_case

Converts a string to lowercase.

**Syntax:**
```
{{ value | lower_case }}
```

**Examples:**
```
{{ "HELLO World" | lower_case }}
# Output: "hello world"

{{ name | lower_case }}
# Converts any string to lowercase
```

**Returns:** Lowercase string

**See Also:** [`upper_case`](#upper_case), [`capitalize`](#capitalize)

---

### strip

Removes leading and trailing whitespace from a string.

**Syntax:**
```
{{ value | strip }}
```

**Examples:**
```
{{ "  hello world  " | strip }}
# Output: "hello world"

{{ input_value | strip }}
# Useful for cleaning user input
```

**Returns:** String with whitespace removed from edges

**Note:** Only removes leading and trailing whitespace, not internal spaces

---

### truncate

Truncates a string to a specified length with optional suffix.

**Syntax:**
```
{{ value | truncate: length }}
{{ value | truncate: length, suffix }}
```

**Parameters:**
- `length` - Maximum length of result
- `suffix` - Optional suffix (default: "...")

**Examples:**
```
{{ "Hello World" | truncate: 8 }}
# Output: "Hello..."

{{ "Hello World" | truncate: 9, "…" }}
# Output: "Hello W…"

{{ description | truncate: 50, "" }}
# Output: First 50 characters with no suffix
```

**Returns:** Truncated string

**Note:** The suffix is included in the length calculation

---

### upper_case

Converts a string to uppercase.

**Syntax:**
```
{{ value | upper_case }}
```

**Examples:**
```
{{ "hello world" | upper_case }}
# Output: "HELLO WORLD"

{{ name | upper_case }}
# Converts any string to uppercase
```

**Returns:** Uppercase string

**See Also:** [`lower_case`](#lower_case), [`capitalize`](#capitalize)

---

## Collection Filters

Collection filters operate on lists and maps.

### compact

Removes nil values from a list.

**Syntax:**
```
{{ list | compact }}
```

**Examples:**
```
{{ values | compact }}
# Input: [1, nil, 2, nil, 3]
# Output: [1, 2, 3]

{{ authors | compact }}
# Removes nil author entries from list
```

**Returns:** List without nil values

**See Also:** [`uniq`](#uniq), [`reject`](#reject)

---

### contains

Checks if a collection, string, or map contains a specific value or key.

**Syntax:**
```
{{ value | contains: search_value }}
```

**Parameters:**
- `search_value` - Value/substring/key to search for

**Examples:**
```
{{ "hello world" | contains: "world" }}
# Output: true

{{ names | contains: "Alice" }}
# Returns true if "Alice" is in the list

{{ user | contains: "email" }}
# Returns true if "email" key exists in map
```

**Returns:** Boolean (true/false)

**See Also:** [`filter`](#filter)

---

### dump

Formats any data structure as a string for debugging purposes.

**Syntax:**
```
{{ value | dump }}
```

**Examples:**
```
{{ user | dump }}
# Output: "%{\"name\" => \"Alice\", \"age\" => 30}"

{{ items | dump }}
# Displays list structure as string
```

**Returns:** String representation of the data

**Use Case:** Debugging template variables and data structures

---

### filter

Filters a list of maps, keeping only items where a field matches a value.

**Syntax:**
```
{{ list | filter: field, value }}
```

**Parameters:**
- `field` - The field name to match on
- `value` - The value to match

**Examples:**
```
{{ users | filter: "status", "active" }}
# Output: [users where status == "active"]

{{ products | filter: "category", "electronics" }}
# Returns only electronics products
```

**Returns:** Filtered list

**Note:** Removes items that don't match

**See Also:** [`reject`](#reject), [`map`](#map)

---

### first

Returns the first element of a collection or string.

**Syntax:**
```
{{ value | first }}
```

**Examples:**
```
{{ items | first }}
# Input: ["apple", "banana", "cherry"]
# Output: "apple"

{{ "hello" | first }}
# Output: "h"

{{ empty_list | first }}
# Output: nil
```

**Returns:** First element, or nil if empty

**See Also:** [`last`](#last)

---

### flatten

Flattens nested lists into a single-level list.

**Syntax:**
```
{{ list | flatten }}
```

**Examples:**
```
{{ matrix | flatten }}
# Input: [[1, 2], [3, 4], [5, 6]]
# Output: [1, 2, 3, 4, 5, 6]

{{ nested_items | flatten }}
# Recursively flattens all nesting levels
```

**Returns:** Flattened list

**Note:** Recursively flattens all nested lists

---

### group_by

Groups a list of maps by the value of a specified field.

**Syntax:**
```
{{ list | group_by: field }}
```

**Parameters:**
- `field` - The field name to group by

**Examples:**
```
{{ users | group_by: "department" }}
# Output: %{
#   "engineering" => [alice, bob],
#   "sales" => [charlie, diana]
# }

{{ products | group_by: "category" }}
# Groups products by their category
```

**Returns:** Map with grouped items

**Use Case:** Creating categorized lists or reports

---

### join

Joins elements of a list into a string with a separator.

**Syntax:**
```
{{ list | join }}
{{ list | join: separator }}
```

**Parameters:**
- `separator` - String to insert between items (default: ", ")

**Examples:**
```
{{ tags | join: ", " }}
# Input: ["ruby", "elixir", "javascript"]
# Output: "ruby, elixir, javascript"

{{ lines | join: "\n" }}
# Joins with newlines (useful for CSV or plain text)

{{ values | join: "-" }}
# Output with dash separator: "1-2-3-4"
```

**Returns:** Joined string

**See Also:** [`split`](#split)

---

### keys

Returns all keys from a map as a list.

**Syntax:**
```
{{ map | keys }}
```

**Examples:**
```
{{ user | keys }}
# Input: %{"name" => "Alice", "email" => "alice@example.com"}
# Output: ["name", "email"]

{{ config | keys }}
# Returns all configuration keys
```

**Returns:** List of keys

**See Also:** [`values`](#values)

---

### last

Returns the last element of a collection or string.

**Syntax:**
```
{{ value | last }}
```

**Examples:**
```
{{ items | last }}
# Input: ["apple", "banana", "cherry"]
# Output: "cherry"

{{ "hello" | last }}
# Output: "o"

{{ empty_list | last }}
# Output: nil
```

**Returns:** Last element, or nil if empty

**See Also:** [`first`](#first)

---

### length

Returns the length (number of elements) of a collection or string.

**Syntax:**
```
{{ value | length }}
```

**Examples:**
```
{{ items | length }}
# Input: ["a", "b", "c"]
# Output: 3

{{ "hello" | length }}
# Output: 5

{{ user | length }}
# For maps: returns the number of keys
```

**Returns:** Integer count

**Use Case:** Checking if collections are empty or displaying counts

---

### map

Extracts a field value from each map in a list, filtering out nil values.

**Syntax:**
```
{{ list | map: field }}
```

**Parameters:**
- `field` - The field name to extract

**Examples:**
```
{{ users | map: "name" }}
# Input: [
#   %{"name" => "Alice", "age" => 30},
#   %{"name" => "Bob", "age" => 25}
# ]
# Output: ["Alice", "Bob"]

{{ products | map: "price" }}
# Extracts all prices from product list
```

**Returns:** List of field values (nils removed)

**See Also:** [`filter`](#filter)

---

### reject

Filters a list of maps, removing items where a field matches a value (opposite of filter).

**Syntax:**
```
{{ list | reject: field, value }}
```

**Parameters:**
- `field` - The field name to match on
- `value` - The value to reject

**Examples:**
```
{{ users | reject: "status", "inactive" }}
# Output: [users where status != "inactive"]

{{ products | reject: "discontinued", true }}
# Returns only products that are not discontinued
```

**Returns:** Filtered list without matching items

**See Also:** [`filter`](#filter)

---

### reverse

Reverses the order of elements in a collection or string.

**Syntax:**
```
{{ value | reverse }}
```

**Examples:**
```
{{ items | reverse }}
# Input: [1, 2, 3, 4]
# Output: [4, 3, 2, 1]

{{ "hello" | reverse }}
# Output: "olleh"
```

**Returns:** Reversed collection or string

---

### slice

Returns a slice (subsequence) of a list or string.

**Syntax:**
```
{{ value | slice: start }}
{{ value | slice: start, length }}
```

**Parameters:**
- `start` - Starting index (0-based)
- `length` - Optional number of elements to include

**Examples:**
```
{{ items | slice: 2 }}
# Input: ["a", "b", "c", "d", "e"]
# Output: ["c", "d", "e"]

{{ items | slice: 1, 2 }}
# Output: ["b", "c"]

{{ "hello world" | slice: 6 }}
# Output: "world"
```

**Returns:** Sliced collection or string

---

### sort

Sorts a collection in ascending order.

**Syntax:**
```
{{ list | sort }}
```

**Examples:**
```
{{ numbers | sort }}
# Input: [3, 1, 4, 1, 5]
# Output: [1, 1, 3, 4, 5]

{{ names | sort }}
# Sorts strings alphabetically
```

**Returns:** Sorted list

**Note:** Uses Elixir's default comparison (numbers first, then strings, etc.)

---

### sum

Sums all numeric values in a list.

**Syntax:**
```
{{ list | sum }}
```

**Examples:**
```
{{ prices | sum }}
# Input: [10, 20, 30]
# Output: 60

{{ quantities | sum }}
# Total quantity across all items
```

**Returns:** Numeric sum

**Error:** Returns error if list contains non-numeric values

**See Also:** Math filters: [`abs`](#abs), [`max`](#max), [`min`](#min)

---

### uniq

Returns only unique elements from a list, removing duplicates.

**Syntax:**
```
{{ list | uniq }}
```

**Examples:**
```
{{ items | uniq }}
# Input: [1, 2, 2, 3, 3, 3]
# Output: [1, 2, 3]

{{ tags | uniq }}
# Removes duplicate tags
```

**Returns:** List with duplicates removed

**See Also:** [`compact`](#compact)

---

### values

Returns all values from a map as a list.

**Syntax:**
```
{{ map | values }}
```

**Examples:**
```
{{ user | values }}
# Input: %{"name" => "Alice", "email" => "alice@example.com"}
# Output: ["Alice", "alice@example.com"]

{{ config | values }}
# Returns all configuration values
```

**Returns:** List of values

**See Also:** [`keys`](#keys)

---

## Math Filters

Math filters perform numerical operations.

### abs

Returns the absolute value of a number.

**Syntax:**
```
{{ value | abs }}
```

**Examples:**
```
{{ -42 | abs }}
# Output: 42

{{ -3.14 | abs }}
# Output: 3.14

{{ temperature_diff | abs }}
# Always returns positive difference
```

**Returns:** Positive number

---

### ceil

Rounds a number up to the nearest integer.

**Syntax:**
```
{{ value | ceil }}
```

**Examples:**
```
{{ 3.2 | ceil }}
# Output: 4

{{ 3.9 | ceil }}
# Output: 4

{{ -2.1 | ceil }}
# Output: -2
```

**Returns:** Rounded up integer

**See Also:** [`floor`](#floor), [`round`](#round)

---

### clamp

Clamps a number between minimum and maximum values.

**Syntax:**
```
{{ value | clamp: min, max }}
```

**Parameters:**
- `min` - Minimum value (inclusive)
- `max` - Maximum value (inclusive)

**Examples:**
```
{{ score | clamp: 0, 100 }}
# If score is 150: returns 100
# If score is -10: returns 0
# If score is 50: returns 50

{{ volume | clamp: 0, 10 }}
# Ensures volume stays within valid range
```

**Returns:** Clamped number

**Error:** min must be <= max

---

### floor

Rounds a number down to the nearest integer.

**Syntax:**
```
{{ value | floor }}
```

**Examples:**
```
{{ 3.2 | floor }}
# Output: 3

{{ 3.9 | floor }}
# Output: 3

{{ -2.1 | floor }}
# Output: -3
```

**Returns:** Rounded down integer

**See Also:** [`ceil`](#ceil), [`round`](#round)

---

### max

Returns the maximum value from a list or compares two numbers.

**Syntax:**
```
{{ list | max }}
{{ number | max: other_number }}
```

**Examples:**
```
{{ prices | max }}
# Input: [10, 50, 30, 20]
# Output: 50

{{ 15 | max: 10 }}
# Output: 15

{{ values | max }}
# Finds highest value in collection
```

**Returns:** Maximum value

**Error:** List must contain at least one number

**See Also:** [`min`](#min)

---

### min

Returns the minimum value from a list or compares two numbers.

**Syntax:**
```
{{ list | min }}
{{ number | min: other_number }}
```

**Examples:**
```
{{ prices | min }}
# Input: [10, 50, 30, 20]
# Output: 10

{{ 15 | min: 20 }}
# Output: 15

{{ values | min }}
# Finds lowest value in collection
```

**Returns:** Minimum value

**Error:** List must contain at least one number

**See Also:** [`max`](#max)

---

### mod

Returns the remainder of integer division (modulo).

**Syntax:**
```
{{ value | mod: divisor }}
```

**Parameters:**
- `divisor` - The number to divide by

**Examples:**
```
{{ 17 | mod: 5 }}
# Output: 2

{{ 10 | mod: 3 }}
# Output: 1

{% if item_index | mod: 2 == 0 %}
# Check if number is even
{% endif %}
```

**Returns:** Remainder (integer)

**Error:** Divisor cannot be zero

---

### power

Raises a number to a specified power (exponentiation).

**Syntax:**
```
{{ base | power: exponent }}
```

**Parameters:**
- `exponent` - The power to raise to

**Examples:**
```
{{ 2 | power: 3 }}
# Output: 8 (2³)

{{ 3 | power: 2 }}
# Output: 9 (3²)

{{ 10 | power: 3 }}
# Output: 1000
```

**Returns:** Result of base^exponent

**See Also:** [`sqrt`](#sqrt)

---

### round

Rounds a number to the nearest integer or specified decimal places.

**Syntax:**
```
{{ value | round }}
{{ value | round: decimal_places }}
```

**Parameters:**
- `decimal_places` - Optional number of decimal places to round to

**Examples:**
```
{{ 3.5 | round }}
# Output: 4

{{ 3.14159 | round: 2 }}
# Output: 3.14

{{ price | round: 2 }}
# Rounds to 2 decimal places (useful for currency)
```

**Returns:** Rounded number

**See Also:** [`ceil`](#ceil), [`floor`](#floor)

---

### sqrt

Returns the square root of a number.

**Syntax:**
```
{{ value | sqrt }}
```

**Examples:**
```
{{ 16 | sqrt }}
# Output: 4

{{ 9 | sqrt }}
# Output: 3

{{ area | sqrt }}
# Finds side length of square given area
```

**Returns:** Square root as float

**Error:** Cannot be applied to negative numbers

**See Also:** [`power`](#power)

---

## Filter Combinations

Filters become powerful when chained together.

### Practical Examples

**Format and truncate text:**
```
{{ description | lower_case | truncate: 50 }}
```

**Process lists:**
```
{{ users | map: "email" | join: "; " | upper_case }}
# Extracts emails, joins with semicolons, and uppercases
```

**Combine filters for reports:**
```
{{ products | filter: "in_stock", true | map: "price" | sum }}
# Sums prices of products that are in stock
```

**Data validation:**
```
{{ user_input | strip | default: "No input" | length }}
# Cleans input, provides default, and checks length
```

**Complex transformations:**
```
{{ items
  | group_by: "category"
  | values
  | map: "price"
  | sum
}}
# Groups items, gets values, extracts prices, and sums them
```

## Best Practices

### 1. Order Matters

```
# Good: strip first, then process
{{ input | strip | default: "value" }}

# Less ideal: processing then stripping
{{ input | default: " value " | strip }}
```

### 2. Use Type-Specific Filters

```
# String operations on strings
{{ text | upper_case | capitalize }}

# Collection operations on lists
{{ items | sort | reverse | first }}

# Math operations on numbers
{{ value | abs | round: 2 }}
```

### 3. Provide Defaults

```
# Defensive programming
{{ author | default: "Anonymous" }}
{{ price | default: 0 }}
```

### 4. Chain Logically

```
# Clean → Extract → Transform → Format
{{ data | strip | map: "value" | sort | join: ", " }}
```

## Common Patterns

### Formatting Numbers

```
{{ total_price | round: 2 }}
{{ percentage | round: 1 | append: "%" }}
```

### Processing Text

```
{{ title | capitalize | truncate: 30 }}
{{ slug | lower_case }}
```

### Working with Lists

```
{{ items | length }}
{{ tags | join: ", " }}
{{ prices | sort | first }}
```

### Filtering and Grouping

```
{{ users | filter: "active", true | length }}
{{ products | group_by: "category" }}
```

## Error Handling

When filters encounter errors:

- **Type Errors:** "length can only be applied to collections or strings"
- **Missing Parameters:** "truncate requires a length parameter"
- **Invalid Operations:** "mod by zero is undefined"

Check filter documentation for specific parameter requirements.

## See Also

- [Template Syntax Guide](../guides/template-syntax.md) - Variable interpolation
- [Filters Guide](../guides/filters.md) - How to use and chain filters
- [Control Flow Guide](../guides/control-flow.md) - Conditionals and loops
