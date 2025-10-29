# Security Best Practices

Ensure secure usage of Mau templates in your applications.

## Overview

This guide covers security considerations when using Mau templates, including input validation, output encoding, and protection against common vulnerabilities.

## Input Validation

### Validate Template Source

Only use trusted template sources:

```elixir
# ❌ DANGEROUS: User-provided templates
defmodule MyApp.Unsafe do
  def render_user_template(user_input) do
    # NEVER do this with untrusted input
    Mau.render(user_input, context)
  end
end

# ✅ SAFE: Pre-compiled templates only
defmodule MyApp.Safe do
  @templates %{
    "welcome" => load_template("welcome.html"),
    "invoice" => load_template("invoice.html")
  }

  def render_template(template_name, context) do
    case @templates[template_name] do
      ast when is_tuple(ast) -> Mau.render(ast, context)
      nil -> {:error, "Template not found"}
    end
  end

  defp load_template(filename) do
    path = Path.join(["templates", filename])
    content = File.read!(path)
    {:ok, ast} = Mau.compile(content)
    ast
  end
end
```

### Whitelist Templates

Maintain an explicit allowlist:

```elixir
defmodule MyApp.TemplateRegistry do
  @allowed_templates [
    "user_profile",
    "order_confirmation",
    "invoice",
    "report_summary"
  ]

  def get_template(name) do
    if Enum.member?(@allowed_templates, name) do
      load_from_file(name)
    else
      {:error, "Template not allowed"}
    end
  end

  defp load_from_file(name) do
    path = Path.join(["priv", "templates", "#{name}.html"])
    File.read!(path)
  end
end
```

---

## Context Security

### Prevent Information Disclosure

Don't expose sensitive data in context:

```elixir
# ❌ Dangerous: Exposes sensitive data
def render_user_page(user) do
  context = %{
    "user" => user  # Includes password_hash, api_keys, etc.
  }
  Mau.render(template, context)
end

# ✅ Safe: Only expose necessary data
def render_user_page(user) do
  context = %{
    "user" => %{
      "id" => user.id,
      "name" => user.name,
      "email" => user.email
    }
  }
  Mau.render(template, context)
end
```

### Sanitize User Input

Clean user-provided data before using in templates:

```elixir
defmodule MyApp.ContextSanitizer do
  def sanitize_context(raw_context) do
    raw_context
    |> Enum.map(fn {key, value} ->
      {key, sanitize_value(value)}
    end)
    |> Map.new()
  end

  defp sanitize_value(value) when is_binary(value) do
    value
    |> String.trim()
    |> truncate_length(1000)  # Prevent DoS
    |> escape_html()
  end

  defp sanitize_value(value) when is_list(value) do
    Enum.map(value, &sanitize_value/1)
  end

  defp sanitize_value(value) when is_map(value) do
    Enum.map(value, fn {k, v} -> {k, sanitize_value(v)} end)
    |> Map.new()
  end

  defp sanitize_value(value), do: value

  defp truncate_length(string, max_length) do
    if String.length(string) > max_length do
      String.slice(string, 0, max_length)
    else
      string
    end
  end

  defp escape_html(string) do
    string
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#x27;")
  end
end

# Usage
context = MyApp.ContextSanitizer.sanitize_context(user_input)
{:ok, output} = Mau.render(template, context)
```

---

## Output Encoding

### HTML Escaping

Always escape HTML content:

```elixir
# ❌ Dangerous: XSS vulnerability
template = """
<p>{{ user_comment }}</p>
"""
context = %{"user_comment" => "<script>alert('XSS')</script>"}
{:ok, output} = Mau.render(template, context)
# Output: <p><script>alert('XSS')</script></p> ← Script executes!

# ✅ Safe: Use escaping filter
template = """
<p>{{ user_comment | escape_html }}</p>
"""
context = %{"user_comment" => "<script>alert('XSS')</script>"}
{:ok, output} = Mau.render(template, context)
# Output: <p>&lt;script&gt;alert(&#x27;XSS&#x27;)&lt;/script&gt;</p> ← Safe
```

### Context-Specific Encoding

Use appropriate encoding for context:

```elixir
defmodule MyApp.OutputEncoders do
  # HTML context
  def html_escape(value) when is_binary(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#x27;")
  end

  # JavaScript context
  def js_escape(value) when is_binary(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace("'", "\\'")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
  end

  # URL context
  def url_encode(value) when is_binary(value) do
    URI.encode(value)
  end

  # CSV context
  def csv_escape(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n"]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end
end
```

---

## Prevent Injection Attacks

### Template Injection

Prevent injection of template syntax:

```elixir
defmodule MyApp.InjectionPrevention do
  # ❌ Dangerous: User input as template
  def render_unsafe(user_template) do
    Mau.render(user_template, %{})  # ← Template injection risk
  end

  # ✅ Safe: User input as context only
  def render_safe(template, user_input) do
    context = %{"user_input" => user_input}  # ← User data only
    Mau.render(template, context)
  end

  # ✅ Safer: Validate user input
  def render_validated(template, user_input) do
    if is_safe_context_value?(user_input) do
      context = %{"user_input" => user_input}
      Mau.render(template, context)
    else
      {:error, "Invalid input"}
    end
  end

  defp is_safe_context_value?(value) when is_binary(value) do
    !String.contains?(value, ["{{", "{%", "{#"])
  end

  defp is_safe_context_value?(value) when is_list(value) do
    Enum.all?(value, &is_safe_context_value?/1)
  end

  defp is_safe_context_value?(value) when is_map(value) do
    Enum.all?(value, fn {_k, v} -> is_safe_context_value?(v) end)
  end

  defp is_safe_context_value?(_), do: true
end
```

### Filter Injection

Restrict available filters:

```elixir
defmodule MyApp.FilterRestriction do
  @allowed_filters [
    "upper_case",
    "lower_case",
    "truncate",
    "join",
    "split",
    "strip"
  ]

  # ✅ Only allow specific filters
  def validate_template(template) do
    template
    |> extract_filters()
    |> Enum.all?(&Enum.member?(@allowed_filters, &1))
  end

  defp extract_filters(template) do
    Regex.scan(~r/\|\s*(\w+)/, template)
    |> Enum.map(fn [_full, filter_name] -> filter_name end)
  end
end
```

---

## Rate Limiting

### Prevent DoS Attacks

Limit template rendering:

```elixir
defmodule MyApp.RateLimiter do
  @max_template_size 100_000  # 100 KB
  @max_loop_iterations 10_000
  @max_renders_per_minute 1000

  def render_limited(template, context) do
    case validate_limits(template) do
      :ok ->
        Mau.render(
          template,
          context,
          max_template_size: @max_template_size,
          max_loop_iterations: @max_loop_iterations
        )

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_limits(template) when is_binary(template) do
    cond do
      byte_size(template) > @max_template_size ->
        {:error, "Template exceeds maximum size"}

      true ->
        :ok
    end
  end

  # Track renders per user
  def track_render(user_id) do
    key = "renders:#{user_id}:#{current_minute()}"
    count = increment_counter(key)

    if count > @max_renders_per_minute do
      {:error, "Rate limit exceeded"}
    else
      :ok
    end
  end

  defp current_minute do
    System.os_time(:second) |> div(60)
  end

  defp increment_counter(key) do
    # Use Redis or ETS for production
    :ets.update_counter(:rate_limits, key, 1)
  end
end
```

---

## Secure Defaults

### Configuration

```elixir
# config/config.exs
config :mau,
  # Disable runtime templates
  enable_runtime_filters: false,

  # Limit template size
  max_template_size: 100_000,

  # Reasonable iteration limit
  max_loop_iterations: 10_000,

  # Only use built-in filters
  filters: [
    Mau.Filters.String,
    Mau.Filters.Collection,
    Mau.Filters.Math
  ]
```

### Safe Defaults in Application Code

```elixir
defmodule MyApp.SecureTemplates do
  @secure_defaults [
    preserve_types: false,
    max_template_size: 100_000,
    max_loop_iterations: 10_000
  ]

  def render(template, context) do
    Mau.render(template, context, @secure_defaults)
  end

  def render_map(input, context) do
    Mau.render_map(input, context, @secure_defaults)
  end
end
```

---

## Security Checklist

### Pre-Deployment

- [ ] All templates from trusted sources only
- [ ] User input validated before template use
- [ ] Sensitive data removed from context
- [ ] HTML output properly escaped
- [ ] Custom filters reviewed for vulnerabilities
- [ ] Rate limiting configured
- [ ] Template size limits set
- [ ] Loop iteration limits configured

### Runtime

- [ ] Error messages don't expose implementation details
- [ ] Logging doesn't include sensitive data
- [ ] Templates cached securely
- [ ] Access control validates template requests
- [ ] Monitoring alerts on suspicious activity

### Testing

- [ ] XSS prevention tested
- [ ] Injection attacks tested
- [ ] DoS scenarios tested
- [ ] Error handling tested
- [ ] Input validation tested

---

## Common Vulnerabilities

### Cross-Site Scripting (XSS)

```elixir
# ❌ Vulnerable
<div>{{ user_comment }}</div>

# ✅ Safe
<div>{{ user_comment | escape_html }}</div>
```

### Template Injection

```elixir
# ❌ Vulnerable
Mau.render(user_provided_template, context)

# ✅ Safe
Mau.render(pre_compiled_template, sanitized_context)
```

### Information Disclosure

```elixir
# ❌ Vulnerable: Error shows implementation details
catch_all_error = fn error ->
  "Error: #{error}"  # Exposes internal details
end

# ✅ Safe: Generic error messages
safe_error = fn _error ->
  "An error occurred. Please try again."
end
```

### Denial of Service

```elixir
# ❌ Vulnerable: No limits
Mau.render(user_template, huge_context)

# ✅ Safe: Limits configured
Mau.render(
  user_template,
  huge_context,
  max_template_size: 100_000,
  max_loop_iterations: 10_000
)
```

---

## Security Testing

### XSS Testing

```elixir
defmodule MyApp.SecurityTests do
  use ExUnit.Case

  test "escapes HTML special characters" do
    template = "<div>{{ content }}</div>"
    context = %{"content" => "<script>alert('XSS')</script>"}

    {:ok, output} = Mau.render(template, context)

    refute String.contains?(output, "<script>")
    assert String.contains?(output, "&lt;")
  end

  test "prevents template injection" do
    template = "{{ user_input }}"
    context = %{"user_input" => "{{ malicious }}"}

    {:ok, output} = Mau.render(template, context)

    # Should render as literal text, not as template
    assert output == "{{ malicious }}"
  end

  test "respects size limits" do
    large_template = String.duplicate("{{ var }}", 20_000)

    assert {:error, _} =
             Mau.render(large_template, %{}, max_template_size: 100_000)
  end
end
```

---

## Resources

- [OWASP Template Injection](https://owasp.org/www-community/Server-Side_Template_Injection)
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [OWASP Injection](https://owasp.org/www-community/attacks/injection-attacks)

---

## See Also

- [Error Handling](error-handling.md) - Error handling security
- [Custom Filters](custom-filters.md) - Securing custom filters
- [Performance Tuning](performance-tuning.md) - DoS prevention
- [API Reference](../reference/api-reference.md) - API security considerations
