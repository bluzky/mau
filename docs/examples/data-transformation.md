# Data Transformation Examples

Real-world examples of using map directives for complex data transformations.

## Overview

This guide demonstrates how to use `render_map` with directives (`#map`, `#filter`, `#merge`, `#pipe`, etc.) for powerful data transformation pipelines.

## Transform API Response

Transform a complex API response into a simplified format.

```elixir
input = %{
  "data" => %{
    "#merge" => [
      %{
        "timestamp" => "{{ now }}",
        "source" => "api"
      },
      %{
        "users" => %{
          "#filter" => [
            "{{$response.users}}",
            "{{$loop.item.active}}"
          ]
        }
      }
    ]
  }
}

context = %{
  "now" => DateTime.to_iso8601(DateTime.utc_now()),
  "$response" => %{
    "users" => [
      %{"id" => 1, "name" => "Alice", "active" => true, "email" => "alice@example.com"},
      %{"id" => 2, "name" => "Bob", "active" => false, "email" => "bob@example.com"},
      %{"id" => 3, "name" => "Charlie", "active" => true, "email" => "charlie@example.com"}
    ]
  }
}

{:ok, result} = Mau.render_map(input, context)

# Result:
# %{
#   "data" => %{
#     "timestamp" => "2024-10-29T14:30:00Z",
#     "source" => "api",
#     "users" => [
#       %{"id" => 1, "name" => "Alice", "active" => true, "email" => "alice@example.com"},
#       %{"id" => 3, "name" => "Charlie", "active" => true, "email" => "charlie@example.com"}
#     ]
#   }
# }
```

---

## Extract and Transform Fields

Extract specific fields from objects and rename them.

```elixir
input = %{
  "extracted" => %{
    "#map" => [
      "{{$items}}",
      %{
        "id" => "{{$loop.item.product_id}}",
        "label" => "{{$loop.item.product_name}}",
        "price_usd" => "{{$loop.item.price}}"
      }
    ]
  }
}

context = %{
  "$items" => [
    %{
      "product_id" => 101,
      "product_name" => "Laptop",
      "price" => 999.99,
      "category" => "Electronics"
    },
    %{
      "product_id" => 102,
      "product_name" => "Mouse",
      "price" => 29.99,
      "category" => "Accessories"
    }
  ]
}

{:ok, result} = Mau.render_map(input, context)

# Result:
# %{
#   "extracted" => [
#     %{"id" => 101, "label" => "Laptop", "price_usd" => 999.99},
#     %{"id" => 102, "label" => "Mouse", "price_usd" => 29.99}
#   ]
# }
```

---

## Group and Aggregate Data

Group data by category and aggregate values.

```elixir
input = %{
  "summary" => %{
    "by_category" => %{
      "#group_by" => [
        "{{$products}}",
        "category"
      ]
    },
    "enriched" => %{
      "#pipe" => [
        "{{$products}}",
        [
          %{
            "#filter" => "{{$loop.item.stock > 0}}"
          },
          %{
            "#map" => %{
              "name" => "{{$loop.item.name}}",
              "category" => "{{$loop.item.category}}",
              "total_value" => "{{$loop.item.price * $loop.item.stock}}"
            }
          }
        ]
      ]
    }
  }
}

context = %{
  "$products" => [
    %{"name" => "Laptop", "category" => "Electronics", "price" => 999.99, "stock" => 5},
    %{"name" => "Mouse", "category" => "Accessories", "price" => 29.99, "stock" => 50},
    %{"name" => "Monitor", "category" => "Electronics", "price" => 399.99, "stock" => 0},
    %{"name" => "Keyboard", "category" => "Accessories", "price" => 79.99, "stock" => 25}
  ]
}

{:ok, result} = Mau.render_map(input, context)

# Result shows grouped data and pipeline-transformed inventory value
```

---

## Conditional Data Transformation

Transform data differently based on conditions.

```elixir
input = %{
  "users" => %{
    "#map" => [
      "{{$users}}",
      %{
        "id" => "{{$loop.item.id}}",
        "name" => "{{$loop.item.name}}",
        "status" => %{
          "#if" => [
            "{{$loop.item.premium}}",
            %{
              "tier" => "premium",
              "features" => ["advanced", "priority_support", "api_access"],
              "monthly_cost" => 29.99
            },
            %{
              "tier" => "free",
              "features" => ["basic"],
              "monthly_cost" => 0
            }
          ]
        }
      }
    ]
  }
}

context = %{
  "$users" => [
    %{"id" => 1, "name" => "Alice", "premium" => true},
    %{"id" => 2, "name" => "Bob", "premium" => false},
    %{"id" => 3, "name" => "Charlie", "premium" => true}
  ]
}

{:ok, result} = Mau.render_map(input, context)

# Result:
# %{
#   "users" => [
#     %{
#       "id" => 1,
#       "name" => "Alice",
#       "status" => %{
#         "tier" => "premium",
#         "features" => ["advanced", "priority_support", "api_access"],
#         "monthly_cost" => 29.99
#       }
#     },
#     ...
#   ]
# }
```

---

## Flatten Nested Structures

Transform nested data into a flat format.

```elixir
input = %{
  "flattened_orders" => %{
    "#pipe" => [
      "{{$orders}}",
      [
        %{
          "#map" => %{
            "order_id" => "{{$loop.item.id}}",
            "customer_name" => "{{$loop.item.customer.name}}",
            "customer_email" => "{{$loop.item.customer.email}}",
            "total" => "{{$loop.item.total}}",
            "status" => "{{$loop.item.status}}"
          }
        }
      ]
    ]
  }
}

context = %{
  "$orders" => [
    %{
      "id" => "ORD-001",
      "customer" => %{
        "name" => "Alice",
        "email" => "alice@example.com"
      },
      "total" => 299.99,
      "status" => "shipped"
    },
    %{
      "id" => "ORD-002",
      "customer" => %{
        "name" => "Bob",
        "email" => "bob@example.com"
      },
      "total" => 149.99,
      "status" => "processing"
    }
  ]
}

{:ok, result} = Mau.render_map(input, context)

# Result: Orders with nested customer data flattened to top level
```

---

## Enrich Data with Lookups

Transform data by adding information from reference tables.

```elixir
input = %{
  "enriched_orders" => %{
    "#map" => [
      "{{$orders}}",
      %{
        "id" => "{{$loop.item.id}}",
        "product_name" => "{{$loop.item.product_id}}",
        "quantity" => "{{$loop.item.quantity}}",
        "price_per_unit" => "{{$loop.item.quantity}}",
        "category" => "{{$loop.item.product_id}}"
      }
    ]
  }
}

context = %{
  "$orders" => [
    %{"id" => 1, "product_id" => 101, "quantity" => 2},
    %{"id" => 2, "product_id" => 102, "quantity" => 1}
  ],
  "$products" => %{
    101 => %{"name" => "Laptop", "price" => 999.99, "category" => "Electronics"},
    102 => %{"name" => "Mouse", "price" => 29.99, "category" => "Accessories"}
  }
}

{:ok, result} = Mau.render_map(input, context)
```

---

## Pivot Data Structure

Transform data into a pivot table format.

```elixir
input = %{
  "pivot" => %{
    "#map" => [
      "{{$categories}}",
      %{
        "category" => "{{$loop.item}}",
        "products" => %{
          "#filter" => [
            "{{$all_products}}",
            "{{$loop.item.category == $loop.parentloop.item}}"
          ]
        }
      }
    ]
  }
}

context = %{
  "$categories" => ["Electronics", "Accessories"],
  "$all_products" => [
    %{"name" => "Laptop", "category" => "Electronics"},
    %{"name" => "Monitor", "category" => "Electronics"},
    %{"name" => "Mouse", "category" => "Accessories"},
    %{"name" => "Keyboard", "category" => "Accessories"}
  ]
}

{:ok, result} = Mau.render_map(input, context)

# Result: Products grouped by category
```

---

## Filter and Aggregate Pipeline

Complex multi-stage transformation.

```elixir
input = %{
  "sales_summary" => %{
    "#pipe" => [
      "{{$sales}}",
      [
        # Stage 1: Filter sales above minimum
        %{
          "#filter" => "{{$loop.item.amount > 100}}"
        },
        # Stage 2: Transform to summary format
        %{
          "#map" => %{
            "region" => "{{$loop.item.region}}",
            "amount" => "{{$loop.item.amount}}",
            "tax" => "{{$loop.item.amount * 0.1}}",
            "total" => "{{$loop.item.amount * 1.1}}"
          }
        },
        # Stage 3: Filter by region (example)
        %{
          "#filter" => "{{$loop.item.region == 'North America'}}"
        }
      ]
    ]
  }
}

context = %{
  "$sales" => [
    %{"region" => "North America", "amount" => 500},
    %{"region" => "Europe", "amount" => 250},
    %{"region" => "North America", "amount" => 75},
    %{"region" => "Asia", "amount" => 600}
  ]
}

{:ok, result} = Mau.render_map(input, context)

# Result: Sales filtered, transformed, and re-filtered for North America > $100
```

---

## Merge Multiple Data Sources

Combine data from multiple sources.

```elixir
input = %{
  "report" => %{
    "#merge" => [
      %{
        "generated_at" => "{{now}}",
        "report_type" => "monthly_summary"
      },
      %{
        "sales" => %{
          "#map" => [
            "{{$sales_data}}",
            %{
              "date" => "{{$loop.item.date}}",
              "amount" => "{{$loop.item.amount}}"
            }
          ]
        }
      },
      %{
        "expenses" => %{
          "#map" => [
            "{{$expense_data}}",
            %{
              "date" => "{{$loop.item.date}}",
              "amount" => "{{$loop.item.amount}}"
            }
          ]
        }
      },
      %{
        "summary" => %{
          "total_sales" => "{{$total_sales}}",
          "total_expenses" => "{{$total_expenses}}",
          "net_profit" => "{{$total_sales - $total_expenses}}"
        }
      }
    ]
  }
}

context = %{
  "now" => DateTime.to_iso8601(DateTime.utc_now()),
  "$sales_data" => [
    %{"date" => "2024-10-01", "amount" => 1000},
    %{"date" => "2024-10-02", "amount" => 1200}
  ],
  "$expense_data" => [
    %{"date" => "2024-10-01", "amount" => 300},
    %{"date" => "2024-10-02", "amount" => 250}
  ],
  "$total_sales" => 2200,
  "$total_expenses" => 550
}

{:ok, result} = Mau.render_map(input, context)

# Result: Combined report with sales, expenses, and summary merged together
```

---

## Deduplicate and Clean Data

Remove duplicates and clean invalid entries.

```elixir
input = %{
  "cleaned_emails" => %{
    "#pipe" => [
      "{{$email_list}}",
      [
        # Stage 1: Remove duplicates
        %{
          "#filter" => "{{$loop.index == 0 or $loop.item != $emails_before[$loop.index - 1]}}"
        },
        # Stage 2: Remove invalid formats
        %{
          "#filter" => "{{$loop.item | contains('@')}}"
        },
        # Stage 3: Normalize to lowercase
        %{
          "#map" => %{
            "email" => "{{$loop.item | lower_case}}"
          }
        }
      ]
    ]
  }
}

context = %{
  "$email_list" => [
    "Alice@Example.com",
    "alice@example.com",
    "bob@example.com",
    "invalid-email",
    "charlie@example.com",
    "Bob@Example.com"
  ]
}

{:ok, result} = Mau.render_map(input, context)

# Result: Deduplicated, validated, and normalized email list
```

---

## Hierarchical Data Transformation

Transform hierarchical/tree data structures.

```elixir
input = %{
  "organization_chart" => %{
    "#map" => [
      "{{$departments}}",
      %{
        "dept_name" => "{{$loop.item.name}}",
        "dept_id" => "{{$loop.item.id}}",
        "employees" => %{
          "#filter" => [
            "{{$all_employees}}",
            "{{$loop.item.department_id == $loop.parentloop.item.id}}"
          ]
        }
      }
    ]
  }
}

context = %{
  "$departments" => [
    %{"id" => 1, "name" => "Engineering"},
    %{"id" => 2, "name" => "Sales"}
  ],
  "$all_employees" => [
    %{"name" => "Alice", "department_id" => 1},
    %{"name" => "Bob", "department_id" => 1},
    %{"name" => "Charlie", "department_id" => 2}
  ]
}

{:ok, result} = Mau.render_map(input, context)

# Result: Departments with their employees nested underneath
```

---

## Create Summary Statistics

Transform detailed data into summary statistics.

```elixir
input = %{
  "summary_stats" => %{
    "by_category" => %{
      "#map" => [
        "{{$categories}}",
        %{
          "category" => "{{$loop.item}}",
          "products" => %{
            "#filter" => [
              "{{$products}}",
              "{{$loop.item.category == $loop.parentloop.item}}"
            ]
          }
        }
      ]
    }
  }
}

context = %{
  "$categories" => ["Electronics", "Accessories"],
  "$products" => [
    %{"name" => "Laptop", "category" => "Electronics", "price" => 999.99},
    %{"name" => "Monitor", "category" => "Electronics", "price" => 399.99},
    %{"name" => "Mouse", "category" => "Accessories", "price" => 29.99}
  ]
}

{:ok, result} = Mau.render_map(input, context)

# Result: Summary statistics by category
```

---

## Best Practices

### 1. Use Meaningful Directive Names

```elixir
# Good: Clear intent
%{
  "active_customers" => %{
    "#filter" => [...]
  }
}

# Less clear
%{
  "filtered_data" => %{
    "#filter" => [...]
  }
}
```

### 2. Break Down Complex Transformations

```elixir
# For very complex transformations, use multiple intermediate steps
%{
  "step1_filtered" => %{"#filter" => [...]},
  "step2_transformed" => %{"#map" => ["{{step1_filtered}}", ...]},
  "step3_final" => %{"#merge" => ["{{step2_transformed}}", ...]}
}
```

### 3. Validate Input Data

```elixir
# Check if required fields exist before transforming
context = %{
  "$items" => items_list || [],
  "$required_field" => Map.get(data, "field", nil)
}
```

### 4. Use Comments

```elixir
# Stage 1: Filter valid items
%{"#filter" => [...]}

# Stage 2: Transform to output format
%{"#map" => [...]}
```

---

## See Also

- [Map Rendering Guide](../guides/map-rendering.md) - Directive system guide
- [Map Directives Reference](../reference/map-directives.md) - Complete directive documentation
- [Report Generation](report-generation.md) - Examples using templates
- [Filters Guide](../guides/filters.md) - Using filters in templates
