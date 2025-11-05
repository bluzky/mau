# Performance Tuning

Optimize Mau template compilation and rendering for maximum performance.

## Overview

This guide covers performance optimization techniques for Mau templates, from compilation to rendering and filter usage.

## Template Compilation

### Compile Once, Render Many

The most important optimization: compile templates once and reuse the AST.

```elixir
# ❌ Bad: Compiles on every render (expensive)
defmodule MyApp.BadExample do
  def render_user(user_data) do
    template = "User: {{ name }}, Email: {{ email }}"
    {:ok, output} = Mau.render(template, user_data)
    output
  end
end

# ✅ Good: Compile once at startup
defmodule MyApp.GoodExample do
  @user_template """
  User: {{ name }}, Email: {{ email }}
  """

  @compiled_template elem(Mau.compile(@user_template), 1)

  def render_user(user_data) do
    {:ok, output} = Mau.render(@compiled_template, user_data)
    output
  end
end
```

### Pre-compile in Application Init

For applications with many templates, pre-compile during startup:

```elixir
defmodule MyApp.Templates do
  @moduledoc """
  Pre-compiled templates for the application.
  """

  # Compile all templates at startup
  def init_templates do
    %{
      user_card: compile_template("user_card.html"),
      email_welcome: compile_template("email_welcome.html"),
      report_summary: compile_template("report_summary.txt")
    }
  end

  defp compile_template(filename) do
    content = File.read!(Path.join(["templates", filename]))
    {:ok, ast} = Mau.compile(content)
    ast
  end
end

# Usage in application startup
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    # Pre-compile all templates
    templates = MyApp.Templates.init_templates()
    Application.put_env(:my_app, :compiled_templates, templates)

    # ... rest of startup
  end
end
```

### Cache Compiled Templates

Store compiled templates in ETS for fast access:

```elixir
defmodule MyApp.TemplateCache do
  @cache_table :template_cache

  def init do
    :ets.new(@cache_table, [:named_table, :public, :set])
  end

  def get_or_compile(name, template_string) do
    case :ets.lookup(@cache_table, name) do
      [{^name, ast}] ->
        {:ok, ast}

      [] ->
        case Mau.compile(template_string) do
          {:ok, ast} ->
            :ets.insert(@cache_table, {name, ast})
            {:ok, ast}

          error ->
            error
        end
    end
  end

  def clear do
    :ets.delete_all_objects(@cache_table)
  end
end
```

---

## Rendering Optimization

### Use Type Preservation Wisely

Type preservation adds overhead - use only when needed:

```elixir
# ❌ Unnecessary type preservation
{:ok, output} = Mau.render("Count: {{ items | length }}", context, preserve_types: true)
# Result: "Count: 3" (string anyway)

# ✅ Smart type preservation
{:ok, result} = Mau.render("{{ total }}", context, preserve_types: true)
# Result: 1500 (number, no string conversion)
```

### Set Appropriate Loop Limits

Prevent runaway loops with realistic limits:

```elixir
# Dangerous: User could create infinite-like loops
{:ok, output} = Mau.render(user_template, context)

# Safe: Limit iterations
{:ok, output} = Mau.render(
  user_template,
  context,
  max_loop_iterations: 5000  # Reasonable limit for most cases
)
```

### Batch Rendering

For multiple templates with same context, batch them:

```elixir
# ❌ Inefficient: Processes context separately
results =
  Enum.map(templates, fn template ->
    {:ok, output} = Mau.render(template, context)
    output
  end)

# ✅ Efficient: Prepare context once
prepared_context = prepare_context(raw_context)

results =
  Enum.map(templates, fn template ->
    {:ok, output} = Mau.render(template, prepared_context)
    output
  end)

defp prepare_context(raw_context) do
  %{
    "name" => String.downcase(raw_context.name),
    "items" => Enum.sort(raw_context.items),
    "totals" => calculate_totals(raw_context)
  }
end
```

---

## Filter Performance

### Use Built-in Filters

Built-in filters are optimized in Elixir:

```elixir
# ❌ Manual looping (slower)
def custom_filter(items, _args) do
  result = []
  for item <- items do
    result = [item | result]
  end
  {:ok, Enum.reverse(result)}
end

# ✅ Use Enum (optimized)
def custom_filter(items, _args) do
  {:ok, Enum.reverse(items)}
end
```

### Chain Filters Efficiently

Order filters for best performance:

```elixir
# ❌ Processes large list multiple times
{{ items | sort | reverse | first }}

# ✅ Filter before sort (smaller dataset)
{{ items | filter("status", "active") | sort | reverse | first }}
```

### Avoid N+1 Filter Problems

```elixir
# ❌ Creates 1 lookup per item (N+1)
{% for item in items %}
  {{ item | lookup_price(prices) }}
{% endfor %}

# ✅ Preprocess lookups before template
{:ok, enriched_items} = Mau.render_map(%{
  "#map" => ["{{$items}}", %{
    "id" => "{{$loop.item.id}}",
    "price" => "{{$self.prices[$loop.item.id]}}"
  }]
}, %{
  "$items" => items,
  "$self" => %{"prices" => prices_map}
})
```

---

## Context Optimization

### Keep Context Minimal

Only include data that templates need:

```elixir
# ❌ Large context with unused data
context = %{
  "user" => all_user_data,           # 50+ fields
  "items" => all_items,              # 10,000+ items
  "settings" => all_settings         # 100+ fields
}

# ✅ Minimal context with only needed data
context = %{
  "user" => %{
    "name" => user.name,
    "email" => user.email
  },
  "items" => Enum.filter(all_items, &(&1.visible)),
  "settings" => %{
    "theme" => settings.theme
  }
}
```

### Preprocess Complex Data

Transform data before passing to templates:

```elixir
# ❌ Let template do all the work
context = %{
  "orders" => raw_orders
}
# Template processes all orders

# ✅ Preprocess in application code
context = %{
  "orders" => Enum.map(raw_orders, fn order ->
    %{
      "id" => order.id,
      "total" => order.total,
      "formatted_total" => format_currency(order.total),
      "status" => status_label(order.status)
    }
  end)
}
# Template just displays preprocessed data
```

### Use Lazy Evaluation

For large datasets, compute only when needed:

```elixir
# ❌ Evaluates all summaries upfront
context = %{
  "monthly_summaries" => Enum.map(1..12, &calculate_month_summary/1)
}

# ✅ Compute summaries in template only if used
context = %{
  "months" => 1..12,
  "calculate_summary" => &calculate_month_summary/1
}
```

---

## Map Directives Optimization

### Use #filter Before #map

Filter collections before transforming:

```elixir
# ❌ Maps everything then filters
input = %{
  "results" => %{
    "#map" => [
      "{{$items}}",
      %{"id" => "{{$loop.item.id}}"}
    ]
  },
  "active_only" => %{
    "#filter" => ["{{results}}", "{{$loop.item.status == 'active'}}"]
  }
}

# ✅ Filters first, then maps
input = %{
  "active_results" => %{
    "#pipe" => [
      "{{$items}}",
      [
        %{"#filter" => "{{$loop.item.status == 'active'}}"},
        %{"#map" => %{"id" => "{{$loop.item.id}}"}}
      ]
    ]
  }
}
```

### Avoid Nested #map with Complex Logic

```elixir
# ❌ Complex nested logic
%{
  "#map" => [
    "{{$data}}",
    %{
      "items" => %{
        "#map" => [
          "{{$loop.item.children}}",
          %{
            "status" => %{
              "#if" => ["{{$loop.item.status}}", ...]
            }
          }
        ]
      }
    }
  ]
}

# ✅ Preprocess in application
preprocessed = Enum.map(data, fn item ->
  %{
    "items" => Enum.map(item.children, fn child ->
      %{"status" => compute_status(child)}
    end)
  }
end)

{:ok, result} = Mau.render_map(%{
  "items" => "{{$items}}"
}, %{"$items" => preprocessed})
```

---

## Benchmarking

### Measure Performance

Use `:timer.tc` for benchmarking:

```elixir
defmodule MyApp.Benchmarks do
  def benchmark_template do
    template = "Hello {{ name }}, you have {{ count }} items"
    context = %{"name" => "Alice", "count" => 42}

    # Warm up
    Mau.render(template, context)

    # Measure
    {time_us, {:ok, _output}} = :timer.tc(Mau, :render, [template, context])
    time_ms = time_us / 1000

    IO.puts("Rendered in #{time_ms} ms")
  end

  def benchmark_filter do
    {time_us, result} = :timer.tc(fn ->
      Mau.FilterRegistry.apply("upper_case", "hello world", [])
    end)

    IO.puts("Filter took #{time_us / 1000} ms")
  end
end
```

### Use Benchee for Comprehensive Testing

```elixir
defmodule MyApp.BenchmarksWithBenchee do
  def run do
    Benchee.run(%{
      "simple_render" => fn ->
        {:ok, _} = Mau.render("{{ name }}", %{"name" => "Alice"})
      end,
      "complex_render" => fn ->
        {:ok, _} = Mau.render(complex_template(), complex_context())
      end,
      "precompiled_render" => fn ->
        {:ok, _} = Mau.render(precompiled_ast(), complex_context())
      end
    },
      time: 10,
      memory_time: 2
    )
  end
end
```

---

## Common Performance Issues

### Issue: Slow Template Rendering

**Symptoms**: Templates take seconds to render

**Causes**:
- Large datasets
- N+1 lookups in filters
- Unoptimized filters

**Solutions**:
```elixir
# 1. Profile with :fprof
:fprof.start()
Mau.render(template, context)
:fprof.stop()

# 2. Use simpler templates for large datasets
# 3. Preprocess data in application

# 4. Add loop limits
Mau.render(template, context, max_loop_iterations: 5000)
```

### Issue: Memory Usage Growing

**Symptoms**: Application memory keeps increasing

**Causes**:
- Compiled templates not cached properly
- Unbounded context growth
- Large template strings

**Solutions**:
```elixir
# 1. Use template cache
MyApp.TemplateCache.get_or_compile("my_template", template_source)

# 2. Clear old compiled templates periodically
:ets.delete_all_objects(:template_cache)

# 3. Use streaming for large contexts
Enum.each(large_dataset, fn item ->
  context = %{"item" => item}
  {:ok, output} = Mau.render(template, context)
  IO.write(output)
end)
```

### Issue: Slow Filter Chains

**Symptoms**: Chained filters slow down template rendering

**Causes**:
- Multiple passes over data
- Inefficient filter order

**Solutions**:
```elixir
# ❌ Slow: Multiple passes
{{ items | sort | reverse | map("name") | join(", ") }}

# ✅ Fast: Preprocess
preprocessed = items
  |> Enum.sort()
  |> Enum.reverse()
  |> Enum.map(&(&1["name"]))
  |> Enum.join(", ")

{{ preprocessed }}
```

---

## Caching Strategies

### Fragment Caching

Cache rendered fragments:

```elixir
defmodule MyApp.FragmentCache do
  @cache_table :fragment_cache

  def init do
    :ets.new(@cache_table, [:named_table, :public, :set])
  end

  def render_cached(key, template, context, ttl_seconds \\ 3600) do
    case :ets.lookup(@cache_table, key) do
      [{^key, output, expiry}] ->
        if System.os_time(:second) < expiry do
          output
        else
          :ets.delete(@cache_table, key)
          render_and_cache(key, template, context, ttl_seconds)
        end

      [] ->
        render_and_cache(key, template, context, ttl_seconds)
    end
  end

  defp render_and_cache(key, template, context, ttl) do
    {:ok, output} = Mau.render(template, context)
    expiry = System.os_time(:second) + ttl
    :ets.insert(@cache_table, {key, output, expiry})
    output
  end
end
```

---

## Best Practices Summary

1. **Compile once, render many times**
2. **Cache compiled templates**
3. **Preprocess complex data**
4. **Use type preservation selectively**
5. **Set reasonable loop limits**
6. **Filter before transformation**
7. **Keep context minimal**
8. **Profile and benchmark**
9. **Batch operations**
10. **Monitor memory usage**

---

## See Also

- [Custom Filters](custom-filters.md) - Creating efficient custom filters
- [API Reference](../reference/api-reference.md) - Mau API options
- [Map Directives](../reference/map-directives.md) - Directive optimization
