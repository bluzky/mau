# Control Flow Guide

Master conditionals and loops in templates.

## If/Elsif/Else Conditionals

Control rendering based on conditions.

### Simple If

Render content only when condition is true:

```
{% if user.active %}
  Welcome back!
{% endif %}
```

If `user.active` is falsy, the content is not rendered.

### If/Else

Provide alternative content:

```
{% if user.active %}
  Welcome back!
{% else %}
  Please activate your account
{% endif %}
```

### Multiple Conditions (If/Elsif/Else)

Check multiple conditions in order:

```
{% if user.role == "admin" %}
  Admin Dashboard
{% elsif user.role == "moderator" %}
  Moderation Panel
{% elsif user.role == "user" %}
  User Dashboard
{% else %}
  Guest Area
{% endif %}
```

The first true condition renders; rest are skipped.

### Nested Conditionals

Conditions can be nested:

```
{% if user %}
  Name: {{ user.name }}
  {% if user.email %}
    Email: {{ user.email }}
  {% endif %}
{% endif %}
```

## Conditions

### Comparisons

```
{{ 5 > 3 }}          # true
{{ 5 < 3 }}          # false
{{ 5 == 5 }}         # true
{{ 5 != 3 }}         # true
{{ 5 >= 5 }}         # true
{{ 5 <= 10 }}        # true
```

Use comparisons in if statements:

```
{% if age >= 18 %}
  Adult
{% else %}
  Minor
{% endif %}
```

### String Comparisons

```
{% if user.name == "Alice" %}
  Hi Alice!
{% endif %}

{% if status != "active" %}
  Inactive account
{% endif %}
```

### Logical Operators

Combine conditions with `and`, `or`, `not`:

```
{% if user.active and user.verified %}
  Fully verified
{% endif %}

{% if user.admin or user.moderator %}
  Staff member
{% endif %}

{% if not user.banned %}
  Account is good
{% endif %}
```

### Complex Conditions

Use parentheses for clarity:

```
{% if (age >= 18 and verified) or admin %}
  Can proceed
{% endif %}

{% if (status == "active") and not (role == "banned") %}
  Show content
{% endif %}
```

## Truthiness

Values are evaluated as truthy or falsy:

**Falsy:**
- `nil` (null)
- `false`
- `""` (empty string)
- `[]` (empty list)
- `{}` (empty map/object)

**Truthy:**
- Everything else, including:
  - `true`
  - Non-empty strings: `"hello"`
  - Numbers: `0`, `1`, `-1` (all numbers are truthy)
  - Non-empty lists
  - Non-empty maps

### Using Truthiness

Check if value exists:

```
{% if user.email %}
  Email: {{ user.email }}
{% endif %}
```

This renders only if email is defined and not empty.

Check if list has items:

```
{% if items %}
  {{ items | length }} items found
{% else %}
  No items
{% endif %}
```

## Inline Conditionals

Render conditionals on a single line:

```
Status: {% if active %}Active{% else %}Inactive{% endif %}

{% if premium %}🌟{% endif %} {{ user.name }}
```

## For Loops

Iterate over collections.

### Basic Loop

```
{% for item in items %}
  {{ item }}
{% endfor %}
```

This repeats the content for each item in the array.

### Loop Over Objects

```
{% for user in users %}
  Name: {{ user.name }}
  Email: {{ user.email }}
{% endfor %}
```

Each `user` has access to all properties.

### Nested Loops

```
{% for category in categories %}
  Category: {{ category.name }}
  {% for item in category.items %}
    - {{ item }}
  {% endfor %}
{% endfor %}
```

### Loop with Conditionals

```
{% for item in items %}
  {% if item.available %}
    <li>{{ item.name }}</li>
  {% endif %}
{% endfor %}
```

## Loop Variables

Access loop metadata with `forloop`:

```
{% for item in items %}
  {{ forloop.index }}: {{ item }}
{% endfor %}
```

### Available Variables

- **forloop.index** - Position (1-based: 1, 2, 3...)
- **forloop.index0** - Position (0-based: 0, 1, 2...)
- **forloop.first** - Boolean, true on first iteration
- **forloop.last** - Boolean, true on last iteration
- **forloop.length** - Total number of items

### Examples

**Number each item:**

```
{% for item in items %}
  {{ forloop.index }}. {{ item }}
{% endfor %}
```

**Mark first and last:**

```
{% for item in items %}
  {% if forloop.first %}
    (First) {{ item }}
  {% elsif forloop.last %}
    (Last) {{ item }}
  {% else %}
    {{ item }}
  {% endif %}
{% endfor %}
```

**Add separators:**

```
{% for item in items %}
  {{ item }}{% unless forloop.last %}, {% endunless %}
{% endfor %}
```

Output: `Item1, Item2, Item3`

**Alternate rows:**

```
{% for item in items %}
  {% if forloop.index0 | modulo(2) == 0 %}
    <tr class="even">
  {% else %}
    <tr class="odd">
  {% endif %}
    <td>{{ item }}</td>
  </tr>
{% endfor %}
```

**Progress indicator:**

```
{% for item in items %}
  [{{ forloop.index }}/{{ forloop.length }}] {{ item }}
{% endfor %}
```

## Empty Loop Handling

Check if loop will run:

```
{% if items %}
  {% for item in items %}
    {{ item }}
  {% endfor %}
{% else %}
  No items to display
{% endif %}
```

Or with length filter:

```
{% if items | length > 0 %}
  Found {{ items | length }} items
{% else %}
  No items found
{% endif %}
```

## Control Patterns

### Conditional List Items

```
<ul>
{% for item in items %}
  {% if item.active %}
    <li>{{ item.name }}</li>
  {% endif %}
{% endfor %}
</ul>
```

### Role-Based Display

```
{% if user.admin %}
  <div class="admin-tools">
    <button>Ban User</button>
    <button>Edit Settings</button>
  </div>
{% elsif user.moderator %}
  <div class="mod-tools">
    <button>Warn User</button>
  </div>
{% endif %}
```

### Permission Checks

```
{% if user.can_edit_post %}
  <button class="edit">Edit</button>
{% endif %}

{% if user.can_delete_post and post.owner == user.id %}
  <button class="delete">Delete</button>
{% endif %}
```

### Status Indicators

```
{% for order in orders %}
  <div class="order">
    Order #{{ order.id }}
    {% if order.status == "pending" %}
      <span class="pending">Pending</span>
    {% elsif order.status == "shipped" %}
      <span class="shipped">Shipped</span>
    {% elsif order.status == "delivered" %}
      <span class="delivered">Delivered</span>
    {% else %}
      <span class="unknown">Unknown</span>
    {% endif %}
  </div>
{% endfor %}
```

### Pagination Indicators

```
Page {{ current_page }} of {{ total_pages }}

{% if current_page > 1 %}
  <a href="?page={{ current_page | minus(1) }}">Previous</a>
{% endif %}

{% if current_page < total_pages %}
  <a href="?page={{ current_page | plus(1) }}">Next</a>
{% endif %}
```

### Default Values

```
{% if user.bio %}
  Bio: {{ user.bio }}
{% else %}
  Bio: Not provided
{% endif %}
```

Or with filters:

```
Name: {{ user.name | default("Anonymous") }}
```

## Common Mistakes

### Wrong Operator

```
{# Wrong - string comparison #}
{% if items == [] %}

{# Right - check length #}
{% if items | length == 0 %}

{# Or - check truthiness #}
{% if items %}
```

### Missing Endif

```
{# Syntax error #}
{% if condition %}
  Content

{# Correct #}
{% if condition %}
  Content
{% endif %}
```

### Truthiness Confusion

```
{# 0 is truthy in Mau #}
{% if count == 0 %}
  No items
{% endif %}

{# Not this #}
{% if not count %}
  (0 is truthy, this won't work)
{% endif %}
```

## Advanced Patterns

### Ternary-like Pattern

Simulate ternary with inline if:

```
Status: {% if active %}Online{% else %}Offline{% endif %}
```

### Guard Clauses

Use early returns with negation:

```
{% if not user %}
  Please log in
{% else %}
  Welcome {{ user.name }}
{% endif %}
```

### Multi-Level Conditions

```
{% if user %}
  {% if user.admin %}
    Admin: {{ user.name }}
  {% elsif user.active %}
    Active: {{ user.name }}
  {% else %}
    Inactive: {{ user.name }}
  {% endif %}
{% else %}
  No user
{% endif %}
```

## Summary

| Feature | Syntax | Purpose |
|---------|--------|---------|
| If | `{% if condition %}` | Conditional rendering |
| Else | `{% else %}` | Alternative content |
| Elsif | `{% elsif condition %}` | Multiple conditions |
| For | `{% for x in y %}` | Iterate collections |
| forloop.index | `{{ forloop.index }}` | Current position (1-based) |
| forloop.first | `{{ forloop.first }}` | True on first item |
| forloop.last | `{{ forloop.last }}` | True on last item |
| and | `condition1 and condition2` | Logical AND |
| or | `condition1 or condition2` | Logical OR |
| not | `not condition` | Logical NOT |

## See Also

- [Template Syntax Guide](template-syntax.md) - Expression syntax
- [Variables Guide](variables.md) - Variable access patterns
- [Filters Guide](filters.md) - Using filters in conditions
