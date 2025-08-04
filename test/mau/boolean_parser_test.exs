defmodule Mau.BooleanParserTest do
  use ExUnit.Case

  alias Mau.Parser

  describe "Comparison Expression Parsing" do
    test "parses equality expressions" do
      {:ok, ast} = Parser.parse("{{ 5 == 5 }}")
      expected_expression = {:binary_op, ["==", {:literal, [5], []}, {:literal, [5], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast

      {:ok, ast} = Parser.parse("{{ 5 != 3 }}")
      expected_expression = {:binary_op, ["!=", {:literal, [5], []}, {:literal, [3], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "parses relational expressions" do
      {:ok, ast} = Parser.parse("{{ 5 > 3 }}")
      expected_expression = {:binary_op, [">", {:literal, [5], []}, {:literal, [3], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast

      {:ok, ast} = Parser.parse("{{ 3 < 5 }}")
      expected_expression = {:binary_op, ["<", {:literal, [3], []}, {:literal, [5], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast

      {:ok, ast} = Parser.parse("{{ 5 >= 5 }}")
      expected_expression = {:binary_op, [">=", {:literal, [5], []}, {:literal, [5], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast

      {:ok, ast} = Parser.parse("{{ 3 <= 5 }}")
      expected_expression = {:binary_op, ["<=", {:literal, [3], []}, {:literal, [5], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "parses string comparisons" do
      {:ok, ast} = Parser.parse(~s({{ "apple" < "banana" }}))
      expected_expression = {:binary_op, ["<", {:literal, ["apple"], []}, {:literal, ["banana"], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast

      {:ok, ast} = Parser.parse(~s({{ "hello" == "hello" }}))
      expected_expression = {:binary_op, ["==", {:literal, ["hello"], []}, {:literal, ["hello"], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "parses logical expressions" do
      {:ok, ast} = Parser.parse("{{ true and false }}")
      expected_expression = {:logical_op, ["and", {:literal, [true], []}, {:literal, [false], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast

      {:ok, ast} = Parser.parse("{{ true or false }}")
      expected_expression = {:logical_op, ["or", {:literal, [true], []}, {:literal, [false], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "handles precedence correctly" do
      # Arithmetic before comparison
      {:ok, ast} = Parser.parse("{{ 2 + 3 > 4 }}")
      expected_expression = {:binary_op, [">", 
        {:binary_op, ["+", {:literal, [2], []}, {:literal, [3], []}], []},
        {:literal, [4], []}
      ], []}
      assert [{:expression, [^expected_expression], []}] = ast

      # Comparison before logical
      {:ok, ast} = Parser.parse("{{ 5 > 3 and 2 < 4 }}")
      expected_expression = {:logical_op, ["and",
        {:binary_op, [">", {:literal, [5], []}, {:literal, [3], []}], []},
        {:binary_op, ["<", {:literal, [2], []}, {:literal, [4], []}], []}
      ], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "handles logical operator precedence" do
      # AND has higher precedence than OR
      {:ok, ast} = Parser.parse("{{ true or false and true }}")
      expected_expression = {:logical_op, ["or",
        {:literal, [true], []},
        {:logical_op, ["and", {:literal, [false], []}, {:literal, [true], []}], []}
      ], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "handles complex nested expressions" do
      {:ok, ast} = Parser.parse("{{ (5 > 3 and 2 < 4) or false }}")
      expected_inner = {:logical_op, ["and",
        {:binary_op, [">", {:literal, [5], []}, {:literal, [3], []}], []},
        {:binary_op, ["<", {:literal, [2], []}, {:literal, [4], []}], []}
      ], []}
      expected_expression = {:logical_op, ["or", expected_inner, {:literal, [false], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "parses comparisons with variables" do
      {:ok, ast} = Parser.parse("{{ age > 18 }}")
      expected_expression = {:binary_op, [">", {:variable, ["age"], []}, {:literal, [18], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast

      {:ok, ast} = Parser.parse("{{ user.name == \"Alice\" }}")
      expected_expression = {:binary_op, ["==", 
        {:variable, ["user", {:property, "name"}], []},
        {:literal, ["Alice"], []}
      ], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "handles whitespace around operators" do
      {:ok, ast} = Parser.parse("{{ 5>3 }}")
      expected_expression = {:binary_op, [">", {:literal, [5], []}, {:literal, [3], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast

      {:ok, ast} = Parser.parse("{{ true   and   false }}")
      expected_expression = {:logical_op, ["and", {:literal, [true], []}, {:literal, [false], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "parses left-associative operations" do
      {:ok, ast} = Parser.parse("{{ true and false and true }}")
      expected_inner = {:logical_op, ["and", {:literal, [true], []}, {:literal, [false], []}], []}
      expected_expression = {:logical_op, ["and", expected_inner, {:literal, [true], []}], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "combines all expression types" do
      {:ok, ast} = Parser.parse("{{ (x + 5) * 2 >= threshold and status == \"active\" }}")
      
      # Should parse correctly with proper precedence
      assert [{:expression, [expression], []}] = ast
      assert {:logical_op, ["and", left_side, right_side], []} = expression
      
      # Left side: (x + 5) * 2 >= threshold
      assert {:binary_op, [">=", _arithmetic_expr, {:variable, ["threshold"], []}], []} = left_side
      
      # Right side: status == "active"
      assert {:binary_op, ["==", {:variable, ["status"], []}, {:literal, ["active"], []}], []} = right_side
    end
  end
end