defmodule Mau.Filters.NumberFilters do
  @moduledoc """
  Number manipulation filters for Mau templates.
  """

  @doc """
  Rounds a number to the specified precision.
  
  ## Examples
  
      iex> Mau.Filters.NumberFilters.round(3.14159, [2])
      3.14
      
      iex> Mau.Filters.NumberFilters.round(3.14159, [])
      3
      
      iex> Mau.Filters.NumberFilters.round("3.14159", [1])
      3.1
  """
  def round(value, args) do
    number = to_number(value)
    
    case args do
      [precision] when is_integer(precision) and precision >= 0 ->
        Float.round(number, precision)
      
      [] ->
        Kernel.round(number)
      
      _ ->
        number
    end
  end

  @doc """
  Formats a number as currency with optional currency symbol.
  
  ## Examples
  
      iex> Mau.Filters.NumberFilters.format_currency(1234.56, [])
      "$1,234.56"
      
      iex> Mau.Filters.NumberFilters.format_currency(1234.56, ["€"])
      "€1,234.56"
      
      iex> Mau.Filters.NumberFilters.format_currency("1234.56", ["£"])
      "£1,234.56"
  """
  def format_currency(value, args) do
    number = to_number(value)
    
    symbol = case args do
      [currency_symbol] when is_binary(currency_symbol) -> currency_symbol
      [] -> "$"
      _ -> "$"
    end
    
    formatted_number = 
      number
      |> Float.round(2)
      |> :erlang.float_to_binary(decimals: 2)
      |> add_thousands_separator()
    
    "#{symbol}#{formatted_number}"
  end

  # Private functions

  defp to_number(value) when is_number(value), do: value
  defp to_number(value) when is_binary(value) do
    case Float.parse(value) do
      {number, _} -> number
      :error -> 0.0
    end
  end
  defp to_number(_), do: 0.0

  defp add_thousands_separator(number_string) do
    [integer_part, decimal_part] = String.split(number_string, ".")
    
    formatted_integer = 
      integer_part
      |> String.reverse()
      |> String.graphemes()
      |> Enum.chunk_every(3)
      |> Enum.map(&Enum.join/1)
      |> Enum.join(",")
      |> String.reverse()
    
    "#{formatted_integer}.#{decimal_part}"
  end
end