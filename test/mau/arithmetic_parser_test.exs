defmodule Mau.ArithmeticParserTest do
  use ExUnit.Case

  alias Mau.Parser

  describe "Arithmetic Expression Parsing" do
    test "parses simple addition" do
      assert {:ok, {:expression, [{:binary_op, ["+", {:literal, [2], []}, {:literal, [3], []}], []}], []}} = 
        Parser.parse_expression_block("{{ 2 + 3 }}")
    end

    test "parses simple subtraction" do
      assert {:ok, {:expression, [{:binary_op, ["-", {:literal, [5], []}, {:literal, [2], []}], []}], []}} = 
        Parser.parse_expression_block("{{ 5 - 2 }}")
    end

    test "parses simple multiplication" do
      assert {:ok, {:expression, [{:binary_op, ["*", {:literal, [4], []}, {:literal, [6], []}], []}], []}} = 
        Parser.parse_expression_block("{{ 4 * 6 }}")
    end

    test "parses simple division" do
      assert {:ok, {:expression, [{:binary_op, ["/", {:literal, [8], []}, {:literal, [2], []}], []}], []}} = 
        Parser.parse_expression_block("{{ 8 / 2 }}")
    end

    test "parses modulo operation" do
      assert {:ok, {:expression, [{:binary_op, ["%", {:literal, [10], []}, {:literal, [3], []}], []}], []}} = 
        Parser.parse_expression_block("{{ 10 % 3 }}")
    end

    test "handles operator precedence - multiplication before addition" do
      # 2 + 3 * 4 should parse as 2 + (3 * 4)
      expected = {:expression, [
        {:binary_op, ["+", 
          {:literal, [2], []}, 
          {:binary_op, ["*", {:literal, [3], []}, {:literal, [4], []}], []}
        ], []}
      ], []}
      assert {:ok, expected} = Parser.parse_expression_block("{{ 2 + 3 * 4 }}")
    end

    test "handles operator precedence - division before subtraction" do
      # 10 - 8 / 2 should parse as 10 - (8 / 2)
      expected = {:expression, [
        {:binary_op, ["-", 
          {:literal, [10], []}, 
          {:binary_op, ["/", {:literal, [8], []}, {:literal, [2], []}], []}
        ], []}
      ], []}
      assert {:ok, expected} = Parser.parse_expression_block("{{ 10 - 8 / 2 }}")
    end

    test "handles left associativity for same precedence operators" do
      # 10 - 3 - 2 should parse as (10 - 3) - 2
      expected = {:expression, [
        {:binary_op, ["-", 
          {:binary_op, ["-", {:literal, [10], []}, {:literal, [3], []}], []}, 
          {:literal, [2], []}
        ], []}
      ], []}
      assert {:ok, expected} = Parser.parse_expression_block("{{ 10 - 3 - 2 }}")
    end

    test "handles parentheses for precedence override" do
      # (2 + 3) * 4 should parse as (2 + 3) * 4
      expected = {:expression, [
        {:binary_op, ["*", 
          {:binary_op, ["+", {:literal, [2], []}, {:literal, [3], []}], []}, 
          {:literal, [4], []}
        ], []}
      ], []}
      assert {:ok, expected} = Parser.parse_expression_block("{{ (2 + 3) * 4 }}")
    end

    test "handles nested parentheses" do
      # ((2 + 3) * 4) / 2
      expected = {:expression, [
        {:binary_op, ["/", 
          {:binary_op, ["*", 
            {:binary_op, ["+", {:literal, [2], []}, {:literal, [3], []}], []}, 
            {:literal, [4], []}
          ], []}, 
          {:literal, [2], []}
        ], []}
      ], []}
      assert {:ok, expected} = Parser.parse_expression_block("{{ ((2 + 3) * 4) / 2 }}")
    end

    test "handles whitespace variations in arithmetic expressions" do
      # No spaces
      assert {:ok, {:expression, [{:binary_op, ["+", {:literal, [1], []}, {:literal, [2], []}], []}], []}} = 
        Parser.parse_expression_block("{{1+2}}")
      
      # Multiple spaces
      assert {:ok, {:expression, [{:binary_op, ["+", {:literal, [1], []}, {:literal, [2], []}], []}], []}} = 
        Parser.parse_expression_block("{{  1   +   2  }}")
    end

    test "works with variables in arithmetic expressions" do
      expected = {:expression, [
        {:binary_op, ["+", 
          {:variable, ["x"], []}, 
          {:literal, [5], []}
        ], []}
      ], []}
      assert {:ok, expected} = Parser.parse_expression_block("{{ x + 5 }}")
    end

    test "works with complex variable paths in arithmetic" do
      expected = {:expression, [
        {:binary_op, ["*", 
          {:variable, ["user", {:property, "age"}], []}, 
          {:literal, [2], []}
        ], []}
      ], []}
      assert {:ok, expected} = Parser.parse_expression_block("{{ user.age * 2 }}")
    end

    test "works with string literals and addition (concatenation)" do
      expected = {:expression, [
        {:binary_op, ["+", 
          {:literal, ["hello"], []}, 
          {:literal, [" world"], []}
        ], []}
      ], []}
      assert {:ok, expected} = Parser.parse_expression_block(~s({{ "hello" + " world" }}))
    end

    test "handles float numbers in arithmetic" do
      expected = {:expression, [
        {:binary_op, ["+", 
          {:literal, [3.14], []}, 
          {:literal, [2.86], []}
        ], []}
      ], []}
      assert {:ok, expected} = Parser.parse_expression_block("{{ 3.14 + 2.86 }}")
    end

    test "handles negative numbers correctly" do
      # Negative numbers should be parsed as literals, not unary operations
      expected = {:expression, [
        {:binary_op, ["+", 
          {:literal, [-5], []}, 
          {:literal, [10], []}
        ], []}
      ], []}
      assert {:ok, expected} = Parser.parse_expression_block("{{ -5 + 10 }}")
    end

    test "fails on malformed arithmetic expressions" do
      # Missing operand
      assert {:error, _} = Parser.parse_expression_block("{{ 5 + }}")
      assert {:error, _} = Parser.parse_expression_block("{{ + 5 }}")
      
      # Unmatched parentheses
      assert {:error, _} = Parser.parse_expression_block("{{ (5 + 3 }}")
      assert {:error, _} = Parser.parse_expression_block("{{ 5 + 3) }}")
    end
  end
end