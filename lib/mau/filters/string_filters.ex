defmodule Mau.Filters.StringFilters do
  @moduledoc """
  String manipulation filters for Mau templates.
  """

  @doc """
  Converts a string to uppercase.
  
  ## Examples
  
      iex> Mau.Filters.StringFilters.upper_case("hello", [])
      "HELLO"
      
      iex> Mau.Filters.StringFilters.upper_case(123, [])
      "123"
  """
  def upper_case(value, _args) do
    value
    |> to_string()
    |> String.upcase()
  end

  @doc """
  Converts a string to lowercase.
  
  ## Examples
  
      iex> Mau.Filters.StringFilters.lower_case("HELLO", [])
      "hello"
      
      iex> Mau.Filters.StringFilters.lower_case(123, [])
      "123"
  """
  def lower_case(value, _args) do
    value
    |> to_string()
    |> String.downcase()
  end

  @doc """
  Capitalizes the first letter of a string.
  
  ## Examples
  
      iex> Mau.Filters.StringFilters.capitalize("hello world", [])
      "Hello world"
      
      iex> Mau.Filters.StringFilters.capitalize("", [])
      ""
  """
  def capitalize(value, _args) do
    value
    |> to_string()
    |> String.capitalize()
  end

  @doc """
  Truncates a string to the specified length.
  
  ## Examples
  
      iex> Mau.Filters.StringFilters.truncate("hello world", [5])
      "hello"
      
      iex> Mau.Filters.StringFilters.truncate("hello", [10])
      "hello"
      
      iex> Mau.Filters.StringFilters.truncate("hello world", [])
      "hello world"
  """
  def truncate(value, args) do
    string = to_string(value)
    
    case args do
      [length] when is_integer(length) and length >= 0 ->
        String.slice(string, 0, length)
      
      [] ->
        string
      
      _ ->
        string
    end
  end

  @doc """
  Returns the default value if the input is nil, empty, or falsy.
  
  ## Examples
  
      iex> Mau.Filters.StringFilters.default(nil, ["fallback"])
      "fallback"
      
      iex> Mau.Filters.StringFilters.default("", ["fallback"])
      "fallback"
      
      iex> Mau.Filters.StringFilters.default("value", ["fallback"])  
      "value"
  """
  def default(value, args) do
    fallback = case args do
      [fallback_value] -> fallback_value
      [] -> ""
      _ -> ""
    end
    
    case value do
      nil -> fallback
      "" -> fallback
      false -> fallback
      _ -> value
    end
  end
end