# Map Directives Reference

This document provides a comprehensive reference for the map directive system in Mau, which enables advanced template transformations within map structures.

## Overview

Map directives are special map keys that start with `#` and provide powerful transformation capabilities for template rendering. They allow you to iterate, filter, merge, conditionally render, and extract data within nested map structures.

## render_map Function

The main entry point for using map directives is the `render_map/3` function.

### Function Signature

```elixir
render_map(nested_map, context, opts \\ [])
```

### Parameters

- `nested_map` - A map containing templates and directives to be rendered
- `context` - A map containing variables and data available to templates
- `opts` - Optional keyword list for rendering configuration

### Returns

- `{:ok, rendered_map}` - Successfully rendered map with all directives applied
- `{:error, error}` - Error information if rendering fails

### Basic Usage

```elixir
input = %{
  users: %{
    "#map" => [
      "{{$users}}",
      %{name: "{{$loop.item.name}}", email: "{{$loop.item.email}}"}
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
# result: %{users: [%{name: "John", email: "john@example.com"}, %{name: "Jane", email: "jane@example.com"}]}
```

## Available Directives

### `#pipe` - Data Pipeline

Threads data through a series of transformations, similar to Elixir's `|>` operator. Each directive in the chain automatically receives the output of the previous directive as its first argument.

#### Syntax

```elixir
"#pipe" => [initial_template, [directive1, directive2, ...]]
```

#### Parameters

- `initial_template` - Template that resolves to the starting value
- `directives` - List of directive maps to apply in sequence

#### How It Works

1. The initial value is rendered from `initial_template`
2. Each directive in the list receives the previous result as its **first argument** (auto-injected)
3. The result flows through the chain, with each directive transforming it
4. The `$self` context variable is available within each stage (refers to the piped value)
5. For `#map` and `#filter`, use `$loop.item` to access individual items (not `$self.item`)

#### Examples

**Basic pipeline - Filter then Map:**
```elixir
%{
  active_users: %{
    "#pipe" => [
      "{{$users}}",
      [
        %{"#filter" => "{{$loop.item.active}}"},
        %{"#map" => %{name: "{{$loop.item.name}}"}}
      ]
    ]
  }
}
```

**Map then Merge:**
```elixir
%{
  enriched: %{
    "#pipe" => [
      "{{$products}}",
      [
        %{"#map" => %{name: "{{$loop.item.name}}"}},
        %{"#map" => %{
          "#merge" => [
            "{{$loop.item}}",
            %{company: "{{$company}}"}
          ]
        }}
      ]
    ]
  }
}
```

**Single map through Merge and Pick:**
```elixir
%{
  user_profile: %{
    "#pipe" => [
      "{{$user}}",
      [
        %{"#merge" => %{status: "active"}},
        %{"#merge" => %{last_login: "2024-01-15"}},
        %{"#pick" => ["name", "email", :status, :last_login]}
      ]
    ]
  }
}
```

**Complex pipeline with conditionals:**
```elixir
%{
  premium_items: %{
    "#pipe" => [
      "{{$items}}",
      [
        %{"#filter" => "{{$loop.item.price > 100}}"},
        %{"#map" => %{
          "#if" => [
            "{{$loop.item.premium}}",
            %{name: "{{$loop.item.name}}", badge: "premium"},
            %{name: "{{$loop.item.name}}", badge: "standard"}
          ]
        }}
      ]
    ]
  }
}
```

**Nested pipes:**
```elixir
%{
  departments: %{
    "#pipe" => [
      "{{$departments}}",
      [
        %{"#map" => %{
          dept: "{{$loop.item.name}}",
          active_staff: %{
            "#pipe" => [
              "{{$loop.item.employees}}",
              [
                %{"#filter" => "{{$loop.item.active}}"},
                %{"#map" => %{name: "{{$loop.item.name}}"}}
              ]
            ]
          }
        }}
      ]
    ]
  }
}
```

#### Key Notes

- Each directive automatically receives the piped value as its first argument
- You don't need to specify the collection/map argument for directives in the pipe
- Use `$loop.item` for map/filter operations (standard behavior)
- Use `$self` to access the raw piped value when needed
- Empty directive list returns the initial value unchanged
- Nested pipes work independently with their own `$self` context

### `#map` - Collection Iteration

Iterates over a collection and applies a template to each item, creating a `$loop` context variable for each iteration.

#### Syntax

```elixir
"#map" => [collection_template, item_template]
```

#### Parameters

- `collection_template` - Template that resolves to a list to iterate over
- `item_template` - Template to apply to each item in the collection

#### Loop Context Variable

Each iteration has access to a `$loop` variable with the following structure:

```elixir
$loop = %{
  "item" => %{},           # Current iteration item
  "index" => 0,            # Current iteration index (0-based)
  "parentloop" => $loop    # Reference to parent $loop (or nil for outermost)
}
```

#### Examples

**Basic iteration:**
```elixir
%{
  items: %{
    "#map" => [
      "{{$products}}",
      %{name: "{{$loop.item.name}}", price: "{{$loop.item.price}}"}
    ]
  }
}
```

**Index access:**
```elixir
%{
  items: %{
    "#map" => [
      "{{$products}}",
      %{
        name: "{{$loop.item.name}}",
        position: "{{$loop.index}}",
        is_first: "{{$loop.index == 0}}"
      }
    ]
  }
}
```

**Nested property access:**
```elixir
%{
  users: %{
    "#map" => [
      "{{$users}}",
      %{
        full_name: "{{$loop.item.profile.firstName}} {{$loop.item.profile.lastName}}",
        contact: "{{$loop.item.contact.email}}"
      }
    ]
  }
}
```

**Accessing context variables alongside $loop.item:**
```elixir
%{
  products: %{
    "#map" => [
      "{{$products}}",
      %{
        name: "{{$loop.item.name}}",
        company: "{{$company}}",
        in_stock: "{{$loop.item.quantity > 0}}"
      }
    ]
  }
}
```

**Nested loops with parent access:**
```elixir
%{
  departments: %{
    "#map" => [
      "{{$departments}}",
      %{
        dept_name: "{{$loop.item.name}}",
        employees: %{
          "#map" => [
            "{{$loop.item.employees}}",
            %{
              emp_name: "{{$loop.item.name}}",
              department: "{{$loop.parentloop.item.name}}",
              dept_index: "{{$loop.parentloop.index}}"
            }
          ]
        }
      }
    ]
  }
}
```

### `#merge` - Map Combination

Merges multiple maps together, with later values overriding earlier ones.

#### Syntax

```elixir
"#merge" => [template1, template2, ...]
```

#### Parameters

- `templates` - List of templates that resolve to maps to be merged

#### Examples

**Merging context data with static data:**
```elixir
%{
  user_profile: %{
    "#merge" => [
      "{{$user}}",
      %{last_login: "2024-01-15", status: "active"}
    ]
  }
}
```

**Merging multiple context sources:**
```elixir
%{
  combined_data: %{
    "#merge" => [
      "{{$base_config}}",
      "{{$user_config}}",
      "{{$system_defaults}}"
    ]
  }
}
```

### `#if` - Conditional Rendering

Conditionally renders one of two templates based on a boolean condition.

#### Syntax

```elixir
# With else clause
"#if" => [condition_template, true_template, false_template]

# Without else clause (renders nil when false)
"#if" => [condition_template, true_template]
```

#### Parameters

- `condition_template` - Template that should resolve to a truthy or falsy value
- `true_template` - Template to render when condition is truthy
- `false_template` - Optional template to render when condition is falsy

#### Truthy/Falsy Values

**Truthy:** `true`, non-empty strings, non-zero numbers, non-empty lists/maps, any other value
**Falsy:** `nil`, `false`, `""` (empty string), `[]` (empty list), `{}` (empty map)

#### Examples

**Simple conditional:**
```elixir
%{
  status_badge: %{
    "#if" => [
      "{{$user.is_active}}",
      %{badge: "active", color: "green"},
      %{badge: "inactive", color: "red"}
    ]
  }
}
```

**Without else clause:**
```elixir
%{
  admin_panel: %{
    "#if" => [
      "{{$user.is_admin}}",
      %{admin_tools: "enabled"}
    ]
  }
}
```

**Complex conditions:**
```elixir
%{
  pricing: %{
    "#if" => [
      "{{$loop.item.premium_user}}",
      %{price: "{{$loop.item.price}}", discount: "0.9"},
      %{price: "{{$loop.item.base_price}}"}
    ]
  }
}
```

### `#filter` - Collection Filtering

Filters items in a collection based on a condition template. Each item is accessible via the `$loop` variable during filtering.

#### Syntax

```elixir
"#filter" => [collection_template, condition_template]
```

#### Parameters

- `collection_template` - Template that resolves to a list to filter
- `condition_template` - Template that should resolve to truthy/falsy for each item

#### Loop Context Access

During filtering, each item has access to the same `$loop` structure as the `#map` directive, providing `$loop.item` and `$loop.index` for conditional logic.

#### Examples

**Filter active users:**
```elixir
%{
  active_users: %{
    "#filter" => [
      "{{$users}}",
      "{{$loop.item.status == 'active'}}"
    ]
  }
}
```

**Filter by numeric comparison:**
```elixir
%{
  expensive_products: %{
    "#filter" => [
      "{{$products}}",
      "{{$loop.item.price > 100}}"
    ]
  }
}
```

**Filter with index logic:**
```elixir
%{
  first_five_items: %{
    "#filter" => [
      "{{$items}}",
      "{{$loop.index < 5}}"
    ]
  }
}
```

**Complex filtering:**
```elixir
%{
  senior_engineers: %{
    "#filter" => [
      "{{$employees}}",
      "{{$loop.item.department == 'engineering' and $loop.item.level >= 4}}"
    ]
  }
}
```

### `#pick` - Key Extraction

Extracts specific keys from a map (similar to `Map.pick/2`).

#### Syntax

```elixir
"#pick" => [map_template, keys]
```

#### Parameters

- `map_template` - Template that resolves to a map
- `keys` - List of string keys to extract from the map

#### Examples

**User profile extraction:**
```elixir
%{
  public_profile: %{
    "#pick" => [
      "{{$user}}",
      ["name", "email", "avatar_url"]
    ]
  }
}
```

**Configuration extraction:**
```elixir
%{
  app_config: %{
    "#pick" => [
      "{{$full_config}}",
      ["app_name", "version", "debug_mode"]
    ]
  }
}
```

## Advanced Usage Patterns

### Nested Directives

Directives can be nested for complex transformations:

```elixir
%{
  departments: %{
    "#map" => [
      "{{$departments}}",
      %{
        "#merge" => [
          "{{$loop.item}}",
          %{
            senior_staff: %{
              "#filter" => [
                "{{$loop.item.employees}}",
                "{{$loop.item.level >= 4}}"
              ]
            }
          }
        ]
      }
    ]
  }
}
```

### Context Variables

Directives have access to all context variables:

- `$loop` - Loop context structure (available in `#map` and `#filter`)
  - `$loop.item` - Current iteration item
  - `$loop.index` - Current iteration index (0-based)
  - `$loop.parentloop` - Parent loop context (for nested loops)
- Custom variables passed to `render_map/3`

### Error Handling

Invalid directive arguments are treated as regular map keys rather than causing errors:

```elixir
%{
  # This will be treated as a regular map key, not an error
  "#map" => "invalid arguments",

  # This will also be treated as a regular map key
  "#filter" => ["{{$items}}"]  # Missing condition template
}
```

### Type Preservation

The `render_map` function automatically enables type preservation to maintain data types:

```elixir
context = %{
  "$numbers" => [1, 2, 3],  # These numbers will stay as numbers
  "$config" => %{debug: true}  # This boolean will stay as boolean
}
```

## Integration with Template System

Map directives integrate seamlessly with the existing Mau template system:


## Performance Considerations

1. **Collection Size**: Large collections processed with `#map` and `#filter` will impact performance
2. **Template Complexity**: Complex templates within directives take longer to render
3. **Nesting Depth**: Deeply nested directives create more recursive calls
4. **Context Size**: Large context maps consume more memory

## Troubleshooting

### Common Issues

1. **Directive Not Applied**: Check that arguments are in a list format
2. **Empty Results**: Verify that collection templates resolve to actual lists
3. **Missing $loop**: Ensure you're using `#map` or `#filter` when trying to access `$loop.item`
4. **Incorrect variable access**: Use `$loop.item` instead of `$self`, and `$loop.index` for position
5. **Parent access issues**: Check that `$loop.parentloop` is only available in nested loops
6. **Type Issues**: Remember that template rendering converts values to strings unless type preservation is enabled

