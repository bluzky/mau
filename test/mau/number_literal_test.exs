defmodule Mau.NumberLiteralTest do
  use ExUnit.Case

  alias Mau.Parser

  describe "Number Literal Parsing" do
    test "parses positive integers" do
      assert {:ok, {:literal, [0], []}} = Parser.parse_number_literal("0")
      assert {:ok, {:literal, [42], []}} = Parser.parse_number_literal("42")
      assert {:ok, {:literal, [123], []}} = Parser.parse_number_literal("123")
      assert {:ok, {:literal, [999999], []}} = Parser.parse_number_literal("999999")
    end

    test "parses negative integers" do
      assert {:ok, {:literal, [-42], []}} = Parser.parse_number_literal("-42")
      assert {:ok, {:literal, [-123], []}} = Parser.parse_number_literal("-123")
      assert {:ok, {:literal, [-999999], []}} = Parser.parse_number_literal("-999999")
    end

    test "parses positive floats" do
      assert {:ok, {:literal, [3.14], []}} = Parser.parse_number_literal("3.14")
      assert {:ok, {:literal, [0.5], []}} = Parser.parse_number_literal("0.5")
      assert {:ok, {:literal, [123.456], []}} = Parser.parse_number_literal("123.456")
      {:ok, {:literal, [zero_float], []}} = Parser.parse_number_literal("0.0")
      assert zero_float == 0.0
    end

    test "parses negative floats" do
      assert {:ok, {:literal, [-3.14], []}} = Parser.parse_number_literal("-3.14")
      assert {:ok, {:literal, [-0.5], []}} = Parser.parse_number_literal("-0.5")
      assert {:ok, {:literal, [-123.456], []}} = Parser.parse_number_literal("-123.456")
    end

    test "parses scientific notation with positive exponent" do
      assert {:ok, {:literal, [1.0e3], []}} = Parser.parse_number_literal("1e3")
      assert {:ok, {:literal, [1.0e3], []}} = Parser.parse_number_literal("1E3")
      assert {:ok, {:literal, [1.0e3], []}} = Parser.parse_number_literal("1e+3")
      assert {:ok, {:literal, [2.5e10], []}} = Parser.parse_number_literal("2.5e10")
    end

    test "parses scientific notation with negative exponent" do
      assert {:ok, {:literal, [1.0e-3], []}} = Parser.parse_number_literal("1e-3")
      assert {:ok, {:literal, [1.0e-3], []}} = Parser.parse_number_literal("1E-3")
      assert {:ok, {:literal, [2.5e-10], []}} = Parser.parse_number_literal("2.5e-10")
    end

    test "parses negative scientific notation" do
      assert {:ok, {:literal, [-1.0e3], []}} = Parser.parse_number_literal("-1e3")
      assert {:ok, {:literal, [-2.5e-10], []}} = Parser.parse_number_literal("-2.5e-10")
    end

    test "fails on invalid number formats" do
      assert {:error, _} = Parser.parse_number_literal("01")  # Leading zero
      assert {:error, _} = Parser.parse_number_literal("3.")   # Trailing dot without digits
      assert {:error, _} = Parser.parse_number_literal(".5")   # No integer part
      assert {:error, _} = Parser.parse_number_literal("1e")   # No exponent digits
      assert {:error, _} = Parser.parse_number_literal("1e+")  # No exponent digits after sign
      assert {:error, _} = Parser.parse_number_literal("--1")  # Double negative
      assert {:error, _} = Parser.parse_number_literal("abc")  # Non-numeric
    end

    test "fails on numbers with extra characters" do
      assert {:error, _} = Parser.parse_number_literal("42x")
      assert {:error, _} = Parser.parse_number_literal("3.14abc")
    end

    test "handles edge cases" do
      # Very large numbers
      assert {:ok, {:literal, [999999999999999999], []}} = Parser.parse_number_literal("999999999999999999")
      
      # Very small floats
      assert {:ok, {:literal, [0.000001], []}} = Parser.parse_number_literal("0.000001")
      assert {:ok, {:literal, [1.0e-300], []}} = Parser.parse_number_literal("1e-300")
      
      # Very large scientific notation
      assert {:ok, {:literal, [1.0e300], []}} = Parser.parse_number_literal("1e300")
    end
  end
end