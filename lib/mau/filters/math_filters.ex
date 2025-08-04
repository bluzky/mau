defmodule Mau.Filters.MathFilters do
  @moduledoc """
  Mathematical operation filters for Mau templates.
  """

  @doc """
  Returns the absolute value of a number.
  
  ## Examples
  
      iex> Mau.Filters.MathFilters.abs(-5, [])
      5
      
      iex> Mau.Filters.MathFilters.abs(3.14, [])
      3.14
      
      iex> Mau.Filters.MathFilters.abs("-42", [])
      42.0
  """
  def abs(value, _args) do
    value
    |> to_number()
    |> Kernel.abs()
  end

  @doc """
  Returns the ceiling of a number (smallest integer greater than or equal to the number).
  
  ## Examples
  
      iex> Mau.Filters.MathFilters.ceil(3.14, [])
      4
      
      iex> Mau.Filters.MathFilters.ceil(-2.7, [])
      -2
  """
  def ceil(value, _args) do
    value
    |> to_number()
    |> Float.ceil()
    |> trunc()
  end

  @doc """
  Returns the floor of a number (largest integer less than or equal to the number).
  
  ## Examples
  
      iex> Mau.Filters.MathFilters.floor(3.14, [])
      3
      
      iex> Mau.Filters.MathFilters.floor(-2.7, [])
      -3
  """
  def floor(value, _args) do
    value
    |> to_number()
    |> Float.floor()
    |> trunc()
  end

  @doc """
  Returns the maximum of the input value and the provided arguments.
  
  ## Examples
  
      iex> Mau.Filters.MathFilters.max(5, [10])
      10
      
      iex> Mau.Filters.MathFilters.max(15, [10])
      15
      
      iex> Mau.Filters.MathFilters.max(5, [3, 7, 2])
      7
  """
  def max(value, args) do
    number = to_number(value)
    
    case args do
      [] -> number
      numbers ->
        [number | Enum.map(numbers, &to_number/1)]
        |> Enum.max()
    end
  end

  @doc """
  Returns the minimum of the input value and the provided arguments.
  
  ## Examples
  
      iex> Mau.Filters.MathFilters.min(5, [10])
      5
      
      iex> Mau.Filters.MathFilters.min(15, [10])
      10
      
      iex> Mau.Filters.MathFilters.min(5, [3, 7, 2])
      2
  """
  def min(value, args) do
    number = to_number(value)
    
    case args do
      [] -> number
      numbers ->
        [number | Enum.map(numbers, &to_number/1)]
        |> Enum.min()
    end
  end

  @doc """
  Raises a number to the specified power.
  
  ## Examples
  
      iex> Mau.Filters.MathFilters.power(2, [3])
      8.0
      
      iex> Mau.Filters.MathFilters.power(5, [2])
      25.0
  """
  def power(value, args) do
    base = to_number(value)
    
    case args do
      [exponent] ->
        exponent_num = to_number(exponent)
        :math.pow(base, exponent_num)
      
      _ -> base
    end
  end

  @doc """
  Returns the square root of a number.
  
  ## Examples
  
      iex> Mau.Filters.MathFilters.sqrt(16, [])
      4.0
      
      iex> Mau.Filters.MathFilters.sqrt(2, [])
      1.4142135623730951
  """
  def sqrt(value, _args) do
    value
    |> to_number()
    |> :math.sqrt()
  end

  @doc """
  Returns the modulo (remainder) of dividing the input by the provided argument.
  
  ## Examples
  
      iex> Mau.Filters.MathFilters.mod(10, [3])
      1
      
      iex> Mau.Filters.MathFilters.mod(15, [4])
      3
  """
  def mod(value, args) do
    number = to_number(value)
    
    case args do
      [divisor] ->
        divisor_num = to_number(divisor)
        if divisor_num == 0, do: 0, else: rem(trunc(number), trunc(divisor_num))
      
      _ -> 0
    end
  end

  @doc """
  Clamps a number between a minimum and maximum value.
  
  ## Examples
  
      iex> Mau.Filters.MathFilters.clamp(5, [1, 10])
      5
      
      iex> Mau.Filters.MathFilters.clamp(-5, [1, 10])
      1
      
      iex> Mau.Filters.MathFilters.clamp(15, [1, 10])
      10
  """
  def clamp(value, args) do
    number = to_number(value)
    
    case args do
      [min_val, max_val] ->
        min_num = to_number(min_val)
        max_num = to_number(max_val)
        
        number
        |> Kernel.max(min_num)
        |> Kernel.min(max_num)
      
      _ -> number
    end
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
end