defmodule Mau.Filters.Math do
  @moduledoc """
  Mathematical operation filters.
  """

  @doc """
  Returns the filter specification for this module.
  """
  def spec do
    %{
      category: :math,
      description: "Mathematical operation filters",
      filters: %{
        "abs" => %{
          description: "Returns absolute value",
          function: {__MODULE__, :abs}
        },
        "ceil" => %{
          description: "Rounds up to nearest integer",
          function: {__MODULE__, :ceil}
        },
        "floor" => %{
          description: "Rounds down to nearest integer",
          function: {__MODULE__, :floor}
        },
        "round" => %{
          description: "Rounds to nearest integer or specified decimals",
          function: {__MODULE__, :round}
        },
        "max" => %{
          description: "Returns maximum value from list or compares two values",
          function: {__MODULE__, :max_value}
        },
        "min" => %{
          description: "Returns minimum value from list or compares two values",
          function: {__MODULE__, :min_value}
        },
        "power" => %{
          description: "Raises number to a power",
          function: {__MODULE__, :power}
        },
        "sqrt" => %{
          description: "Returns square root",
          function: {__MODULE__, :sqrt}
        },
        "mod" => %{
          description: "Returns remainder of division",
          function: {__MODULE__, :mod}
        },
        "clamp" => %{
          description: "Clamps value between min and max",
          function: {__MODULE__, :clamp}
        }
      }
    }
  end

  @doc """
  Returns the absolute value of a number.
  """
  def abs(value, _args) do
    case value do
      num when is_number(num) -> {:ok, Kernel.abs(num)}
      _ -> {:error, "abs can only be applied to numbers"}
    end
  end

  @doc """
  Rounds a number up to the nearest integer.
  """
  def ceil(value, _args) do
    case value do
      # Integer is already "ceiled"
      num when is_integer(num) -> {:ok, num}
      num when is_float(num) -> {:ok, Float.ceil(num) |> trunc()}
      # Convert to float first
      num when is_number(num) -> {:ok, Float.ceil(num / 1) |> trunc()}
      _ -> {:error, "ceil can only be applied to numbers"}
    end
  end

  @doc """
  Rounds a number down to the nearest integer.
  """
  def floor(value, _args) do
    case value do
      # Integer is already "floored"
      num when is_integer(num) -> {:ok, num}
      num when is_float(num) -> {:ok, Float.floor(num) |> trunc()}
      # Convert to float first
      num when is_number(num) -> {:ok, Float.floor(num / 1) |> trunc()}
      _ -> {:error, "floor can only be applied to numbers"}
    end
  end

  @doc """
  Rounds a number to the nearest integer or specified decimal places.
  """
  def round(value, args) do
    case {value, args} do
      {num, []} when is_number(num) ->
        {:ok, Kernel.round(num)}

      {num, [precision]} when is_number(num) and is_integer(precision) and precision >= 0 ->
        {:ok, Float.round(num, precision)}

      {num, _} when is_number(num) ->
        {:ok, round(num)}

      _ ->
        {:error, "round can only be applied to numbers"}
    end
  end

  @doc """
  Returns the maximum value from a list or compares with another value.
  """
  def max_value(value, args) do
    case {value, args} do
      {list, []} when is_list(list) and list != [] ->
        case Enum.filter(list, &is_number/1) do
          [] -> {:error, "max requires at least one numeric value"}
          numbers -> {:ok, Enum.max(numbers)}
        end

      {num, [other]} when is_number(num) and is_number(other) ->
        {:ok, Kernel.max(num, other)}

      {[], _} ->
        {:error, "max cannot be applied to empty list"}

      _ ->
        {:error, "max can only be applied to numbers or lists of numbers"}
    end
  end

  @doc """
  Returns the minimum value from a list or compares with another value.
  """
  def min_value(value, args) do
    case {value, args} do
      {list, []} when is_list(list) and list != [] ->
        case Enum.filter(list, &is_number/1) do
          [] -> {:error, "min requires at least one numeric value"}
          numbers -> {:ok, Enum.min(numbers)}
        end

      {num, [other]} when is_number(num) and is_number(other) ->
        {:ok, Kernel.min(num, other)}

      {[], _} ->
        {:error, "min cannot be applied to empty list"}

      _ ->
        {:error, "min can only be applied to numbers or lists of numbers"}
    end
  end

  @doc """
  Raises a number to the specified power.
  """
  def power(value, args) do
    case {value, args} do
      {base, [exponent]} when is_number(base) and is_number(exponent) ->
        {:ok, :math.pow(base, exponent)}

      _ ->
        {:error, "power requires a base number and exponent"}
    end
  end

  @doc """
  Returns the square root of a number.
  """
  def sqrt(value, _args) do
    case value do
      num when is_number(num) and num >= 0 ->
        {:ok, :math.sqrt(num)}

      num when is_number(num) ->
        {:error, "sqrt cannot be applied to negative numbers"}

      _ ->
        {:error, "sqrt can only be applied to numbers"}
    end
  end

  @doc """
  Returns the remainder of integer division.
  """
  def mod(value, args) do
    case {value, args} do
      {dividend, [divisor]} when is_integer(dividend) and is_integer(divisor) and divisor != 0 ->
        {:ok, rem(dividend, divisor)}

      {_, [0]} ->
        {:error, "mod by zero is undefined"}

      _ ->
        {:error, "mod requires two integers"}
    end
  end

  @doc """
  Clamps a number between a minimum and maximum value.
  """
  def clamp(value, args) do
    case {value, args} do
      {num, [min_val, max_val]}
      when is_number(num) and is_number(min_val) and is_number(max_val) ->
        if min_val <= max_val do
          clamped = num |> Kernel.max(min_val) |> Kernel.min(max_val)
          {:ok, clamped}
        else
          {:error, "clamp min value must be less than or equal to max value"}
        end

      _ ->
        {:error, "clamp requires a number and min/max values"}
    end
  end
end
