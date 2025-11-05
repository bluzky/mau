# Creating Custom Functions

Learn how to implement custom functions for your specific use cases.

## Overview

In Mau, functions and filters are the same thing - they use identical implementation patterns. This guide covers creating functions that perform specialized operations in templates.

## Function Basics

Custom functions follow the same structure as filters:

```elixir
defmodule MyApp.CustomFunctions do
  def spec do
    %{
      category: :custom,
      description: "Custom functions for MyApp",
      filters: %{
        "my_function" => %{
          description: "What this function does",
          function: {__MODULE__, :my_function}
        }
      }
    }
  end

  def my_function(value, args) do
    {:ok, result}
  end
end
```

## Math Functions

Create domain-specific math operations:

```elixir
defmodule MyApp.MathFunctions do
  def spec do
    %{
      category: :math,
      description: "Advanced math functions",
      filters: %{
        "percentage_of" => %{
          description: "Calculate percentage of a value",
          function: {__MODULE__, :percentage_of}
        },
        "tax" => %{
          description: "Calculate tax on amount",
          function: {__MODULE__, :tax}
        },
        "discount" => %{
          description: "Calculate discounted price",
          function: {__MODULE__, :discount}
        },
        "compound_interest" => %{
          description: "Calculate compound interest",
          function: {__MODULE__, :compound_interest}
        }
      }
    }
  end

  @doc """
  Calculate percentage of a value.

  Usage: {{ amount | percentage_of(20) }}
  100 -> 20 (20% of 100)
  """
  def percentage_of(amount, [percentage]) when is_number(amount) and is_number(percentage) do
    result = amount * percentage / 100
    {:ok, Float.round(result, 2)}
  end

  def percentage_of(_value, _args) do
    {:error, "percentage_of requires a number and percentage"}
  end

  @doc """
  Calculate tax on amount.

  Usage: {{ amount | tax(8.5) }}
  Default tax rate: 10%
  """
  def tax(amount, args) when is_number(amount) do
    tax_rate = case args do
      [rate] when is_number(rate) -> rate
      _ -> 10  # Default to 10%
    end

    result = amount * tax_rate / 100
    {:ok, Float.round(result, 2)}
  end

  def tax(_value, _args) do
    {:error, "tax requires a number"}
  end

  @doc """
  Calculate discounted price.

  Usage: {{ original_price | discount(25) }}
  Subtracts discount percentage from original price
  """
  def discount(original_price, [discount_percent])
      when is_number(original_price) and is_number(discount_percent) do
    discount_amount = original_price * discount_percent / 100
    result = original_price - discount_amount
    {:ok, Float.round(result, 2)}
  end

  def discount(_value, _args) do
    {:error, "discount requires a price and discount percentage"}
  end

  @doc """
  Calculate compound interest.

  Usage: {{ principal | compound_interest(rate, years, compounds) }}
  compound_interest(1000, [5, 10, 12]) -> amount after 10 years at 5% compounded monthly
  """
  def compound_interest(principal, [rate, years, compounds])
      when is_number(principal) and is_number(rate) and is_number(years) and is_number(compounds) do
    rate_decimal = rate / 100
    exponent = compounds * years
    base = 1 + rate_decimal / compounds

    result = principal * :math.pow(base, exponent)
    {:ok, Float.round(result, 2)}
  end

  def compound_interest(_value, _args) do
    {:error, "compound_interest requires principal, rate, years, and compounds"}
  end
end
```

**Usage:**

```elixir
context = %{
  "amount" => 100,
  "price" => 99.99,
  "principal" => 1000
}

Mau.render("{{ amount | percentage_of(20) }}", context)
# Output: "20"

Mau.render("{{ price | tax(8.5) }}", context)
# Output: "8.5"

Mau.render("{{ price | discount(25) }}", context)
# Output: "74.99"
```

---

## Date/Time Functions

Create date and time utilities:

```elixir
defmodule MyApp.DateFunctions do
  def spec do
    %{
      category: :datetime,
      description: "Date and time functions",
      filters: %{
        "days_since" => %{
          description: "Calculate days since a date",
          function: {__MODULE__, :days_since}
        },
        "format_date" => %{
          description: "Format date string",
          function: {__MODULE__, :format_date}
        },
        "is_past" => %{
          description: "Check if date is in the past",
          function: {__MODULE__, :is_past}
        }
      }
    }
  end

  @doc """
  Calculate days since a given date.

  Usage: {{ date | days_since }}
  Requires ISO8601 formatted date string
  """
  def days_since(date_string, _args) when is_binary(date_string) do
    try do
      {:ok, date, _} = DateTime.from_iso8601(date_string)
      today = DateTime.utc_now()
      days = DateTime.diff(today, date, :day)
      {:ok, days}
    rescue
      _ -> {:error, "Invalid date format. Use ISO8601."}
    end
  end

  def days_since(_value, _args) do
    {:error, "days_since requires an ISO8601 date string"}
  end

  @doc """
  Format date for display.

  Usage: {{ date | format_date("%B %d, %Y") }}
  """
  def format_date(date_string, [format]) when is_binary(date_string) and is_binary(format) do
    try do
      {:ok, date, _} = DateTime.from_iso8601(date_string)
      formatted = Calendar.strftime(date, format)
      {:ok, formatted}
    rescue
      _ -> {:error, "Could not format date"}
    end
  end

  def format_date(_value, _args) do
    {:error, "format_date requires a date string and format"}
  end

  @doc """
  Check if date is in the past.
  """
  def is_past(date_string, _args) when is_binary(date_string) do
    try do
      {:ok, date, _} = DateTime.from_iso8601(date_string)
      is_past_date = DateTime.compare(date, DateTime.utc_now()) == :lt
      {:ok, is_past_date}
    rescue
      _ -> {:error, "Invalid date format"}
    end
  end

  def is_past(_value, _args) do
    {:error, "is_past requires an ISO8601 date string"}
  end
end
```

---

## Validation Functions

Create functions that validate data:

```elixir
defmodule MyApp.ValidationFunctions do
  def spec do
    %{
      category: :validation,
      description: "Data validation functions",
      filters: %{
        "is_email" => %{
          description: "Validate email format",
          function: {__MODULE__, :is_email}
        },
        "is_phone" => %{
          description: "Validate phone number",
          function: {__MODULE__, :is_phone}
        },
        "is_url" => %{
          description: "Validate URL format",
          function: {__MODULE__, :is_url}
        }
      }
    }
  end

  @doc """
  Validate email format.
  """
  def is_email(email, _args) when is_binary(email) do
    # Simple email validation regex
    regex = ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/
    {:ok, Regex.match?(regex, email)}
  end

  def is_email(_value, _args) do
    {:error, "is_email requires a string"}
  end

  @doc """
  Validate phone number (basic check).
  """
  def is_phone(phone, _args) when is_binary(phone) do
    # Remove common separators and check for digits
    cleaned = String.replace(phone, ~r/[\s\-\(\)\+]/, "")
    is_valid = String.length(cleaned) >= 10 and String.match?(cleaned, ~r/^\d+$/)
    {:ok, is_valid}
  end

  def is_phone(_value, _args) do
    {:error, "is_phone requires a string"}
  end

  @doc """
  Validate URL format.
  """
  def is_url(url, _args) when is_binary(url) do
    # Simple URL validation
    regex = ~r/^https?:\/\/.+/
    {:ok, Regex.match?(regex, url)}
  end

  def is_url(_value, _args) do
    {:error, "is_url requires a string"}
  end
end
```

**Usage in templates:**

```elixir
{% if email | is_email %}
  Email is valid
{% else %}
  Please enter a valid email
{% endif %}
```

---

## Encoding/Decoding Functions

Create encoding and decoding utilities:

```elixir
defmodule MyApp.EncodingFunctions do
  def spec do
    %{
      category: :encoding,
      description: "Encoding and decoding functions",
      filters: %{
        "base64_encode" => %{
          description: "Encode to base64",
          function: {__MODULE__, :base64_encode}
        },
        "base64_decode" => %{
          description: "Decode from base64",
          function: {__MODULE__, :base64_decode}
        },
        "url_encode" => %{
          description: "URL encode a string",
          function: {__MODULE__, :url_encode}
        },
        "html_escape" => %{
          description: "Escape HTML special characters",
          function: {__MODULE__, :html_escape}
        }
      }
    }
  end

  def base64_encode(value, _args) when is_binary(value) do
    encoded = Base.encode64(value)
    {:ok, encoded}
  end

  def base64_encode(_value, _args) do
    {:error, "base64_encode requires a string"}
  end

  def base64_decode(value, _args) when is_binary(value) do
    case Base.decode64(value) do
      {:ok, decoded} -> {:ok, decoded}
      :error -> {:error, "Invalid base64 string"}
    end
  end

  def base64_decode(_value, _args) do
    {:error, "base64_decode requires a string"}
  end

  def url_encode(value, _args) when is_binary(value) do
    encoded = URI.encode(value)
    {:ok, encoded}
  end

  def url_encode(_value, _args) do
    {:error, "url_encode requires a string"}
  end

  def html_escape(value, _args) when is_binary(value) do
    escaped =
      value
      |> String.replace("&", "&amp;")
      |> String.replace("<", "&lt;")
      |> String.replace(">", "&gt;")
      |> String.replace("\"", "&quot;")
      |> String.replace("'", "&#x27;")

    {:ok, escaped}
  end

  def html_escape(_value, _args) do
    {:error, "html_escape requires a string"}
  end
end
```

---

## Statistical Functions

Create functions for data analysis:

```elixir
defmodule MyApp.StatisticsFunctions do
  def spec do
    %{
      category: :statistics,
      description: "Statistical functions",
      filters: %{
        "mean" => %{
          description: "Calculate mean of numbers",
          function: {__MODULE__, :mean}
        },
        "median" => %{
          description: "Calculate median of numbers",
          function: {__MODULE__, :median}
        },
        "std_dev" => %{
          description: "Calculate standard deviation",
          function: {__MODULE__, :std_dev}
        }
      }
    }
  end

  @doc """
  Calculate mean (average) of a list of numbers.
  """
  def mean(values, _args) when is_list(values) do
    numbers = Enum.filter(values, &is_number/1)

    if Enum.empty?(numbers) do
      {:error, "No numeric values in list"}
    else
      average = Enum.sum(numbers) / length(numbers)
      {:ok, Float.round(average, 2)}
    end
  end

  def mean(_value, _args) do
    {:error, "mean requires a list of numbers"}
  end

  @doc """
  Calculate median of a list of numbers.
  """
  def median(values, _args) when is_list(values) do
    numbers =
      values
      |> Enum.filter(&is_number/1)
      |> Enum.sort()

    case length(numbers) do
      0 ->
        {:error, "No numeric values in list"}

      count ->
        mid = div(count, 2)

        result = if rem(count, 2) == 0 do
          (Enum.at(numbers, mid - 1) + Enum.at(numbers, mid)) / 2
        else
          Enum.at(numbers, mid)
        end

        {:ok, Float.round(result, 2)}
    end
  end

  def median(_value, _args) do
    {:error, "median requires a list of numbers"}
  end

  @doc """
  Calculate standard deviation.
  """
  def std_dev(values, _args) when is_list(values) do
    numbers = Enum.filter(values, &is_number/1)

    if length(numbers) < 2 do
      {:error, "std_dev requires at least 2 numeric values"}
    else
      mean_val = Enum.sum(numbers) / length(numbers)
      variance =
        numbers
        |> Enum.map(&:math.pow(&1 - mean_val, 2))
        |> Enum.sum()
        |> Kernel./(length(numbers))

      std = :math.sqrt(variance)
      {:ok, Float.round(std, 2)}
    end
  end

  def std_dev(_value, _args) do
    {:error, "std_dev requires a list of numbers"}
  end
end
```

---

## Best Practices

### 1. Clear Documentation

```elixir
@doc """
Description of what the function does.

Parameters:
  - input (type): What it is
  - arg1 (type): What it's for

Returns:
  - Success: {:ok, result}
  - Error: {:error, "error message"}

Usage examples:
  {{ value | my_func }}
  {{ value | my_func: arg1, arg2 }}
"""
```

### 2. Consistent Error Messages

```elixir
def my_func(value, args) do
  case validate(value, args) do
    :ok -> process(value, args)
    :error -> {:error, "my_func: description of what went wrong"}
  end
end
```

### 3. Handle Edge Cases

```elixir
def divide(numerator, [denominator]) when is_number(numerator) and is_number(denominator) do
  if denominator == 0 do
    {:error, "Cannot divide by zero"}
  else
    {:ok, numerator / denominator}
  end
end
```

### 4. Use Guards

```elixir
# Good: Early filtering of invalid inputs
def my_func(value, _args) when is_binary(value) do
  {:ok, process(value)}
end

def my_func(_value, _args) do
  {:error, "my_func requires a string"}
end
```

### 5. Test Thoroughly

```elixir
defmodule MyApp.CustomFunctionsTest do
  use ExUnit.Case

  test "mean calculates average correctly" do
    assert {:ok, 3.0} = MyApp.StatisticsFunctions.mean([1, 2, 3, 4, 5], [])
  end

  test "mean handles empty list" do
    assert {:error, _} = MyApp.StatisticsFunctions.mean([], [])
  end

  test "mean handles non-numeric values" do
    assert {:error, _} = MyApp.StatisticsFunctions.mean(["a", "b", "c"], [])
  end
end
```

---

## See Also

- [Custom Filters](custom-filters.md) - Creating custom filters
- [Performance Tuning](performance-tuning.md) - Optimization techniques
- [API Reference](../reference/api-reference.md) - Mau API documentation
