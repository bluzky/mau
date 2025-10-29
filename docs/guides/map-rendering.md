# Map Rendering Guide

Master advanced data transformations with map directives.

## Overview

The `render_map` function enables powerful data transformations within nested map structures using special directives. Directives allow you to iterate, filter, merge, and conditionally render maps—similar to a data transformation pipeline.

## When to Use render_map

Use `render_map` when you need to:
- Transform nested data structures
- Build complex outputs programmatically
- Filter and map collections
- Merge multiple data sources
- Apply conditional logic to structured data

Use regular `render` when you need to:
- Generate text/HTML output
- Render simple templates
- Control flow in text documents

## Basic Usage

```elixir
input = %{
  "greeting" => "Hello {{ name }}!"
}

context = %{"name" => "World"}

{:ok, result} = Mau.render_map(input, context)
# result: %{"greeting" => "Hello World!"}
```

## Directives Overview

All directives use keys starting with `#`:

| Directive | Purpose | Syntax |
|-----------|---------|--------|
| `#map` | Iterate over collections | `"#map" => [collection, template]` |
| `#filter` | Filter collections | `"#filter" => [collection, condition]` |
| `#merge` | Combine maps | `"#merge" => [map1, map2, ...]` |
| `#if` | Conditional rendering | `"#if" => [condition, true_template, false_template]` |
| `#pick` | Extract keys from map | `"#pick" => [map, keys]` |
| `#pipe` | Thread data through transformations | `"#pipe" => [initial, directives]` |

## #map Directive

Iterate over a collection and apply a template to each item.

### Syntax

```elixir
%{
  "key" => %{
    "#map" => [collection_template, item_template]
  }
}
```

### Basic Example

```elixir
input = %{
  "users" => %{
    "#map" => [
      "{{$users}}",
      %{"name" => "{{$loop.item.name}}"}
    ]
  }
}

context = %{
  "$users" => [
    %{"name" => "Alice"},
    %{"name" => "Bob"}
  ]
}

{:ok, result} = Mau.render_map(input, context)
# result: %{"users" => [%{"name" => "Alice"}, %{"name" => "Bob"}]}
```

### Access Loop Variables

Available in the item template:

```elixir
%{
  "#map" => [
    "{{$items}}",
    %{
      "index" => "{{$loop.index}}",
      "item" => "{{$loop.item}}",
      "is_first" => "{{$loop.first}}"
    }
  ]
}
```

**Loop variables:**
- `$loop.item` - Current item
- `$loop.index` - Position (0-based)
- `$loop.parentloop` - Parent loop (in nested maps)

### Nested Maps

```elixir
input = %{
  "departments" => %{
    "#map" => [
      "{{$departments}}",
      %{
        "name" => "{{$loop.item.name}}",
        "employees" => %{
          "#map" => [
            "{{$loop.item.employees}}",
            %{"name" => "{{$loop.item.name}}"}
          ]
        }
      }
    ]
  }
}
```

## #filter Directive

Filter items based on a condition.

### Syntax

```elixir
%{
  "key" => %{
    "#filter" => [collection_template, condition_template]
  }
}
```

### Example

```elixir
input = %{
  "active_users" => %{
    "#filter" => [
      "{{$users}}",
      "{{$loop.item.active}}"
    ]
  }
}

context = %{
  "$users" => [
    %{"name" => "Alice", "active" => true},
    %{"name" => "Bob", "active" => false},
    %{"name" => "Charlie", "active" => true}
  ]
}

{:ok, result} = Mau.render_map(input, context)
# result: %{"active_users" => [
#   %{"name" => "Alice", "active" => true},
#   %{"name" => "Charlie", "active" => true}
# ]}
```

### Complex Conditions

```elixir
"#filter" => [
  "{{$users}}",
  "{{$loop.item.age > 18 and $loop.item.verified}}"
]
```

## #merge Directive

Combine multiple maps together.

### Syntax

```elixir
%{
  "key" => %{
    "#merge" => [map1_template, map2_template, ...]
  }
}
```

### Example

```elixir
input = %{
  "user_profile" => %{
    "#merge" => [
      "{{$user}}",
      %{"role" => "{{$role}}", "verified" => true}
    ]
  }
}

context = %{
  "$user" => %{"name" => "Alice", "email" => "alice@example.com"},
  "$role" => "admin"
}

{:ok, result} = Mau.render_map(input, context)
# result: %{"user_profile" => %{
#   "name" => "Alice",
#   "email" => "alice@example.com",
#   "role" => "admin",
#   "verified" => true
# }}
```

## #if Directive

Conditionally render templates.

### Syntax

```elixir
# With else
%{
  "key" => %{
    "#if" => [condition, true_template, false_template]
  }
}

# Without else
%{
  "key" => %{
    "#if" => [condition, true_template]
  }
}
```

### Example

```elixir
input = %{
  "status" => %{
    "#if" => [
      "{{$user.premium}}",
      %{"level" => "premium", "price" => "$9.99"},
      %{"level" => "free", "price" => "free"}
    ]
  }
}

context = %{
  "$user" => %{"name" => "Alice", "premium" => true}
}

{:ok, result} = Mau.render_map(input, context)
# result: %{"status" => %{"level" => "premium", "price" => "$9.99"}}
```

## #pick Directive

Extract specific keys from a map.

### Syntax

```elixir
%{
  "key" => %{
    "#pick" => [map_template, keys]
  }
}
```

### Example

```elixir
input = %{
  "public_profile" => %{
    "#pick" => [
      "{{$user}}",
      ["name", "email", "avatar"]
    ]
  }
}

context = %{
  "$user" => %{
    "name" => "Alice",
    "email" => "alice@example.com",
    "avatar" => "alice.jpg",
    "password_hash" => "secret"  # Won't be included
  }
}

{:ok, result} = Mau.render_map(input, context)
# result: %{"public_profile" => %{
#   "name" => "Alice",
#   "email" => "alice@example.com",
#   "avatar" => "alice.jpg"
# }}
```

## #pipe Directive

Thread data through a series of transformations.

### Syntax

```elixir
%{
  "key" => %{
    "#pipe" => [initial_value, [directive1, directive2, ...]]
  }
}
```

### How It Works

The piped value is automatically injected as the first argument to each directive. Access it via `$self` context variable.

### Basic Example

```elixir
input = %{
  "result" => %{
    "#pipe" => [
      "{{$items}}",
      [
        %{"#filter" => "{{$loop.item.price > 100}}"},
        %{"#map" => %{"name" => "{{$loop.item.name}}"}}
      ]
    ]
  }
}

context = %{
  "$items" => [
    %{"name" => "Item A", "price" => 50},
    %{"name" => "Item B", "price" => 150},
    %{"name" => "Item C", "price" => 200}
  ]
}

{:ok, result} = Mau.render_map(input, context)
# result: %{"result" => [
#   %{"name" => "Item B"},
#   %{"name" => "Item C"}
# ]}
```

### Multi-Stage Pipeline

```elixir
%{
  "#pipe" => [
    "{{$data}}",
    [
      %{"#filter" => "{{$loop.item.active}}"},
      %{"#map" => %{"username" => "{{$loop.item.name}}"}},
      %{"#filter" => "{{$loop.item.username != 'admin'}}"}
    ]
  ]
}
```

## Advanced Patterns

### Combining Directives

Use multiple directives in nested structures:

```elixir
input = %{
  "report" => %{
    "#merge" => [
      %{"title" => "User Report"},
      %{
        "users" => %{
          "#map" => [
            "{{$users}}",
            %{
              "name" => "{{$loop.item.name}}",
              "profile" => %{
                "#if" => [
                  "{{$loop.item.premium}}",
                  %{"tier" => "premium"},
                  %{"tier" => "free"}
                ]
              }
            }
          ]
        }
      }
    ]
  }
}
```

### Data Transformation Pipeline

Create data flows similar to Elixir pipes:

```elixir
input = %{
  "processed" => %{
    "#pipe" => [
      "{{$raw_data}}",
      [
        %{"#filter" => "{{not nil}}"},           # Remove nils
        %{"#map" => %{                            # Transform
          "value" => "{{$loop.item | upper_case}}"
        }},
        %{"#filter" => "{{$loop.item.value}}"}   # Filter empty
      ]
    ]
  }
}
```

## Context Variables

Special variables available in templates:

```
{{$users}}              # From context
{{$loop.item}}          # Current item in map/filter
{{$loop.index}}         # Current index
{{$self}}               # Piped value (in pipe directive)
```

Regular template expressions also work:

```
"count" => "{{items | length}}"
"active" => "{{user.verified and user.active}}"
```

## Complete Example: API Response Transformation

Transform an API response into a structured format:

```elixir
input = %{
  "data" => %{
    "#merge" => [
      %{
        "timestamp" => "{{now}}",
        "source" => "api"
      },
      %{
        "users" => %{
          "#pipe" => [
            "{{$response.users}}",
            [
              %{"#filter" => "{{$loop.item.active}}"},
              %{"#map" => %{
                "id" => "{{$loop.item.id}}",
                "name" => "{{$loop.item.full_name}}",
                "contact" => %{
                  "#merge" => [
                    %{"email" => "{{$loop.item.email}}"},
                    %{"phone" => "{{$loop.item.phone}}"}
                  ]
                }
              }}
            ]
          ]
        }
      }
    ]
  }
}

context = %{
  "now" => "2024-01-15T10:30:00Z",
  "$response" => %{
    "users" => [
      %{
        "id" => 1,
        "full_name" => "Alice Johnson",
        "email" => "alice@example.com",
        "phone" => "555-0001",
        "active" => true
      },
      %{
        "id" => 2,
        "full_name" => "Bob Smith",
        "email" => "bob@example.com",
        "phone" => "555-0002",
        "active" => false
      }
    ]
  }
}

{:ok, result} = Mau.render_map(input, context)
```

Result:

```elixir
%{
  "data" => %{
    "timestamp" => "2024-01-15T10:30:00Z",
    "source" => "api",
    "users" => [
      %{
        "id" => 1,
        "name" => "Alice Johnson",
        "contact" => %{
          "email" => "alice@example.com",
          "phone" => "555-0001"
        }
      }
    ]
  }
}
```

## Comparing render vs render_map

| Feature | render | render_map |
|---------|--------|-----------|
| **Output Type** | String | Map/Structure |
| **Use Case** | Text/HTML output | Data transformation |
| **Syntax** | `{{ }}` and `{% %}` | Directive maps |
| **Iteration** | `{% for %}` | `#map` directive |
| **Filtering** | `\| filter` | `#filter` directive |
| **Conditionals** | `{% if %}` | `#if` directive |

## Best Practices

1. **Validate Input Data**

Always check if required data exists before transforming.

2. **Use Meaningful Directive Keys**

```elixir
%{
  "active_users" => %{    # Clear intent
    "#filter" => [...]
  }
}
```

3. **Break Down Complex Transformations**

Use intermediate steps for clarity:

```elixir
%{
  "filtered" => %{
    "#filter" => [...]
  },
  "transformed" => %{
    "#map" => ["{{filtered}}", ...]
  }
}
```

4. **Comment Complex Structures**

```elixir
# Step 1: Filter active users
# Step 2: Map to names only
# Step 3: Sort results
%{"#pipe" => [...]}
```

## Troubleshooting

### Directive Not Applied

**Problem:** Directive key not recognized

**Solution:** Verify syntax and ensure arguments are lists

```elixir
# Wrong
%{"#map" => "{{items}}"}

# Right
%{"#map" => ["{{items}}", item_template]}
```

### Empty Results

**Problem:** Directive returns empty

**Solution:** Check collection is rendering correctly

```elixir
# Debug: render collection first
{:ok, items} = Mau.render("{{$items}}", context)
IO.inspect(items)
```

### Type Errors

**Problem:** Wrong data type to directive

**Solution:** Ensure correct types:
- `#map` and `#filter` need lists
- `#merge` needs maps
- `#pick` needs map and key list

## See Also

- [Template Syntax Guide](template-syntax.md) - Template expressions
- [Variables Guide](variables.md) - Variable access
- [Map Directives Reference](../reference/map-directives.md) - Complete directive reference
- [Data Transformation Examples](../examples/data-transformation.md) - Real-world map rendering examples
