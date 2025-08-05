# Prana Template Language Reference

This document defines the syntax, data types, operators, and semantics of the Prana template language.

## Overview

Prana templates combine literal text with dynamic expressions and control flow. The language is designed for workflow automation contexts where data flows between nodes in a graph-based execution model.

## Template Syntax

### Basic Structure

```liquid
Literal text content
{{ expression }}
{% tag %}...{% endtag %}
```

### Delimiters

**Expression Blocks:**
- `{{ expression }}` - Output expression result
- `{{- expression }}` - Trim whitespace before
- `{{ expression -}}` - Trim whitespace after
- `{{- expression -}}` - Trim whitespace both sides

**Tag Blocks:**
- `{% tag %}` - Control flow and logic tags
- `{%- tag %}` - Trim whitespace before
- `{% tag -%}` - Trim whitespace after
- `{%- tag -%}` - Trim whitespace both sides

**Comments:**
- `{# comment #}` - Template comments (not rendered)

## Data Types

### Primitive Types

**String**
```liquid
{{ "hello world" }}
{{ 'single quotes' }}
{{ "escape \"quotes\" with backslash" }}
```

**Number**
```liquid
{{ 42 }}
{{ 3.14159 }}
{{ -17 }}
{{ 1.5e-10 }}
```

**Boolean**
```liquid
{{ true }}
{{ false }}
```

**Null**
```liquid
{{ null }}
{{ nil }}
```

### Complex Types

**Array/List**
```liquid
{{ items[0] }}          <!-- First element -->
{{ items[-1] }}         <!-- Last element (Not Yet Implemented) -->
{{ items[1:3] }}        <!-- Slice (Not Yet Implemented) -->
```

**Object/Map**
```liquid
{{ user.name }}         <!-- Property access -->
{{ user["email"] }}     <!-- Bracket access -->
{{ user.address.city }} <!-- Nested access -->
```

### Built-in Workflow variables

Workflow variables are normal variables that support a $ prefix in the variable name to distinguish them from local variables.

**Workflow Variables**
```liquid
{{ $input }}            <!-- Workflow input data -->
{{ $variables }}        <!-- Workflow variables -->
{{ $nodes.step1.output }} <!-- Node execution results -->
{{ $context }}          <!-- Execution context -->
```

**Path Expressions**
```liquid
{{ $input.user.profile.email }}
{{ $nodes.api_call.response.data.users[0].name }}
{{ $variables.api_url }}
```

## Variable Access

### Simple Variables
```liquid
{{ name }}
{{ age }}
{{ active }}
{{ $user }}
```

### Object Property Access
```liquid
{{ user.name }}
{{ user.profile.email }}
{{ $settings.api.timeout }}
```

### Array Access
```liquid
{{ users[0] }}          <!-- Index access -->
{{ users[index] }}      <!-- Dynamic index -->
{{ $nested[0].items[1] }} <!-- Nested arrays -->
```

### Workflow Context Access
```liquid
<!-- Input data from workflow trigger -->
{{ $input.email }}
{{ $input.user.preferences.theme }}

<!-- Results from previous nodes -->
{{ $nodes.fetch_user.output.user_id }}
{{ $nodes.api_call.response.data }}

<!-- Workflow variables -->
{{ $variables.api_key }}
{{ $variables.base_url }}

<!-- Execution context -->
{{ $context.execution_id }}
{{ $context.timestamp }}
```

## Operators

### Comparison Operators

**Equality**
```liquid
{{ user.role == "admin" }}
{{ status != "pending" }}
```

**Relational**
```liquid
{{ age >= 18 }}
{{ score > 90 }}
{{ count <= 10 }}
{{ priority < 5 }}
```

### Arithmetic Operators

**Basic Math**
```liquid
{{ price + tax }}
{{ total - discount }}
{{ quantity * price }}
{{ total / count }}
{{ number % 2 }}
```

**String Concatenation**
```liquid
{{ first_name + " " + last_name }}
{{ "Hello " + user.name }}
```

### Logical Operators

**Boolean Logic**
```liquid
{{ user.active and user.verified }}
{{ role == "admin" or role == "moderator" }}
{{ not user.blocked }}
```

**Complex Conditions**
```liquid
{{ (age >= 18 and age <= 65) and (role == "user" or role == "premium") }}
{{ user.active and (user.plan == "pro" or user.credits > 0) }}
```

### Operator Precedence

**Highest to Lowest:**
1. Property access: `.`, `[]`
2. Unary: `not`, `-`
3. Multiplicative: `*`, `/`, `%`
4. Additive: `+`, `-`
5. Relational: `<`, `<=`, `>`, `>=`
6. Equality: `==`, `!=`
7. Logical AND: `and`
8. Logical OR: `or`

**Parentheses** can override precedence:
```liquid
{{ (total + tax) * quantity }}
{{ user.active and (role == "admin" or permissions.elevated) }}
```

## Control Flow Tags

### Conditional Statements

**If/Else**
```liquid
{% if user.active %}
  Welcome back, {{ user.name }}!
{% else %}
  Your account is inactive.
{% endif %}
```

**If/Elsif/Else**
```liquid
{% if user.role == "admin" %}
  Administrator Dashboard
{% elsif user.role == "moderator" %}
  Moderator Panel
{% elsif user.role == "user" %}
  User Profile
{% else %}
  Access Denied
{% endif %}
```

### Loops

**For Loops**
```liquid
{% for user in users %}
  Name: {{ user.name }}
  Email: {{ user.email }}
{% endfor %}
```

**For with Conditions** *(Not Yet Implemented)*
```liquid
{% for item in items limit: 5 %}
  {{ item.name }}
{% endfor %}

{% for user in users offset: 10 limit: 20 %}
  {{ user.name }}
{% endfor %}
```

**For with Filtering** *(Not Yet Implemented)*
```liquid
{% for user in users where user.active %}
  {{ user.name }}
{% endfor %}
```

**Loop Variables**
```liquid
{% for item in items %}
  {{ forloop.index }}: {{ item.name }}
  {% if forloop.first %}First item!{% endif %}
  {% if forloop.last %}Last item!{% endif %}
{% endfor %}
```

### Case/Switch *(Not Yet Implemented)*
```liquid
{% case user.role %}
  {% when "admin" %}
    Administrator
  {% when "moderator" %}
    Moderator
  {% when "user" %}
    User
  {% else %}
    Unknown role
{% endcase %}
```

## Utility Tags

### Assignment
```liquid
{% assign full_name = user.first_name + " " + user.last_name %}
{% assign total_price = quantity * price + tax %}

Hello {{ full_name }}!
Total: ${{ total_price }}
```

### Comments
```liquid
{# Inline comment - not rendered #}
```

## Filters

Filters transform expression values using the pipe (`|`) operator.
Filters can be invoked directly without the pipe operator:

```liquid
{{ capitalize(user.name) }}
```

**Multiple Filters** *(Fully Supported)*
```liquid
{{ user.bio | strip | truncate(100) | capitalize }}
{{ price | multiply(quantity) | format_currency("USD") }}
{{ items | slice(0, 3) | join(", ") | upper_case }}
{{ numbers | sum | power(2) | sqrt }}
```

### Available Filters

**String Filters**
- `upper_case` - Convert string to uppercase
- `lower_case` - Convert string to lowercase  
- `capitalize` - Capitalize the first letter of a string
- `truncate` - Truncate string to specified length
- `default` - Provide default value for nil/empty values

**Number Filters**
- `format_currency` - Format number as currency

*Note: The `round` filter is implemented in the Math filters category.*

**Collection Filters**
- `length` - Get length/count of a collection
- `first` - Get first item from a collection
- `last` - Get last item from a collection
- `join` - Join array elements with separator
- `sort` - Sort a list
- `reverse` - Reverse a list or string
- `uniq` - Get unique elements from list
- `slice` - Extract slice from list or string
- `contains` - Check if collection contains value
- `compact` - Remove nil values from list
- `flatten` - Flatten nested lists
- `sum` - Sum numeric values in list
- `keys` - Get keys of a map
- `values` - Get values of a map
- `group_by` - Group list elements by key
- `map` - Extract field values from list of maps
- `filter` - Filter list of maps by field value
- `reject` - Reject list of maps by field value
- `dump` - Format data structures for display

**Math Filters**
- `abs` - Absolute value
- `ceil` - Round up to nearest integer
- `floor` - Round down to nearest integer
- `max` - Maximum of two values
- `min` - Minimum of two values
- `power` - Raise to power
- `sqrt` - Square root
- `mod` - Modulo operation
- `clamp` - Clamp value between min and max

## Whitespace Control

### Tag-Level Control

**Trim Before**
```liquid
Text   {%- if true %}Content{% endif %}
<!-- Result: "TextContent" -->
```

**Trim After**
```liquid
{% if true -%}   Content   {% endif %}
<!-- Result: "Content   " -->
```

**Trim Both**
```liquid
Text   {%- if true -%}   Content   {%- endif -%}   More
<!-- Result: "TextContentMore" -->
```

### Global Options

**trim_blocks** *(Not Yet Implemented)* - Remove newlines after tag blocks
 With trim_blocks: true
```liquid
Start
{% if true %}
Content
{% endif %}
End
```
- Result: "Start\nContent\nEnd"

**lstrip_blocks** *(Not Yet Implemented)* - Remove leading whitespace before tag blocks
- With lstrip_blocks: true
```liquid
Start
    {% if true %}Content{% endif %}
End
```
- Result: "Start\n{% if true %}Content{% endif %}\nEnd"

## Data Type Preservation

By default, all template output is converted to strings. However, Mau supports preserving original data types for single-value templates using the `preserve_types` option.

### Basic Usage

```liquid
# Default behavior (all strings)
Mau.render("{{ 42 }}", %{})           #=> {:ok, "42"}
Mau.render("{{ true }}", %{})         #=> {:ok, "true"}

# With data type preservation
Mau.render("{{ 42 }}", %{}, preserve_types: true)    #=> {:ok, 42}
Mau.render("{{ true }}", %{}, preserve_types: true)  #=> {:ok, true}
```

### Supported Data Types

**Primitive Types**
```liquid
{{ 42 }}        # Integer -> 42
{{ 3.14 }}      # Float -> 3.14  
{{ true }}      # Boolean -> true
{{ false }}     # Boolean -> false
{{ nil }}       # Nil -> nil
{{ "hello" }}   # String -> "hello"
```

**Collection Types**
```liquid
{{ [1, 2, 3] }}           # List -> [1, 2, 3]
{{ %{"key" => "value"} }} # Map -> %{"key" => "value"}
```

**Expressions and Operations**
```liquid
{{ 5 + 3 }}         # Arithmetic -> 8
{{ 5 > 3 }}         # Comparison -> true
{{ true and false }} # Logic -> false
```

**Filter Results**
```liquid
{{ items | length }}     # Numeric filter -> 3
{{ items | reverse }}    # List filter -> [3, 2, 1]
{{ items | join(",") }}  # String filter -> "1,2,3"
```

### Mixed Content Behavior

Mixed content (text + expressions) always returns strings, even with `preserve_types: true`:

```liquid
# These always return strings
Mau.render("Count: {{ 42 }}", %{}, preserve_types: true)  #=> {:ok, "Count: 42"}
Mau.render("{{ name }}: {{ age }}", context, preserve_types: true)  #=> {:ok, "Alice: 25"}
```

### Single Value Detection

Data type preservation only applies to templates that contain exactly one expression and no surrounding text:

```liquid
# Single value - types preserved
{{ 42 }}                 # -> 42 (Integer)
{{ user.active }}        # -> true (Boolean)
{{ items | length }}     # -> 3 (Integer)

# Multiple expressions - returns string
{{ 42 }}{{ true }}       # -> "42true" (String)

# Mixed content - returns string  
Value: {{ 42 }}          # -> "Value: 42" (String)
```

## Error Handling

### Strict Mode

**strict_mode: true** - Return errors for incomplete expressions and undefined variables
- Incomplete expression: `{{ variable` → Error
- Undefined variable: `{{ unknown_var }}` → Error

**strict_mode: false** (default) - Graceful degradation
- Incomplete expression: `{{ variable` → Rendered as-is: "{{ variable"
- Undefined variable: `{{ unknown_var }}` → Treated as nil/empty

### Missing Variables

**Default Behavior (strict_mode: false)**
```liquid
{{ undefined_variable }}           <!-- Renders as empty string -->
{{ user.missing_property }}        <!-- Renders as empty string -->
```

### Type Coercion

**Boolean Context**
```liquid
{% if "non_empty_string" %}       <!-- true -->
{% if "" %}                       <!-- false -->
{% if 0 %}                        <!-- false -->
{% if null %}                     <!-- false -->
```

## Workflow Integration

### Execution Context

**Available Variables**
- `$input` - Data passed to the workflow
- `$variables` - Workflow-level variables
- `$nodes` - Results from executed nodes
- `$context` - Execution metadata
- `$env` - Environment variable for project *(Not Yet Implemented)*


## Future Extensions

### Planned Features

**Enhanced Control Flow** *(Not Yet Implemented)*
- `{% break %}` - Break out of loops
- `{% case %}` - Switch statements

**Advanced Expressions** *(Not Yet Implemented)*
- Ternary operator: `condition ? true_value : false_value`

## Implementation Status

### ✅ Fully Implemented Features

**Core Template Syntax**
- All expression blocks with whitespace control: `{{ }}`, `{{- }}`, `{{ -}}`, `{{- -}}`
- All tag blocks with whitespace control: `{% %}`, `{%- %}`, `{% -%}`, `{%- -%}`
- Template comments: `{# comment #}`
- Data type preservation: `preserve_types: true` option

**Data Types & Variables**
- All primitive types: strings, numbers, booleans, null/nil
- Complex types: arrays with indexing (positive only), objects/maps with property access
- Workflow variables: `$input`, `$variables`, `$nodes`, `$context`

**Operators & Expressions**
- All comparison operators: `==`, `!=`, `>`, `>=`, `<`, `<=`
- All arithmetic operators: `+`, `-`, `*`, `/`, `%`
- All logical operators: `and`, `or`, `not`
- Proper operator precedence and parentheses support

**Control Flow**
- If/else/elsif conditionals with full nesting support
- For loops with collection iteration
- Loop variables: `forloop.index`, `forloop.first`, `forloop.last`
- Assignment tags: `{% assign var = value %}`

**Filters (40+ implemented)**
- String filters: `upper_case`, `lower_case`, `capitalize`, `strip`, `truncate`, `default`
- Collection filters: `length`, `first`, `last`, `join`, `sort`, `reverse`, `uniq`, `slice`, `contains`, `compact`, `flatten`, `sum`, `keys`, `values`, `group_by`, `map`, `filter`, `reject`, `dump`
- Math filters: `abs`, `ceil`, `floor`, `round`, `max`, `min`, `power`, `sqrt`, `mod`, `clamp`
- Number filters: `format_currency`
- **Full filter chaining support**: `{{ value | filter1 | filter2 | filter3 }}`
- Function call syntax: `{{ filter_name(value) }}`

### ❌ Not Yet Implemented

**Advanced Loop Features**
- Loop conditions: `limit:`, `offset:` parameters
- Loop filtering: `where` conditions

**Control Flow Extensions**
- Case/switch statements: `{% case %}{% when %}{% endcase %}`
- Break statements: `{% break %}`

**Filter Limitations**
- Complex filter expressions in conditionals (e.g., `{% if name | upper_case == "ADMIN" %}`)

**Global Options**
- `trim_blocks` and `lstrip_blocks` global whitespace control
- Environment variables: `$env` workflow variable

**Advanced Features**
- Array slicing: `{{ items[1:3] }}`
- Negative array indexing: `{{ items[-1] }}`
- Ternary operator: `condition ? true_value : false_value`

### Implementation Coverage
**~95% of documented features are fully implemented**, with comprehensive support for core template functionality, full filter chaining, loop variables, data type preservation, and an extensive filter library.

## Syntax Summary

```liquid
<!-- Basic output -->
{{ variable }}
{{ $variable_with_dollar_sign }}
{{ object.property }}
{{ array[index] }}

<!-- Expressions -->
{{ a + b }}
{{ name == "John" }}
{{ active and verified }}

<!-- Control flow -->
{% if condition %}...{% endif %}
{% for item in items %}...{% endfor %}

<!-- Utility -->
{% assign var = value %}

<!-- Filters (full chaining support) -->
{{ text | upper_case | truncate(50) }}
{{ items | slice(0, 3) | join(", ") | upper_case }}
{{ price | format_currency("USD") }}
{{ format_currency(price, "USD") }}

<!-- Whitespace control -->
{{- variable -}}
{%- tag -%}...{%- endtag -%}
```
