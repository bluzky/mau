defmodule Mau.Filters.MathTest do
  use ExUnit.Case, async: true

  alias Mau.Filters.Math

  describe "abs/2" do
    test "returns absolute value of negative integer" do
      assert {:ok, 5} = Math.abs(-5, [])
    end

    test "returns absolute value of negative float" do
      assert {:ok, 3.7} = Math.abs(-3.7, [])
    end

    test "returns positive integer unchanged" do
      assert {:ok, 3} = Math.abs(3, [])
    end

    test "returns zero unchanged" do
      assert {:ok, 0} = Math.abs(0, [])
    end

    test "errors on non-number" do
      assert {:error, msg} = Math.abs("hello", [])
      assert msg =~ "abs can only be applied to numbers"
    end

    test "errors on nil" do
      assert {:error, _} = Math.abs(nil, [])
    end
  end

  describe "ceil/2" do
    test "rounds up a float" do
      assert {:ok, 4} = Math.ceil(3.2, [])
    end

    test "rounds up a float near the ceiling" do
      assert {:ok, 4} = Math.ceil(3.9, [])
    end

    test "returns integer unchanged" do
      assert {:ok, 5} = Math.ceil(5, [])
    end

    test "rounds up negative float toward zero" do
      assert {:ok, -3} = Math.ceil(-3.7, [])
    end

    test "errors on non-number" do
      assert {:error, msg} = Math.ceil("x", [])
      assert msg =~ "ceil can only be applied to numbers"
    end
  end

  describe "floor/2" do
    test "rounds down a float" do
      assert {:ok, 3} = Math.floor(3.7, [])
    end

    test "rounds down a float near the floor" do
      assert {:ok, 3} = Math.floor(3.1, [])
    end

    test "returns integer unchanged" do
      assert {:ok, 5} = Math.floor(5, [])
    end

    test "rounds down negative float away from zero" do
      assert {:ok, -4} = Math.floor(-3.2, [])
    end

    test "errors on non-number" do
      assert {:error, msg} = Math.floor("x", [])
      assert msg =~ "floor can only be applied to numbers"
    end
  end

  describe "round/2" do
    test "rounds float to nearest integer" do
      assert {:ok, 4} = Math.round(3.5, [])
    end

    test "rounds down when below .5" do
      assert {:ok, 3} = Math.round(3.4, [])
    end

    test "returns integer unchanged" do
      assert {:ok, 5} = Math.round(5, [])
    end

    test "rounds to specified decimal places" do
      assert {:ok, 3.14} = Math.round(3.14159, [2])
    end

    test "rounds integer to specified decimal places returns float" do
      assert {:ok, 5.0} = Math.round(5, [2])
    end

    test "rounds with precision 0 returns float" do
      assert {:ok, 4.0} = Math.round(3.6, [0])
    end

    test "errors on non-number" do
      assert {:error, msg} = Math.round("x", [])
      assert msg =~ "round can only be applied to numbers"
    end
  end

  describe "mod/2" do
    test "returns remainder of integer division" do
      assert {:ok, 1} = Math.mod(10, [3])
    end

    test "returns zero when evenly divisible" do
      assert {:ok, 0} = Math.mod(10, [5])
    end

    test "works with negative dividend" do
      assert {:ok, -1} = Math.mod(-7, [3])
    end

    test "errors on division by zero" do
      assert {:error, msg} = Math.mod(5, [0])
      assert msg =~ "mod by zero"
    end

    test "errors on float dividend" do
      assert {:error, msg} = Math.mod(5.5, [2])
      assert msg =~ "mod requires two integers"
    end

    test "errors on float divisor" do
      assert {:error, msg} = Math.mod(5, [2.0])
      assert msg =~ "mod requires two integers"
    end
  end

  describe "power/2" do
    test "raises integer to integer power" do
      assert {:ok, 8.0} = Math.power(2, [3])
    end

    test "raises to power of zero" do
      assert {:ok, 1.0} = Math.power(5, [0])
    end

    test "raises to fractional power" do
      assert {:ok, result} = Math.power(4, [0.5])
      assert_in_delta result, 2.0, 0.0001
    end

    test "raises float base" do
      assert {:ok, result} = Math.power(2.0, [3])
      assert_in_delta result, 8.0, 0.0001
    end

    test "errors without exponent" do
      assert {:error, msg} = Math.power(2, [])
      assert msg =~ "power requires a base number and exponent"
    end
  end

  describe "sqrt/2" do
    test "returns square root of perfect square" do
      assert {:ok, 3.0} = Math.sqrt(9, [])
    end

    test "returns square root of float" do
      assert {:ok, result} = Math.sqrt(2.0, [])
      assert_in_delta result, 1.4142, 0.001
    end

    test "returns zero for zero" do
      assert {:ok, 0.0} = Math.sqrt(0, [])
    end

    test "errors on negative number" do
      assert {:error, msg} = Math.sqrt(-1, [])
      assert msg =~ "sqrt cannot be applied to negative numbers"
    end

    test "errors on non-number" do
      assert {:error, msg} = Math.sqrt("x", [])
      assert msg =~ "sqrt can only be applied to numbers"
    end
  end

  describe "max_value/2" do
    test "returns max from list" do
      assert {:ok, 5} = Math.max_value([1, 5, 3, 2], [])
    end

    test "returns max of two numbers" do
      assert {:ok, 7} = Math.max_value(3, [7])
    end

    test "returns value when it is already max" do
      assert {:ok, 9} = Math.max_value(9, [3])
    end

    test "errors on empty list" do
      assert {:error, msg} = Math.max_value([], [])
      assert msg =~ "max cannot be applied to empty list"
    end

    test "filters non-numeric values from list" do
      assert {:ok, 5} = Math.max_value([1, 5, 3], [])
    end

    test "errors when list has no numeric values" do
      assert {:error, msg} = Math.max_value(["a", "b"], [])
      assert msg =~ "max requires at least one numeric value"
    end
  end

  describe "min_value/2" do
    test "returns min from list" do
      assert {:ok, 1} = Math.min_value([1, 5, 3, 2], [])
    end

    test "returns min of two numbers" do
      assert {:ok, 3} = Math.min_value(3, [7])
    end

    test "returns value when it is already min" do
      assert {:ok, 1} = Math.min_value(1, [9])
    end

    test "errors on empty list" do
      assert {:error, msg} = Math.min_value([], [])
      assert msg =~ "min cannot be applied to empty list"
    end

    test "errors when list has no numeric values" do
      assert {:error, msg} = Math.min_value(["a", "b"], [])
      assert msg =~ "min requires at least one numeric value"
    end
  end

  describe "trunc/2" do
    test "truncates positive float toward zero" do
      assert {:ok, 3} = Math.trunc(3.9, [])
    end

    test "truncates negative float toward zero" do
      assert {:ok, -3} = Math.trunc(-3.9, [])
    end

    test "returns integer unchanged" do
      assert {:ok, 5} = Math.trunc(5, [])
    end

    test "returns zero for 0.0" do
      assert {:ok, 0} = Math.trunc(0.0, [])
    end

    test "errors on non-number" do
      assert {:error, msg} = Math.trunc("x", [])
      assert msg =~ "trunc can only be applied to numbers"
    end
  end

  describe "div/2" do
    test "returns integer quotient" do
      assert {:ok, 3} = Math.div(10, [3])
    end

    test "returns zero when dividend smaller than divisor" do
      assert {:ok, 0} = Math.div(2, [5])
    end

    test "truncates toward zero for negative dividend" do
      assert {:ok, -3} = Math.div(-10, [3])
    end

    test "truncates toward zero for negative divisor" do
      assert {:ok, -3} = Math.div(10, [-3])
    end

    test "returns exact result when evenly divisible" do
      assert {:ok, 5} = Math.div(10, [2])
    end

    test "errors on division by zero" do
      assert {:error, msg} = Math.div(10, [0])
      assert msg =~ "div by zero is undefined"
    end

    test "errors on float dividend" do
      assert {:error, msg} = Math.div(10.5, [3])
      assert msg =~ "div requires two integers"
    end

    test "errors on float divisor" do
      assert {:error, msg} = Math.div(10, [3.0])
      assert msg =~ "div requires two integers"
    end
  end

  describe "add/2" do
    test "adds two integers" do
      assert {:ok, 8} = Math.add(5, [3])
    end

    test "adds negative number" do
      assert {:ok, 2} = Math.add(5, [-3])
    end

    test "adds floats" do
      assert {:ok, result} = Math.add(1.5, [2.5])
      assert_in_delta result, 4.0, 0.0001
    end

    test "errors on non-number value" do
      assert {:error, msg} = Math.add("x", [3])
      assert msg =~ "add requires two numbers"
    end

    test "errors on non-number argument" do
      assert {:error, msg} = Math.add(5, ["x"])
      assert msg =~ "add requires two numbers"
    end
  end

  describe "sub/2" do
    test "subtracts two integers" do
      assert {:ok, 2} = Math.sub(5, [3])
    end

    test "subtracts to negative result" do
      assert {:ok, -2} = Math.sub(3, [5])
    end

    test "subtracts floats" do
      assert {:ok, result} = Math.sub(2.5, [1.0])
      assert_in_delta result, 1.5, 0.0001
    end

    test "errors on non-number value" do
      assert {:error, msg} = Math.sub("x", [3])
      assert msg =~ "sub requires two numbers"
    end

    test "errors on non-number argument" do
      assert {:error, msg} = Math.sub(5, ["x"])
      assert msg =~ "sub requires two numbers"
    end
  end

  describe "mul/2" do
    test "multiplies two integers" do
      assert {:ok, 15} = Math.mul(5, [3])
    end

    test "multiplies by zero" do
      assert {:ok, 0} = Math.mul(5, [0])
    end

    test "multiplies floats" do
      assert {:ok, result} = Math.mul(1.5, [2.0])
      assert_in_delta result, 3.0, 0.0001
    end

    test "errors on non-number value" do
      assert {:error, msg} = Math.mul("x", [3])
      assert msg =~ "mul requires two numbers"
    end

    test "errors on non-number argument" do
      assert {:error, msg} = Math.mul(5, ["x"])
      assert msg =~ "mul requires two numbers"
    end
  end

  describe "clamp/2" do
    test "returns value when within range" do
      assert {:ok, 5} = Math.clamp(5, [0, 10])
    end

    test "clamps to max when above range" do
      assert {:ok, 10} = Math.clamp(15, [0, 10])
    end

    test "clamps to min when below range" do
      assert {:ok, 0} = Math.clamp(-5, [0, 10])
    end

    test "works with float values" do
      assert {:ok, 1.5} = Math.clamp(1.5, [0.0, 2.0])
    end

    test "accepts equal min and max" do
      assert {:ok, 5} = Math.clamp(5, [5, 5])
    end

    test "errors when min greater than max" do
      assert {:error, msg} = Math.clamp(5, [10, 0])
      assert msg =~ "clamp min value must be less than or equal to max value"
    end

    test "errors on non-number value" do
      assert {:error, msg} = Math.clamp("x", [0, 10])
      assert msg =~ "clamp requires a number and min/max values"
    end
  end
end
