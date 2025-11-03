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
{{ nil }}
```
Note: Both `nil` and `null` are supported and equivalent.

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

Mau supports two styles of logical operators with **different behavior**:

#### Word-based Operators: `and` / `or` / `not`

**Returns boolean values** (`true` or `false`) using Liquid-style truthiness:

```liquid
{{ user.active and user.verified }}        # Returns: true or false
{{ role == "admin" or role == "moderator" }}  # Returns: true or false
{{ not user.blocked }}                     # Returns: true or false
```

**Truthiness (Liquid-style):**
- Falsy values: `nil`, `false`, `0`, `""` (empty string), `[]` (empty list), `{}` (empty map)
- Everything else is truthy

**Examples:**
```liquid
{{ 0 and "hello" }}          # false (0 is falsy)
{{ "" or "world" }}          # true (returns boolean, not the value)
{{ "hello" and "world" }}    # true (returns boolean)
```

#### Symbol-based Operators: `&&` / `||` / `!`

**Returns actual values** (not booleans) using Elixir-style truthiness:

```liquid
{{ user.active && user.verified }}        # Returns: right value or false/nil
{{ role == "admin" || role == "moderator" }}  # Returns: first truthy value
{{ !user.blocked }}                       # Returns: true or false
```

**Truthiness (Elixir-style):**
- Falsy values: **only** `nil` and `false`
- Everything else is truthy (including `0`, `""`, `[]`, `{}`)

**Examples:**
```liquid
{{ 0 && "hello" }}           # "hello" (0 is truthy, returns right value)
{{ "" || "world" }}          # "" (empty string is truthy, returns left value)
{{ "hello" && "world" }}     # "world" (returns right value)
{{ false || 42 }}            # 42 (returns first truthy value)
{{ nil && "test" }}          # nil (short-circuits, returns nil)
```

#### Choosing Between Operators

Use **`and` / `or` / `not`** when:
- You need boolean results for conditions
- You want Liquid-like behavior where `0` and `""` are falsy
- You're writing templates familiar to Liquid users

Use **`&&` / `||` / `!`** when:
- You need the actual values (for default value patterns)
- You want Elixir-like behavior where only `nil` and `false` are falsy
- You're using `||` for default values: `{{ user.name || "Guest" }}`

**Complex Conditions:**
```liquid
{{ (age >= 18 and age <= 65) and (role == "user" or role == "premium") }}
{{ user.active && (user.plan == "pro" || user.credits > 0) }}
```

**Short-circuit Evaluation:**
Both operator styles support short-circuit evaluation:
```liquid
{{ false && expensive_operation }}  # expensive_operation not evaluated
{{ true || expensive_operation }}   # expensive_operation not evaluated
```

### Operator Precedence

**Highest to Lowest:**
1. Property access: `.`, `[]`
2. Unary: `not` / `!`, `-`
3. Multiplicative: `*`, `/`, `%`
4. Additive: `+`, `-`
5. Relational: `<`, `<=`, `>`, `>=`
6. Equality: `==`, `!=`
7. Logical AND: `and` / `&&`
8. Logical OR: `or` / `||`

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

Filters transform expression values using the pipe (`|`) operator or function call syntax.

**Pipe Syntax:**
```liquid
{{ user.name | capitalize }}
{{ text | upper_case | strip }}
```

**Function Call Syntax:**
```liquid
{{ capitalize(user.name) }}
{{ upper_case(text) }}
```

**Multiple Filters** *(Fully Supported)*

Filters can be chained together for complex transformations:
```liquid
{{ user.bio | strip | truncate(100) | capitalize }}
{{ price | multiply(quantity) | format_currency("USD") }}
{{ items | slice(0, 3) | join(", ") | upper_case }}
{{ numbers | sum | power(2) | sqrt }}
```

### Available Filters

Mau includes 40+ built-in filters organized into categories:
- **String Filters** - Text manipulation and formatting
- **Collection Filters** - Array and list operations
- **Math Filters** - Numeric calculations and rounding
- **Number Filters** - Number formatting

For a complete list of all available filters with detailed documentation, see **[Filters List Reference](filters-list.md)**.

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
{{ %{"key" => "value"} }} # Map -> %{"key" => "value"} # not yet support
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
