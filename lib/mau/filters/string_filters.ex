defmodule Mau.Filters.StringFilters do
  @moduledoc """
  String manipulation filters for Mau templates.
  """

  @doc """
  Converts a string to uppercase.

  ## Examples

      iex> Mau.Filters.StringFilters.upper_case("hello", [])
      {:ok, "HELLO"}
      
      iex> Mau.Filters.StringFilters.upper_case(123, [])
      {:ok, "123"}
  """
  def upper_case(value, _args) when is_binary(value) do
    {:ok, String.upcase(value)}
  end

  def upper_case(value, _args) do
    {:ok, value |> to_string() |> String.upcase()}
  end

  @doc """
  Converts a string to lowercase.

  ## Examples

      iex> Mau.Filters.StringFilters.lower_case("HELLO", [])
      {:ok, "hello"}
      
      iex> Mau.Filters.StringFilters.lower_case(123, [])
      {:ok, "123"}
  """
  def lower_case(value, _args) when is_binary(value) do
    {:ok, String.downcase(value)}
  end

  def lower_case(value, _args) do
    {:ok, value |> to_string() |> String.downcase()}
  end

  @doc """
  Capitalizes the first letter of a string.

  ## Examples

      iex> Mau.Filters.StringFilters.capitalize("hello world", [])
      {:ok, "Hello world"}
      
      iex> Mau.Filters.StringFilters.capitalize("", [])
      {:ok, ""}
  """
  def capitalize(value, _args) when is_binary(value) do
    {:ok, String.capitalize(value)}
  end

  def capitalize(value, _args) do
    {:ok, value |> to_string() |> String.capitalize()}
  end

  @doc """
  Truncates a string to the specified length.

  ## Examples

      iex> Mau.Filters.StringFilters.truncate("hello world", [5])
      {:ok, "hello"}
      
      iex> Mau.Filters.StringFilters.truncate("hello", [10])
      {:ok, "hello"}
      
      iex> Mau.Filters.StringFilters.truncate("hello world", [])
      {:ok, "hello world"}
      
      iex> Mau.Filters.StringFilters.truncate("hello", [-5])
      {:error, "Truncate length must be non-negative"}
  """
  def truncate(value, args) when is_binary(value) do
    case args do
      [length] when is_integer(length) and length >= 0 ->
        {:ok, String.slice(value, 0, length)}

      [length] when is_integer(length) ->
        {:error, "Truncate length must be non-negative"}

      [] ->
        {:ok, value}

      _ ->
        {:error, "Invalid truncate arguments"}
    end
  end

  def truncate(value, args) do
    truncate(to_string(value), args)
  end

  @doc """
  Returns the default value if the input is nil, empty, or falsy.

  ## Examples

      iex> Mau.Filters.StringFilters.default(nil, ["fallback"])
      {:ok, "fallback"}
      
      iex> Mau.Filters.StringFilters.default("", ["fallback"])
      {:ok, "fallback"}
      
      iex> Mau.Filters.StringFilters.default("value", ["fallback"])  
      {:ok, "value"}
  """
  def default(value, args) do
    fallback =
      case args do
        [fallback_value] -> fallback_value
        [] -> ""
        _ -> ""
      end

    result =
      case value do
        nil -> fallback
        "" -> fallback
        false -> fallback
        _ -> value
      end

    {:ok, result}
  end

  @doc """
  Removes leading and trailing whitespace from a string.

  ## Examples

      iex> Mau.Filters.StringFilters.strip("  hello world  ", [])
      {:ok, "hello world"}
      
      iex> Mau.Filters.StringFilters.strip("\\n\\t hello \\n\\t", [])
      {:ok, "hello"}
      
      iex> Mau.Filters.StringFilters.strip(123, [])
      {:ok, "123"}
  """
  def strip(value, _args) when is_binary(value) do
    {:ok, String.trim(value)}
  end

  def strip(value, args) do
    strip(to_string(value), args)
  end
end
