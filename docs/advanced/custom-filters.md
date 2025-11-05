# Creating Custom Filters

Learn how to extend Mau with custom filters for domain-specific functionality.

## Overview

Custom filters allow you to extend Mau with application-specific logic. Filters are functions that transform values and can be used in templates via the pipe syntax.

## Basic Filter Structure

All filters follow this pattern:

```elixir
defmodule MyApp.CustomFilters do
  @moduledoc """
  Custom filters for MyApp.
  """

  @doc """
  Returns the filter specification.
  """
  def spec do
    %{
      category: :custom,
      description: "Custom filters for MyApp",
      filters: %{
        "my_filter" => %{
          description: "Description of what the filter does",
          function: {__MODULE__, :my_filter}
        }
      }
    }
  end

  @doc """
  Filter implementation.
  """
  def my_filter(value, args) do
    {:ok, transformed_value}
  end
end
```

## Filter Signature

All filter functions must follow this signature:

```elixir
def filter_name(value, args) :: {:ok, result} | {:error, reason}
```

- **value**: The input value to transform
- **args**: List of filter arguments
- **Returns**: `{:ok, result}` on success or `{:error, reason}` on failure

## Simple Filter Example

Create a filter that formats currency values:

```elixir
defmodule MyApp.CurrencyFilters do
  @moduledoc """
  Filters for currency formatting.
  """

  def spec do
    %{
      category: :currency,
      description: "Currency formatting filters",
      filters: %{
        "currency" => %{
          description: "Formats number as currency",
          function: {__MODULE__, :currency}
        },
        "currency_short" => %{
          description: "Formats number as short currency (K, M, B)",
          function: {__MODULE__, :currency_short}
        }
      }
    }
  end

  @doc """
  Formats a number as USD currency.
  """
  def currency(value, _args) when is_number(value) do
    formatted = :erlang.float_to_binary(value, decimals: 2)
    {:ok, "$#{formatted}"}
  end

  def currency(value, _args) do
    {:error, "currency filter requires a number"}
  end

  @doc """
  Formats large numbers with K, M, B suffixes.
  """
  def currency_short(value, _args) when is_number(value) do
    cond do
      value >= 1_000_000_000 ->
        {:ok, "$#{Float.round(value / 1_000_000_000, 1)}B"}
      value >= 1_000_000 ->
        {:ok, "$#{Float.round(value / 1_000_000, 1)}M"}
      value >= 1_000 ->
        {:ok, "$#{Float.round(value / 1_000, 1)}K"}
      true ->
        {:ok, "$#{value}"}
    end
  end

  def currency_short(_value, _args) do
    {:error, "currency_short filter requires a number"}
  end
end
```

**Usage in templates:**

```elixir
context = %{"price" => 1234.56, "revenue" => 1_500_000_000}

Mau.render("{{ price | currency }}", context)
# Output: "$1234.56"

Mau.render("{{ revenue | currency_short }}", context)
# Output: "$1.5B"
```

---

## Filter with Arguments

Create a filter that accepts parameters:

```elixir
defmodule MyApp.StringFilters do
  def spec do
    %{
      category: :string,
      description: "String manipulation filters",
      filters: %{
        "mask" => %{
          description: "Masks part of a string",
          function: {__MODULE__, :mask}
        },
        "repeat" => %{
          description: "Repeats a string N times",
          function: {__MODULE__, :repeat}
        }
      }
    }
  end

  @doc """
  Masks a string, showing only first and last N characters.

  Usage: {{ email | mask(3) }}
  "john@example.com" -> "joh***@example.***"
  """
  def mask(value, [num]) when is_binary(value) and is_integer(num) do
    cond do
      String.length(value) <= num * 2 ->
        {:ok, String.duplicate("*", String.length(value))}

      true ->
        first = String.slice(value, 0, num)
        last = String.slice(value, -num..-1)
        middle = String.duplicate("*", String.length(value) - num * 2)
        {:ok, first <> middle <> last}
    end
  end

  def mask(_value, _args) do
    {:error, "mask requires a string and number argument"}
  end

  @doc """
  Repeats a string N times.

  Usage: {{ word | repeat(3) }}
  "Ha" -> "HaHaHa"
  """
  def repeat(value, [count]) when is_binary(value) and is_integer(count) and count > 0 do
    {:ok, String.duplicate(value, count)}
  end

  def repeat(_value, _args) do
    {:error, "repeat requires a string and positive integer"}
  end
end
```

**Usage:**

```elixir
context = %{"email" => "john@example.com", "word" => "Ha"}

Mau.render("{{ email | mask(3) }}", context)
# Output: "joh***@example.***"

Mau.render("{{ word | repeat(3) }}", context)
# Output: "HaHaHa"
```

---

## Complex Filter with Multiple Arguments

Create a filter for string replacement with options:

```elixir
defmodule MyApp.AdvancedFilters do
  def spec do
    %{
      category: :advanced,
      description: "Advanced transformation filters",
      filters: %{
        "replace_multiple" => %{
          description: "Replace multiple patterns",
          function: {__MODULE__, :replace_multiple}
        },
        "slugify" => %{
          description: "Convert to URL-friendly slug",
          function: {__MODULE__, :slugify}
        }
      }
    }
  end

  @doc """
  Replace multiple patterns in a string.

  Usage: {{ text | replace_multiple(search1, replace1, search2, replace2) }}
  """
  def replace_multiple(value, args) when is_binary(value) and is_list(args) do
    if rem(length(args), 2) == 0 do
      result = Enum.reduce(Enum.chunk_every(args, 2), value, fn [search, replace], acc ->
        String.replace(acc, to_string(search), to_string(replace))
      end)
      {:ok, result}
    else
      {:error, "replace_multiple requires pairs of (search, replace) arguments"}
    end
  end

  def replace_multiple(_value, _args) do
    {:error, "replace_multiple requires a string and argument pairs"}
  end

  @doc """
  Convert string to URL-friendly slug.

  Usage: {{ title | slugify }}
  "Hello World!" -> "hello-world"
  """
  def slugify(value, _args) when is_binary(value) do
    slugified =
      value
      |> String.downcase()
      |> String.replace(~r/[^\w\s-]/u, "")
      |> String.trim()
      |> String.replace(~r/\s+/u, "-")
      |> String.replace(~r/-+/, "-")

    {:ok, slugified}
  end

  def slugify(_value, _args) do
    {:error, "slugify requires a string"}
  end
end
```

**Usage:**

```elixir
context = %{
  "text" => "Hello {{name}} from {{company}}!",
  "title" => "My Awesome Blog Post!"
}

Mau.render("{{ text | replace_multiple('{{name}}', 'Alice', '{{company}}', 'Acme') }}", context)
# Output: "Hello Alice from Acme!"

Mau.render("{{ title | slugify }}", context)
# Output: "my-awesome-blog-post"
```

---

## Conditional Filter Logic

Create a filter with conditional behavior:

```elixir
defmodule MyApp.ConditionalFilters do
  def spec do
    %{
      category: :conditional,
      description: "Conditional filters",
      filters: %{
        "pluralize" => %{
          description: "Pluralize words based on count",
          function: {__MODULE__, :pluralize}
        },
        "human_filesize" => %{
          description: "Convert bytes to human-readable format",
          function: {__MODULE__, :human_filesize}
        }
      }
    }
  end

  @doc """
  Pluralize a word based on count.

  Usage: {{ count | pluralize('item') }}
  1 -> "1 item"
  5 -> "5 items"
  """
  def pluralize(count, [word]) when is_integer(count) and is_binary(word) do
    suffix = if count == 1, do: "", else: "s"
    {:ok, "#{count} #{word}#{suffix}"}
  end

  def pluralize(_value, _args) do
    {:error, "pluralize requires a number and word"}
  end

  @doc """
  Convert bytes to human-readable file size.

  Usage: {{ filesize | human_filesize }}
  1024 -> "1 KB"
  1048576 -> "1 MB"
  """
  def human_filesize(bytes, _args) when is_integer(bytes) and bytes >= 0 do
    cond do
      bytes < 1024 ->
        {:ok, "#{bytes} B"}
      bytes < 1024 * 1024 ->
        {:ok, "#{Float.round(bytes / 1024, 1)} KB"}
      bytes < 1024 * 1024 * 1024 ->
        {:ok, "#{Float.round(bytes / (1024 * 1024), 1)} MB"}
      true ->
        {:ok, "#{Float.round(bytes / (1024 * 1024 * 1024), 2)} GB"}
    end
  end

  def human_filesize(_value, _args) do
    {:error, "human_filesize requires a non-negative integer"}
  end
end
```

**Usage:**

```elixir
context = %{"items" => 1, "more_items" => 5, "filesize" => 1048576}

Mau.render("You have {{ items | pluralize('item') }}", context)
# Output: "You have 1 item"

Mau.render("You have {{ more_items | pluralize('item') }}", context)
# Output: "You have 5 items"

Mau.render("File size: {{ filesize | human_filesize }}", context)
# Output: "File size: 1 MB"
```

---

## Registering Custom Filters

Add your custom filters to the application configuration:

```elixir
# config/config.exs

config :mau,
  filters: [
    MyApp.CurrencyFilters,
    MyApp.StringFilters,
    MyApp.AdvancedFilters,
    MyApp.ConditionalFilters
  ],
  enable_runtime_filters: true
```

Or enable runtime filter loading in your application supervisor:

```elixir
# lib/my_app/application.ex

defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # ... other services
      Mau.FilterRegistry
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

---

## Testing Custom Filters

Write tests for your custom filters:

```elixir
defmodule MyApp.CustomFiltersTest do
  use ExUnit.Case

  test "currency filter formats numbers" do
    assert {:ok, "$1234.56"} = MyApp.CurrencyFilters.currency(1234.56, [])
    assert {:ok, "$0.99"} = MyApp.CurrencyFilters.currency(0.99, [])
  end

  test "currency filter rejects non-numbers" do
    assert {:error, _} = MyApp.CurrencyFilters.currency("not a number", [])
  end

  test "mask filter hides middle characters" do
    assert {:ok, "joh***@example.***"} = MyApp.StringFilters.mask("john@example.com", [3])
  end

  test "slugify converts to URL-friendly format" do
    assert {:ok, "my-awesome-post"} = MyApp.AdvancedFilters.slugify("My Awesome Post!", [])
  end

  test "pluralize handles singular and plural" do
    assert {:ok, "1 item"} = MyApp.ConditionalFilters.pluralize(1, ["item"])
    assert {:ok, "5 items"} = MyApp.ConditionalFilters.pluralize(5, ["item"])
  end
end
```

---

## Best Practices

### 1. Error Handling

Always validate inputs and return meaningful error messages:

```elixir
def my_filter(value, args) do
  case validate_input(value, args) do
    {:ok, cleaned_value} -> process(cleaned_value)
    {:error, reason} -> {:error, reason}
  end
end

defp validate_input(value, args) when is_number(value) and is_list(args) do
  {:ok, value}
end

defp validate_input(_value, _args) do
  {:error, "my_filter requires a number and list of arguments"}
end
```

### 2. Type Coercion

Handle type conversions gracefully:

```elixir
def my_filter(value, args) do
  try do
    numeric_value = value |> to_string() |> String.to_integer()
    {:ok, numeric_value * 2}
  rescue
    _ -> {:error, "Could not convert value to number"}
  end
end
```

### 3. Documentation

Include clear documentation with usage examples:

```elixir
@doc """
Transforms text for social media.

Converts to lowercase, removes special characters, and
truncates to specified length (default: 140).

Usage:
  {{ text | social_format }}
  {{ text | social_format(280) }}

Returns:
  {:ok, transformed_text}
  {:error, reason}
"""
def social_format(value, args) do
  # implementation
end
```

### 4. Performance Considerations

For filters applied to large datasets, optimize for speed:

```elixir
def my_filter(value, _args) when is_list(value) do
  # Use Enum.reduce for better performance with large lists
  result = Enum.reduce(value, [], &process_item/2)
  {:ok, result}
end

defp process_item(item, acc) do
  # Efficient processing
  [transformed | acc]
end
```

### 5. Composability

Design filters that work well in chains:

```elixir
def my_filter(value, args) when is_binary(value) do
  value
  |> String.downcase()           # Works as first filter
  |> String.trim()               # Returns binary
  |> String.split(" ")           # Returns list
  |> Enum.map(&capitalize/1)    # Can be used in pipe
  |> Enum.join(" ")              # Back to binary
  |> then(&{:ok, &1})            # Return wrapped result
end
```

---

## Advanced: Stateful Filters

Create filters that maintain state (use with caution):

```elixir
defmodule MyApp.StatefulFilters do
  def spec do
    %{
      category: :stateful,
      description: "Filters with state",
      filters: %{
        "with_counter" => %{
          description: "Appends counter value",
          function: {__MODULE__, :with_counter}
        }
      }
    }
  end

  @doc """
  Appends a counter to the value.
  Uses process dictionary for state.
  """
  def with_counter(value, _args) do
    counter = Process.get(:filter_counter, 0)
    new_counter = counter + 1
    Process.put(:filter_counter, new_counter)

    {:ok, "#{value}-#{new_counter}"}
  end
end
```

---

## Common Filter Patterns

### Map Transformation

```elixir
def transform_items(items, [key]) when is_list(items) do
  result = Enum.map(items, &Map.get(&1, key))
  {:ok, result}
end
```

### Filtering Collection

```elixir
def by_status(items, [status]) when is_list(items) do
  result = Enum.filter(items, &(&1["status"] == status))
  {:ok, result}
end
```

### Aggregation

```elixir
def sum_field(items, [field]) when is_list(items) do
  result =
    items
    |> Enum.map(&(Map.get(&1, field, 0)))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  {:ok, result}
end
```

---

## Troubleshooting

**Filter not found**: Ensure filter module is registered in config

**Type errors**: Check input validation in filter function

**Performance issues**: Use `:timer.tc` to benchmark custom filters

```elixir
{time_us, result} = :timer.tc(fn -> my_filter(value, args) end)
IO.puts("Filter took #{time_us / 1000} ms")
```

---

## See Also

- [Custom Functions](custom-functions.md) - Creating custom functions
- [Filters Guide](../guides/filters.md) - Using filters in templates
- [Filters List](../reference/filters-list.md) - Built-in filters reference
- [Performance Tuning](performance-tuning.md) - Optimization techniques
