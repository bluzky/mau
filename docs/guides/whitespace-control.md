# Whitespace Control Guide

Master whitespace handling in templates.

## The Problem

Templates often have unwanted whitespace in the output:

```
{% for item in items %}
  Item: {{ item }}
{% endfor %}
```

This produces:

```

  Item: 1

  Item: 2

  Item: 3

```

Notice the extra newlines and spaces. Whitespace control lets you remove them.

## Whitespace Modifiers

Use `-` at the start or end of tags to trim whitespace.

### Trim Left (Left Dash)

```
{{- expression }}
{%- tag %}
```

The dash removes whitespace to the left:

```
Text  {{- "value" }}
```

Renders as: `Textvalue` (no space before value)

### Trim Right (Right Dash)

```
{{ expression -}}
{% tag -%}
```

The dash removes whitespace to the right:

```
{{ "value" -}}  Text
```

Renders as: `valueText` (no space after value)

### Trim Both

```
{{- expression -}}
{%- tag -%}
```

Removes whitespace on both sides:

```
Text  {{- "value" -}}  More
```

Renders as: `TextvalueMore`

## Common Use Cases

### Removing Loop Newlines

**Without whitespace control:**

```
{% for item in items %}
  {{ item }}
{% endfor %}
```

Output:
```

  Item1

  Item2

  Item3

```

**With whitespace control:**

```
{%- for item in items -%}
  {{ item }}
{%- endfor -%}
```

Output:
```
  Item1  Item2  Item3
```

Or with newlines but no extra indentation:

```
{% for item in items -%}
{{ item }}
{% endfor -%}
```

Output:
```
Item1
Item2
Item3
```

### Clean HTML Generation

**Without whitespace control:**

```
<ul>
{% for item in items %}
  <li>{{ item }}</li>
{% endfor %}
</ul>
```

Output:
```html
<ul>

  <li>Item1</li>

  <li>Item2</li>

</ul>
```

**With whitespace control:**

```
<ul>
{%- for item in items %}
  <li>{{ item }}</li>
{%- endfor %}
</ul>
```

Output:
```html
<ul>
  <li>Item1</li>
  <li>Item2</li>
</ul>
```

### Conditional Text

```
Status: {% if active -%}Active{%- else -%}Inactive{%- endif %}
```

Without trim, this would have spaces: `Status:  Active` or `Status:  Inactive`
With trim: `Status: Active` or `Status: Inactive`

### Joining Items

Create a comma-separated list:

```
{% for item in items -%}
  {{ item }}{{ if not forloop.last -%}}, {% endif -%}}
{%- endfor %}
```

This produces: `Item1, Item2, Item3` without trailing comma.

## Whitespace Breakdown

### Where Whitespace Appears

Whitespace includes:
- **Spaces** (` `)
- **Tabs** (`\t`)
- **Newlines** (`\n`)
- **Carriage returns** (`\r`)

### Whitespace Around Tags

```
before text
{% if condition %}
  content
{% endif %}
after text
```

The dashes control whitespace adjacent to tags:

```
before text{%- if condition %}content{%- endif -%}after text
```

## Advanced Patterns

### CSV Generation

```
{%- for item in items -%}
{{ item.id }},{{ item.name }}
{% endfor -%}
```

Produces:
```
1,Item1
2,Item2
3,Item3
```

### Email Templates

```
Hello {{ user.name }},

{%- if order %}

Your order details:
- Order ID: {{ order.id }}
- Total: ${{ order.total }}

{%- endif %}

Best regards,
Team
```

### JSON Output

```
{
  "items": [
    {%- for item in items %}
    {
      "id": {{ item.id }},
      "name": "{{ item.name }}"
    }{{ if not forloop.last }},{% endif -%}}
    {%- endfor %}
  ]
}
```

### Nested Loops with Formatting

```
{%- for category in categories %}
Category: {{ category.name }}
{%- for item in category.items %}
  - {{ item }}
{%- endfor -%}}
{% endfor -%}
```

## Common Mistakes

### Over-trimming

```
{%- for item in items -%}{{- item -}}{%- endfor -%}
```

This removes ALL whitespace, including necessary spacing.

**Better approach:** Only trim where needed:

```
{% for item in items -%}
{{ item }}
{% endfor -%}
```

### Inconsistent Indentation

Mixing trimmed and non-trimmed tags:

```
{% for item in items %}      {# Doesn't trim #}
  {{- item -}}              {# Trims expressions #}
{% endfor %}                {# Doesn't trim #}
```

**Better:** Be consistent:

```
{%- for item in items %}
  {{ item }}
{%- endfor -%}
```

### Trimming Necessary Spaces

```
Hello {{ name }}!    {# Good #}
Hello {{- name -}}!  {# Bad: "Hellothere!" #}
```

## Debugging Whitespace

### Enable Whitespace Visibility

In your testing environment, show whitespace:

```
{:ok, result} = Mau.render(template, context)
IO.inspect(result)  # Shows \n and spacing
```

### Use Different Markers

Test with markers to see what's trimmed:

```
[{% if true -%}content{%- endif %}]
[before {{- "x" -}} after]
```

View the output in a way that shows spaces:

```
result |> String.replace(" ", "·") |> IO.puts()
```

## Whitespace Best Practices

1. **Trim only where necessary** - Don't over-trim and lose important spacing

2. **Be consistent** - Use the same trimming pattern throughout templates

3. **Test output** - Always verify the rendered output looks correct

4. **Document intent** - Add comments if trimming is non-obvious:

```
{%- # Remove newline before list #}
<ul>
{%- for item in items %}
  <li>{{ item }}</li>
{%- endfor %}
</ul>
```

5. **Read-in-template vs Output** - Remember the template source and output can look very different

## Examples

### Clean Markdown

```
# {{ title }}

{{ description }}

{%- for section in sections %}

## {{ section.name }}

{{ section.content }}
{%- endfor %}
```

### HTML Attributes

```
<div class="container{%- if active %} active{%- endif %}">
  Content
</div>
```

Or:

```
<div class="container {% if active %}active{% endif %}">
  Content
</div>
```

### Multi-line Conditionals

```
Status:
{%- if active %}
  <span class="active">Online</span>
{%- else %}
  <span class="inactive">Offline</span>
{%- endif %}
```

### Variable Declaration Block

```
{%- assign prefix = "Item" -%}
{%- assign count = items | length -%}
{{ prefix }} Count: {{ count }}
```

## Troubleshooting

### Extra Whitespace in Output

**Problem:** Output has unexpected spaces or newlines

**Solution:** Add `-` modifiers to trim

```
{%- for item in items -%}
```

### Missing Required Spaces

**Problem:** Output runs together

**Solution:** Don't trim where spaces are needed

```
Hello {{- name -}}!      {# Wrong: "Helloname!" #}
Hello {{ name }}!        {# Right: "Hello name!" #}
```

### Newlines Disappear

**Problem:** Text that should be on separate lines appears on one line

**Solution:** Don't trim newlines between lines

```
{%- # Keep newline by not trimming right side #}
Line 1
{%- if condition %}
Line 2
{%- endif %}
```

## Summary

| Modifier | Purpose | Example |
|----------|---------|---------|
| `{{- }}` | Trim left | `Text {{- value }}` |
| `{{ -}}` | Trim right | `{{ value -}} Text` |
| `{{- -}}` | Trim both | `{{- value -}}` |
| `{%- %}` | Trim left | `{%- if %}` |
| `{% -%}` | Trim right | `{% endif -%}` |
| `{%- -%}` | Trim both | `{%- if -%}` |

## See Also

- [Template Syntax Guide](template-syntax.md) - Full syntax reference
- [Control Flow Guide](control-flow.md) - Tags that work with whitespace
- [Examples](../examples/) - Real-world template examples
