# Error Handling

Strategies for handling errors in Mau templates and applications.

## Overview

This guide covers different approaches to error handling, from strict mode validation to graceful degradation and custom error handlers.

## Error Types

Mau can produce different types of errors:

```elixir
# Syntax errors (only returned in strict mode)
{:error, error} = Mau.compile("invalid {{ syntax", strict_mode: true)

# Runtime errors
{:error, error} = Mau.render("{{ 1 / 0 }}", %{})

# Filter errors
{:error, error} = Mau.render("{{ 'text' | abs }}", %{})
```

## Strict Mode

`strict_mode` turns invalid templates and undefined variables into errors. Invalid templates include invalid syntax, unclosed blocks and stray block tags such as `{% endif %}`.

```elixir
# Default: the original template string is returned as the output
{:ok, "{{ a + }}"} = Mau.render("{{ a + }}", %{})

# Strict: a syntax error is returned, with line and column for invalid syntax
{:error, %Mau.Error{type: :syntax}} = Mau.render("{{ a + }}", %{}, strict_mode: true)
{:error, %Mau.Error{type: :syntax}} = Mau.compile("{{ a + }}", strict_mode: true)
{:ok, ast, []} = Mau.compile("{{ a }}", strict_mode: true)
```

Errors while rendering a valid template, such as division by zero, return `{:error, error}` in both modes.

`render_map/3` handles failures per field by default, so a field that fails keeps its template string. With `strict_mode: true`, the whole call returns `{:error, error}`.

Undefined variables render as empty strings by default. In strict mode, using one returns an error of type `:undefined_variable`:

```elixir
{:error, %Mau.Error{message: "Undefined variable: user.nmae"}} =
  Mau.render("{{ user.nmae }}", %{"user" => %{}}, strict_mode: true)
```

A variable can still be missing in strict mode when it's checked explicitly:

```elixir
"{% if nickname %}...{% endif %}"     # Used directly as a condition
"{{ nickname or fallback }}"          # Direct operand of and, or, &&, || or not
"{{ nickname | default('Friend') }}"  # Direct input to default
```

This only applies to the variable itself, so `{% if nickname == 'x' %}` and `{{ nickname | upper_case | default('x') }}` are errors.

These aren't errors in strict mode:

- A variable or key that exists with the value `nil`
- A property of `nil`, such as `{{ user.profile.name }}` when `profile` is `nil`
- An index that's out of range, such as `{{ items[5] }}`

Map directives render their conditions as ordinary templates, so `"#if"`, `"#filter"` and `"#cond"` conditions need `default` when a variable can be missing: `"{{ item.active | default(false) }}"`.

## Undefined Variables

Handle undefined variable access:

```elixir
# Default behavior: undefined variables become empty strings
context = %{"name" => "Alice"}
{:ok, output} = Mau.render("Hello {{ name }}, meet {{ unknown }}", context)
# Output: "Hello Alice, meet "

# Strict checking: provide defaults
context = %{
  "name" => "Alice",
  "unknown" => nil  # Explicitly set to nil
}
{:ok, output} = Mau.render("Hello {{ name }}, meet {{ unknown | default('Friend') }}", context)
# Output: "Hello Alice, meet Friend"
```

## Filter Error Handling

Handle filter errors gracefully:

```elixir
# Type mismatch in filter
{:error, error} = Mau.render("{{ 'text' | abs }}", %{})
error.message
# "Filter error in abs: \"abs can only be applied to numbers\""

# Handle the error and show a fallback
context = %{"value" => "not_a_number"}

output =
  case Mau.render("{{ value | abs }}", context) do
    {:ok, output} -> output
    {:error, _error} -> "Invalid number"
  end
```

Errors are `%Mau.Error{}` structs with `type`, `message`, `line` and `column` fields. They can't be interpolated into a string directly, so use `error.message` or `Mau.Error.format(error)`.

## Application-Level Error Handling

### Basic Error Pattern

```elixir
defmodule MyApp.TemplateRenderer do
  def render(template_name, context) do
    case get_template(template_name) do
      {:ok, template_ast} ->
        render_template(template_ast, context)

      {:error, reason} ->
        {:error, "Template not found: #{reason}"}
    end
  end

  defp render_template(template_ast, context) do
    case Mau.render(template_ast, context) do
      {:ok, output} ->
        {:ok, output}

      {:error, error} ->
        {:error, "Rendering failed: #{Mau.Error.format(error)}"}
    end
  end

  defp get_template(name) do
    case Application.get_env(:my_app, :compiled_templates)[name] do
      ast when is_list(ast) -> {:ok, ast}
      _ -> {:error, "#{name} not found"}
    end
  end
end
```

### With Logging

```elixir
defmodule MyApp.TemplateRenderer do
  require Logger

  def render_safe(template, context) do
    case Mau.render(template, context) do
      {:ok, output} ->
        {:ok, output}

      {:error, error} ->
        Logger.error("Template rendering failed: #{Mau.Error.format(error)}")
        {:ok, render_fallback(template)}
    end
  end

  def render_fallback(template) do
    "An error occurred while rendering the template"
  end
end
```

---

## Error Recovery Strategies

### Graceful Degradation

Provide fallback content when rendering fails. Add `strict_mode: true` if invalid templates should use the fallback too, because by default they render as their own source:

```elixir
defmodule MyApp.SafeRenderer do
  def render_or_fallback(template, context, fallback \\ "") do
    case Mau.render(template, context) do
      {:ok, output} -> output
      {:error, _} -> fallback
    end
  end

  def render_with_default(template, context, default_value) do
    case Mau.render(template, context, preserve_types: true) do
      {:ok, value} -> value
      {:error, _} -> default_value
    end
  end
end

# Usage
output = MyApp.SafeRenderer.render_or_fallback(
  template,
  context,
  "Unable to render content"
)

price = MyApp.SafeRenderer.render_with_default(
  "{{ product.price }}",
  context,
  0.00
)
```

### Partial Failure Handling

Continue processing when some templates fail:

```elixir
defmodule MyApp.BatchRenderer do
  def render_all(templates, context) do
    Enum.map(templates, fn {name, template} ->
      case Mau.render(template, context) do
        {:ok, output} ->
          {:ok, name, output}

        {:error, error} ->
          {:error, name, error}
      end
    end)
  end

  def render_all_safe(templates, context) do
    # Only return successful renders
    templates
    |> render_all(context)
    |> Enum.filter(&match?({:ok, _, _}, &1))
    |> Enum.map(fn {:ok, name, output} -> {name, output} end)
  end
end

# Usage
results = MyApp.BatchRenderer.render_all(templates, context)

Enum.each(results, fn
  {:ok, name, output} -> IO.puts("#{name}: #{output}")
  {:error, name, error} -> IO.puts("#{name}: ERROR - #{Mau.Error.format(error)}")
end)
```

---

## Validation Before Rendering

### Context Validation

```elixir
defmodule MyApp.ContextValidator do
  def validate_context(context, required_keys) do
    missing = Enum.filter(required_keys, &(!Map.has_key?(context, &1)))

    if Enum.empty?(missing) do
      :ok
    else
      {:error, "Missing context keys: #{Enum.join(missing, ", ")}"}
    end
  end

  def safe_render(template, context, required_keys) do
    case validate_context(context, required_keys) do
      :ok ->
        Mau.render(template, context)

      {:error, reason} ->
        {:error, reason}
    end
  end
end

# Usage
required = ["user_name", "order_id", "total"]
case MyApp.ContextValidator.safe_render(template, context, required) do
  {:ok, output} -> send_email(output)
  {:error, error} -> log_error(error)
end
```

### Template Validation

Use strict mode here, because without it an invalid template compiles successfully to plain text.

```elixir
defmodule MyApp.TemplateValidator do
  def validate_template(template_string) do
    case Mau.compile(template_string, strict_mode: true) do
      {:ok, _ast, _warnings} ->
        :ok

      {:error, error} ->
        {:error, "Template compilation failed: #{Mau.Error.format(error)}"}
    end
  end

  def validate_and_store(name, template_string) do
    case validate_template(template_string) do
      :ok ->
        {:ok, ast} = Mau.compile(template_string)
        store_template(name, ast)
        {:ok, name}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp store_template(name, ast) do
    templates = Application.get_env(:my_app, :compiled_templates, %{})
    Application.put_env(:my_app, :compiled_templates, Map.put(templates, name, ast))
  end
end
```

---

## Error Logging and Monitoring

### Structured Logging

```elixir
defmodule MyApp.TemplateLogger do
  require Logger

  def log_render_error(template_name, context_keys, error) do
    Logger.error("Template rendering error",
      template_name: template_name,
      context_keys: context_keys,
      error: error,
      timestamp: DateTime.utc_now()
    )
  end

  def log_filter_error(filter_name, input_type, error) do
    Logger.error("Filter execution error",
      filter: filter_name,
      input_type: input_type,
      error: error
    )
  end
end

# Usage
case Mau.render(template, context) do
  {:ok, output} -> output
  {:error, error} ->
    MyApp.TemplateLogger.log_render_error(
      template_name,
      Map.keys(context),
      error
    )
    render_fallback()
end
```

### Error Metrics

Mau doesn't emit telemetry events itself, so call these helpers from your own error handling.

```elixir
defmodule MyApp.ErrorMetrics do
  def track_render_error(error_type, metadata \\ %{}) do
    :telemetry.execute(
      [:mau, :render, :error],
      %{count: 1},
      Map.merge(metadata, %{error_type: error_type})
    )
  end

  def track_filter_error(filter_name) do
    :telemetry.execute(
      [:mau, :filter, :error],
      %{count: 1},
      %{filter: filter_name}
    )
  end
end

# Attach handlers in application startup
:telemetry.attach_many(
  "mau_errors",
  [
    [:mau, :render, :error],
    [:mau, :filter, :error]
  ],
  &MyApp.ErrorMetrics.handle_event/4,
  []
)
```

---

## Custom Error Handlers

### Error Handler Pipeline

```elixir
defmodule MyApp.ErrorHandler do
  @type error_result :: {:ok, any} | {:error, Mau.Error.t()}

  def render_with_handlers(template, context, handlers \\ []) do
    case Mau.render(template, context, strict_mode: true) do
      {:ok, output} -> {:ok, output}
      {:error, error} -> handle_error(error, handlers)
    end
  end

  defp handle_error(error, handlers) do
    Enum.reduce_while(handlers, {:error, error}, fn handler, acc ->
      case handler.(acc) do
        {:ok, recovered} -> {:halt, {:ok, recovered}}
        :skip -> {:cont, acc}
        {:error, new_error} -> {:cont, {:error, new_error}}
      end
    end)
  end
end

# Usage with multiple recovery strategies
handlers = [
  fn {:error, error} ->
    if error.type == :syntax do
      {:ok, "Default content"}
    else
      :skip
    end
  end,
  fn {:error, _error} ->
    {:ok, "Fallback content"}
  end
]

MyApp.ErrorHandler.render_with_handlers(template, context, handlers)
```

### Custom Error Messages

```elixir
defmodule MyApp.UserFriendlyErrors do
  def render_safe(template, context) do
    case Mau.render(template, context, strict_mode: true) do
      {:ok, output} ->
        {:ok, output}

      {:error, error} ->
        user_message = translate_error(error)
        {:error, user_message}
    end
  end

  defp translate_error(%Mau.Error{type: :syntax}) do
    "The template is misconfigured. Please contact support."
  end

  defp translate_error(%Mau.Error{message: message}) do
    if String.contains?(message, "ilter") do
      "A formatting error occurred. Please contact support."
    else
      "An unexpected error occurred. Please try again."
    end
  end
end
```

---

## Testing Error Scenarios

### Unit Tests for Error Handling

```elixir
defmodule MyApp.ErrorHandlingTest do
  use ExUnit.Case

  test "handles undefined variables gracefully" do
    template = "Hello {{ name }}"
    context = %{}
    assert {:ok, "Hello "} = Mau.render(template, context)
  end

  test "handles filter type errors" do
    template = "{{ 'text' | abs }}"
    context = %{}
    assert {:error, _} = Mau.render(template, context)
  end

  test "returns template source for invalid syntax by default" do
    assert {:ok, "{{ a + }}"} = Mau.render("{{ a + }}", %{})
  end

  test "returns a syntax error in strict mode" do
    assert {:error, %Mau.Error{type: :syntax}} =
             Mau.render("{{ a + }}", %{}, strict_mode: true)
  end

  test "validates context before rendering" do
    template = "Hello {{ name }}"
    context = %{"name" => "Alice"}
    required = ["name", "email"]

    assert {:error, "Missing context keys: email"} =
             MyApp.ContextValidator.safe_render(template, context, required)
  end

  test "recovers from template rendering errors" do
    template = "{{ 1 / 0 }}"
    context = %{}

    assert "Fallback" = MyApp.SafeRenderer.render_or_fallback(template, context, "Fallback")
  end
end
```

### Property-Based Testing

```elixir
defmodule MyApp.ErrorHandlingProperties do
  use ExUnit.Case
  use PropCheck

  property "rendering with any context never crashes" do
    forall template <- string(:printable) do
      context = %{"key" => "value"}

      case Mau.render(template, context) do
        {:ok, _output} -> true
        {:error, _} -> true
      end
    end
  end

  property "filters always return valid results or errors" do
    forall {filter, args} <- filter_and_args() do
      case Mau.FilterRegistry.apply(filter, "test", args) do
        {:ok, _result} -> true
        {:error, _} -> true
      end
    end
  end
end
```

---

## Production Best Practices

### Error Rate Monitoring

```elixir
defmodule MyApp.ErrorMonitoring do
  def start_monitoring do
    :telemetry.attach(
      "mau_error_counter",
      [:mau, :render, :error],
      &count_error/4,
      %{errors: 0}
    )
  end

  def count_error(_event_name, measurements, metadata, config) do
    total = (config.errors || 0) + measurements.count
    if rem(total, 100) == 0 do
      Logger.warn("Reached #{total} template rendering errors")
    end
  end
end
```

### Alerting on Error Spikes

```elixir
defmodule MyApp.ErrorAlerting do
  def check_error_rate do
    recent_errors = get_recent_errors(last_n_minutes: 5)
    error_rate = length(recent_errors) / total_renders()

    if error_rate > 0.05 do  # More than 5% errors
      send_alert("High template error rate: #{error_rate * 100}%")
    end
  end

  defp send_alert(message) do
    Logger.error("ALERT: #{message}")
    # Send to monitoring/alerting service
  end
end
```

---

## See Also

- [Custom Filters](custom-filters.md) - Error handling in custom filters
- [Performance Tuning](performance-tuning.md) - Performance monitoring
- [Security](security.md) - Security-related error handling
- [API Reference](../reference/api-reference.md) - Error types and messages
