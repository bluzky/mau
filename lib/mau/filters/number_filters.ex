defmodule Mau.Filters.NumberFilters do
  @moduledoc """
  Number manipulation filters for Mau templates.
  """

  @doc """
  Rounds a number to the specified precision.
  
  ## Examples
  
      iex> Mau.Filters.NumberFilters.round(3.14159, [2])
      {:ok, 3.14}
      
      iex> Mau.Filters.NumberFilters.round(3.14159, [])
      {:ok, 3}
      
      iex> Mau.Filters.NumberFilters.round("3.14159", [1])
      {:ok, 3.1}
      
      iex> Mau.Filters.NumberFilters.round("invalid", [])
      {:error, "Cannot convert to number"}
  """
  def round(value, args) when is_number(value) do
    case args do
      [precision] when is_integer(precision) and precision >= 0 ->
        {:ok, Float.round(value, precision)}
      
      [precision] when is_integer(precision) ->
        {:error, "Precision must be non-negative"}
      
      [] ->
        {:ok, Kernel.round(value)}
      
      _ ->
        {:error, "Invalid round arguments"}
    end
  end
  
  def round(value, args) do
    case to_number(value) do
      {:ok, number} -> round(number, args)
      {:error, _} -> {:error, "Cannot convert to number"}
    end
  end

  @doc """
  Formats a number as currency with optional currency symbol.
  
  ## Examples
  
      iex> Mau.Filters.NumberFilters.format_currency(1234.56, [])
      {:ok, "$1,234.56"}
      
      iex> Mau.Filters.NumberFilters.format_currency(1234.56, ["€"])
      {:ok, "€1,234.56"}
      
      iex> Mau.Filters.NumberFilters.format_currency("1234.56", ["£"])
      {:ok, "£1,234.56"}
      
      iex> Mau.Filters.NumberFilters.format_currency("invalid", [])
      {:error, "Cannot convert to number"}
  """
  def format_currency(value, args) when is_number(value) do
    symbol = case args do
      [currency_symbol] when is_binary(currency_symbol) -> currency_symbol
      [] -> "$"
      _ -> "$"
    end
    
    formatted_number = 
      value
      |> Float.round(2)
      |> :erlang.float_to_binary(decimals: 2)
      |> add_thousands_separator()
    
    {:ok, "#{symbol}#{formatted_number}"}
  end
  
  def format_currency(value, args) do
    case to_number(value) do
      {:ok, number} -> format_currency(number, args)
      {:error, _} -> {:error, "Cannot convert to number"}
    end
  end

  # Private functions

  defp to_number(value) when is_number(value), do: {:ok, value}
  defp to_number(value) when is_binary(value) do
    case Float.parse(value) do
      {number, _} -> {:ok, number}
      :error -> {:error, "Invalid number format"}
    end
  end
  defp to_number(_), do: {:error, "Cannot convert to number"}

  defp add_thousands_separator(number_string) do
    case String.split(number_string, ".") do
      [integer_part, decimal_part] ->
        formatted_integer = format_integer_with_commas(integer_part)
        "#{formatted_integer}.#{decimal_part}"
      
      [integer_part] ->
        format_integer_with_commas(integer_part)
    end
  end
  
  defp format_integer_with_commas(integer_part) do
    integer_part
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
    |> String.reverse()
  end
end