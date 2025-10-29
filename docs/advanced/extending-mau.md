# Extending Mau

Learn how to extend Mau's architecture and add custom functionality.

## Overview

Mau is designed to be extensible. This guide covers the architecture and how to extend the template engine with custom features.

## Architecture Overview

Mau follows a pipeline architecture:

```
Template String
      ↓
   [Parser]
      ↓
   AST Nodes
      ↓
[Whitespace Processor]
      ↓
[Block Processor]
      ↓
   Renderer
      ↓
Output (String or typed)
```

### Core Modules

**Mau.Parser**
- Converts template string to AST
- Handles all template syntax
- Returns AST nodes

**Mau.WhitespaceProcessor**
- Processes whitespace control modifiers (-, ->, --)
- Trims whitespace around expressions and tags

**Mau.BlockProcessor**
- Processes block-level structures
- Handles if/elsif/else and for loops
- Nests expressions within control structures

**Mau.Renderer**
- Evaluates expressions
- Renders tags
- Applies filters
- Manages context and variables

**Mau.MapDirectives**
- Handles special directives for map transformation
- Supports #map, #filter, #merge, #if, #pick, #pipe

---

## Custom Filters (Easiest Extension)

The simplest way to extend Mau - create domain-specific filters:

```elixir
defmodule MyApp.Filters do
  def spec do
    %{
      category: :app,
      description: "Application-specific filters",
      filters: %{
        "format_currency" => %{
          description: "Format as currency",
          function: {__MODULE__, :format_currency}
        }
      }
    }
  end

  def format_currency(amount, _args) when is_number(amount) do
    {:ok, "$#{Float.round(amount, 2)}"}
  end

  def format_currency(_value, _args) do
    {:error, "format_currency requires a number"}
  end
end

# Register in config/config.exs
config :mau, filters: [MyApp.Filters]
```

See [Custom Filters Guide](custom-filters.md) for detailed examples.

---

## Custom Directives

Extend map rendering with custom directives:

```elixir
defmodule MyApp.CustomDirectives do
  def match_directive(%{"#custom_transform" => args}) when is_list(args) do
    if length(args) == 2 do
      {:custom_transform, args}
    else
      :none
    end
  end

  def match_directive(_), do: :none

  def apply_directive({:custom_transform, [source_template, transform_args]}, context, opts, render_fn) do
    # 1. Render the source
    source = render_fn.(source_template, context, opts)

    # 2. Apply transformation
    transform_directive = %{
      "transformed" => transform_args
    }

    # 3. Return transformed result
    render_fn.(transform_directive, context ++ [source: source], opts)
  end
end
```

Integrate into `Mau.MapDirectives.match_directive/1`:

```elixir
def match_directive(map) do
  case map do
    %{"#map" => args} when is_list(args) and length(args) == 2 -> {:map, args}
    %{"#filter" => args} when is_list(args) and length(args) == 2 -> {:filter, args}
    # ... existing directives ...
    _ -> MyApp.CustomDirectives.match_directive(map)
  end
end
```

---

## Custom Tag Types

Add new control flow tags:

```elixir
defmodule MyApp.CustomTags do
  # Pattern for custom tags
  def render_tag(:custom_repeat, [times, content], _opts, context) do
    times_val = case times do
      {:literal, [n], _} when is_integer(n) -> n
      _ -> 1
    end

    # Render content N times
    output = Enum.map(1..times_val, fn _i ->
      case Mau.Renderer.render(content, context) do
        {:ok, result} -> result
        {:error, _} -> ""
      end
    end)

    {:ok, Enum.join(output)}
  end

  def render_tag(tag_name, _params, _opts, _context) do
    {:error, "Unknown tag: #{tag_name}"}
  end
end
```

---

## Middleware/Hooks

Add processing hooks at different stages:

```elixir
defmodule MyApp.TemplateHooks do
  # Pre-compilation hook
  def pre_compile(template_string) do
    # Apply transformations before compilation
    template_string
    |> replace_custom_syntax()
    |> normalize_whitespace()
  end

  # Post-compilation hook
  def post_compile(ast) do
    # Validate or optimize AST
    validate_ast(ast)
    optimize_ast(ast)
  end

  # Pre-render hook
  def pre_render(context) do
    # Enrich context
    context
    |> add_globals()
    |> sanitize_values()
  end

  # Post-render hook
  def post_render(output) do
    # Process output
    output
    |> String.trim()
    |> remove_debug_markers()
  end

  defp replace_custom_syntax(template) do
    # Replace custom syntax with standard syntax
    template
  end

  defp normalize_whitespace(template) do
    # Normalize whitespace
    template
  end

  defp validate_ast(ast) do
    # Validate AST structure
    ast
  end

  defp optimize_ast(ast) do
    # Optimize AST for faster rendering
    ast
  end

  defp add_globals(context) do
    Map.merge(context, %{
      "now" => DateTime.utc_now(),
      "version" => Application.spec(:my_app)[:vsn]
    })
  end

  defp sanitize_values(context) do
    # Clean values
    context
  end

  defp remove_debug_markers(output) do
    # Remove markers
    output
  end
end
```

Usage:

```elixir
defmodule MyApp.SecureRenderer do
  def render(template, context) do
    template = MyApp.TemplateHooks.pre_compile(template)
    {:ok, ast} = Mau.compile(template)
    ast = MyApp.TemplateHooks.post_compile(ast)

    context = MyApp.TemplateHooks.pre_render(context)
    {:ok, output} = Mau.render(ast, context)
    output = MyApp.TemplateHooks.post_render(output)

    {:ok, output}
  end
end
```

---

## Custom Expression Evaluators

Create custom expression types:

```elixir
defmodule MyApp.CustomExpressions do
  # Extend expression evaluation
  def evaluate_expression({:custom_expr, [type | args], _opts}, context) do
    case type do
      :range -> evaluate_range(args, context)
      :set -> evaluate_set(args, context)
      :regex -> evaluate_regex(args, context)
      _ -> {:error, "Unknown custom expression type: #{type}"}
    end
  end

  defp evaluate_range([start, finish], context) do
    {:ok, start..finish}
  end

  defp evaluate_set(args, context) do
    {:ok, MapSet.new(args)}
  end

  defp evaluate_regex([pattern], _context) do
    {:ok, Regex.compile!(pattern)}
  end
end
```

---

## Custom Renderer

Create a specialized renderer for specific use cases:

```elixir
defmodule MyApp.XMLRenderer do
  @moduledoc """
  Render templates as XML with special handling.
  """

  def render(template, context) do
    case Mau.compile(template) do
      {:ok, ast} ->
        render_xml_nodes(ast, context)

      error ->
        error
    end
  end

  defp render_xml_nodes(nodes, context) when is_list(nodes) do
    case Enum.reduce_while(nodes, [], fn node, acc ->
      case render_xml_node(node, context) do
        {:ok, result} -> {:cont, [result | acc]}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end) do
      {:error, _} = error -> error
      results -> {:ok, Enum.reverse(results) |> Enum.join()}
    end
  end

  defp render_xml_node({:text, [content], _opts}, _context) do
    {:ok, String.trim(content)}
  end

  defp render_xml_node({:expression, expr, _opts}, context) do
    case Mau.Renderer.evaluate_expression(expr, context) do
      {:ok, value} ->
        # XML escape output
        {:ok, xml_escape(to_string(value))}

      error ->
        error
    end
  end

  defp xml_escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
```

---

## Parser Extensions

Extend the parser for custom syntax:

```elixir
defmodule MyApp.ExtendedParser do
  @moduledoc """
  Parser with custom syntax support.
  """

  def parse(template) do
    # Transform template before standard parsing
    transformed = transform_custom_syntax(template)
    Mau.Parser.parse(transformed)
  end

  defp transform_custom_syntax(template) do
    template
    # Convert custom @include syntax to standard tags
    |> String.replace(~r/@include\s+"([^"]+)"/, "{# include: \\1 #}")
    # Convert custom #tag syntax
    |> String.replace(~r/#each\s+(\w+)/, "{% for item in \\1 %}")
  end
end
```

---

## Filter Registry Extensions

Add runtime filter loading:

```elixir
defmodule MyApp.DynamicFilters do
  def load_filters_from_directory(path) do
    path
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".ex"))
    |> Enum.map(&load_filter_module(&1, path))
  end

  defp load_filter_module(filename, path) do
    full_path = Path.join(path, filename)
    content = File.read!(full_path)

    case Code.compile_string(content) do
      {module, _bytecode} -> {:ok, module}
      :error -> {:error, "Failed to compile #{filename}"}
    end
  end

  def register_filters(modules) do
    existing = Application.get_env(:mau, :filters, [])
    new_filters = existing ++ modules
    Application.put_env(:mau, :filters, new_filters)
  end
end
```

---

## Context Providers

Create pluggable context providers:

```elixir
defmodule MyApp.ContextProvider do
  @type context_provider :: (any() -> map())

  @providers [
    &user_context/1,
    &config_context/1,
    &locale_context/1
  ]

  def build_context(request) do
    @providers
    |> Enum.reduce(%{}, fn provider, acc ->
      Map.merge(acc, provider.(request))
    end)
  end

  defp user_context(request) do
    if user = request.user do
      %{
        "user" => %{
          "id" => user.id,
          "name" => user.name,
          "role" => user.role
        }
      }
    else
      %{}
    end
  end

  defp config_context(_request) do
    %{
      "config" => %{
        "app_name" => Application.get_env(:my_app, :app_name),
        "version" => Application.spec(:my_app)[:vsn]
      }
    }
  end

  defp locale_context(request) do
    %{
      "locale" => request.locale || "en",
      "timezone" => request.timezone || "UTC"
    }
  end
end

# Usage
context = MyApp.ContextProvider.build_context(request)
{:ok, output} = Mau.render(template, context)
```

---

## Testing Extensions

Test custom extensions:

```elixir
defmodule MyApp.ExtensionsTest do
  use ExUnit.Case

  test "custom filter works" do
    assert {:ok, "$1,234.56"} =
             Mau.FilterRegistry.apply("format_currency", 1234.56, [])
  end

  test "custom directive transforms data" do
    input = %{
      "result" => %{
        "#custom_transform" => ["{{$value}}", [1, 2, 3]]
      }
    }

    context = %{"$value" => 42}

    assert {:ok, result} = Mau.render_map(input, context)
    assert result["result"]
  end

  test "custom renderer produces XML" do
    template = "<item>{{ value }}</item>"
    context = %{"value" => "test"}

    assert {:ok, output} = MyApp.XMLRenderer.render(template, context)
    assert String.contains?(output, "<item>")
  end

  test "context provider merges sources" do
    request = %{
      user: %{id: 1, name: "Alice", role: "admin"},
      locale: "fr",
      timezone: "Europe/Paris"
    }

    context = MyApp.ContextProvider.build_context(request)

    assert context["user"]["name"] == "Alice"
    assert context["locale"] == "fr"
    assert context["config"]["app_name"]
  end
end
```

---

## Best Practices for Extensions

### 1. Follow Mau Conventions

- Use the same error handling pattern: `{:ok, result}` or `{:error, reason}`
- Document filters with spec function
- Use consistent naming

### 2. Maintain Compatibility

- Don't break existing APIs
- Version your extensions
- Provide migration paths

### 3. Performance

- Cache where possible
- Avoid expensive operations in hot paths
- Profile your extensions

### 4. Testing

- Write comprehensive tests
- Test edge cases
- Test error handling

### 5. Documentation

- Document custom syntax
- Provide examples
- Include troubleshooting

---

## Common Extension Patterns

### Logging/Tracing

```elixir
defmodule MyApp.TracingRenderer do
  def render(template, context, trace_fn) do
    trace_fn.({:render_start, %{template_length: byte_size(template)}})

    case Mau.render(template, context) do
      {:ok, output} ->
        trace_fn.({:render_complete, %{output_length: byte_size(output)}})
        {:ok, output}

      {:error, error} ->
        trace_fn.({:render_error, %{error: error}})
        {:error, error}
    end
  end
end
```

### Metrics Collection

```elixir
defmodule MyApp.MetricsRenderer do
  def render(template, context) do
    {time_us, result} = :timer.tc(Mau, :render, [template, context])

    :telemetry.execute([:mau, :render], %{duration_us: time_us})

    result
  end
end
```

---

## See Also

- [Custom Filters](custom-filters.md) - Creating custom filters
- [Custom Functions](custom-functions.md) - Creating custom functions
- [Performance Tuning](performance-tuning.md) - Optimization
- [Security](security.md) - Security considerations
- [API Reference](../reference/api-reference.md) - API documentation
