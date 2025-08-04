defmodule Mau.BooleanEvaluatorTest do
  use ExUnit.Case

  alias Mau.Renderer

  describe "Comparison Operation Evaluation" do
    test "evaluates equality operations" do
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, ["==", {:literal, [5], []}, {:literal, [5], []}], []}], []}, %{})
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:binary_op, ["==", {:literal, [5], []}, {:literal, [3], []}], []}], []}, %{})
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:binary_op, ["!=", {:literal, [5], []}, {:literal, [5], []}], []}], []}, %{})
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, ["!=", {:literal, [5], []}, {:literal, [3], []}], []}], []}, %{})
    end

    test "evaluates string equality" do
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, ["==", {:literal, ["hello"], []}, {:literal, ["hello"], []}], []}], []}, %{})
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:binary_op, ["==", {:literal, ["hello"], []}, {:literal, ["world"], []}], []}], []}, %{})
    end

    test "evaluates mixed type equality" do
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:binary_op, ["==", {:literal, [5], []}, {:literal, ["5"], []}], []}], []}, %{})
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, ["!=", {:literal, [5], []}, {:literal, ["5"], []}], []}], []}, %{})
    end

    test "evaluates numerical relational operations" do
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, [">", {:literal, [5], []}, {:literal, [3], []}], []}], []}, %{})
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:binary_op, [">", {:literal, [3], []}, {:literal, [5], []}], []}], []}, %{})
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, [">=", {:literal, [5], []}, {:literal, [5], []}], []}], []}, %{})
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, [">=", {:literal, [5], []}, {:literal, [3], []}], []}], []}, %{})
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:binary_op, ["<", {:literal, [5], []}, {:literal, [3], []}], []}], []}, %{})
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, ["<", {:literal, [3], []}, {:literal, [5], []}], []}], []}, %{})
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, ["<=", {:literal, [5], []}, {:literal, [5], []}], []}], []}, %{})
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, ["<=", {:literal, [3], []}, {:literal, [5], []}], []}], []}, %{})
    end

    test "evaluates float relational operations" do
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, [">", {:literal, [3.14], []}, {:literal, [2.71], []}], []}], []}, %{})
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:binary_op, [">", {:literal, [2.71], []}, {:literal, [3.14], []}], []}], []}, %{})
    end

    test "evaluates string relational operations" do
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, ["<", {:literal, ["apple"], []}, {:literal, ["banana"], []}], []}], []}, %{})
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:binary_op, [">", {:literal, ["apple"], []}, {:literal, ["banana"], []}], []}], []}, %{})
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, [">=", {:literal, ["apple"], []}, {:literal, ["apple"], []}], []}], []}, %{})
    end

    test "handles comparison with variables" do
      context = %{"age" => 25, "name" => "Alice"}
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, [">", {:variable, ["age"], []}, {:literal, [18], []}], []}], []}, context)
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:binary_op, ["<", {:variable, ["age"], []}, {:literal, [18], []}], []}], []}, context)
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, ["==", {:variable, ["name"], []}, {:literal, ["Alice"], []}], []}], []}, context)
    end

    test "handles comparison with nil values" do
      context = %{"value" => nil}
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, ["==", {:variable, ["value"], []}, {:literal, [nil], []}], []}], []}, context)
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:binary_op, ["==", {:variable, ["undefined"], []}, {:literal, [nil], []}], []}], []}, context)
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:binary_op, ["!=", {:variable, ["value"], []}, {:literal, [nil], []}], []}], []}, context)
    end

    test "returns error for unsupported relational operations" do
      assert {:error, %Mau.Error{type: :runtime}} = 
        Renderer.render_node({:expression, [{:binary_op, [">", {:literal, ["hello"], []}, {:literal, [5], []}], []}], []}, %{})
      assert {:error, %Mau.Error{type: :runtime}} = 
        Renderer.render_node({:expression, [{:binary_op, ["<", {:literal, [5], []}, {:literal, [true], []}], []}], []}, %{})
    end
  end

  describe "Logical Operation Evaluation" do
    test "evaluates AND operations with short-circuiting" do
      # True AND True = True
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [true], []}, {:literal, [true], []}], []}], []}, %{})
      
      # True AND False = False
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [true], []}, {:literal, [false], []}], []}], []}, %{})
      
      # False AND True = False (short-circuits)
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [false], []}, {:literal, [true], []}], []}], []}, %{})
      
      # False AND False = False
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [false], []}, {:literal, [false], []}], []}], []}, %{})
    end

    test "evaluates OR operations with short-circuiting" do
      # True OR True = True (short-circuits)
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:logical_op, ["or", {:literal, [true], []}, {:literal, [true], []}], []}], []}, %{})
      
      # True OR False = True (short-circuits)
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:logical_op, ["or", {:literal, [true], []}, {:literal, [false], []}], []}], []}, %{})
      
      # False OR True = True
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:logical_op, ["or", {:literal, [false], []}, {:literal, [true], []}], []}], []}, %{})
      
      # False OR False = False
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:logical_op, ["or", {:literal, [false], []}, {:literal, [false], []}], []}], []}, %{})
    end

    test "handles truthiness evaluation correctly" do
      # Truthy values
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [1], []}, {:literal, [true], []}], []}], []}, %{})
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, ["hello"], []}, {:literal, [true], []}], []}], []}, %{})
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [[1, 2]], []}, {:literal, [true], []}], []}], []}, %{})
      
      # Falsy values
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [0], []}, {:literal, [true], []}], []}], []}, %{})
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [""], []}, {:literal, [true], []}], []}], []}, %{})
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [nil], []}, {:literal, [true], []}], []}], []}, %{})
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [[]], []}, {:literal, [true], []}], []}], []}, %{})
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [%{}], []}, {:literal, [true], []}], []}], []}, %{})
    end

    test "handles float zero correctly in truthiness" do
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [0.0], []}, {:literal, [true], []}], []}], []}, %{})
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:literal, [0.1], []}, {:literal, [true], []}], []}], []}, %{})
    end

    test "combines logical operations with variables" do
      context = %{"is_admin" => true, "is_active" => false, "age" => 25}
      
      assert {:ok, "false"} = Renderer.render_node({:expression, [{:logical_op, ["and", {:variable, ["is_admin"], []}, {:variable, ["is_active"], []}], []}], []}, context)
      assert {:ok, "true"} = Renderer.render_node({:expression, [{:logical_op, ["or", {:variable, ["is_admin"], []}, {:variable, ["is_active"], []}], []}], []}, context)
    end

    test "handles errors in logical operations" do
      # Error in left operand should propagate
      assert {:error, %Mau.Error{type: :runtime}} = 
        Renderer.render_node({:expression, [{:logical_op, ["and", {:binary_op, ["/", {:literal, [5], []}, {:literal, [0], []}], []}, {:literal, [true], []}], []}], []}, %{})
    end
  end

  describe "Complex Boolean Expressions" do
    test "evaluates nested boolean expressions" do
      # (5 > 3) AND (2 < 4) = True AND True = True
      nested_expr = {:logical_op, ["and",
        {:binary_op, [">", {:literal, [5], []}, {:literal, [3], []}], []},
        {:binary_op, ["<", {:literal, [2], []}, {:literal, [4], []}], []}
      ], []}
      assert {:ok, "true"} = Renderer.render_node({:expression, [nested_expr], []}, %{})
      
      # (5 < 3) OR (2 < 4) = False OR True = True
      nested_expr = {:logical_op, ["or",
        {:binary_op, ["<", {:literal, [5], []}, {:literal, [3], []}], []},
        {:binary_op, ["<", {:literal, [2], []}, {:literal, [4], []}], []}
      ], []}
      assert {:ok, "true"} = Renderer.render_node({:expression, [nested_expr], []}, %{})
    end

    test "evaluates expressions with mixed arithmetic and boolean operations" do
      context = %{"x" => 10, "y" => 5}
      
      # (x + y) > 12 AND x > y = 15 > 12 AND 10 > 5 = True AND True = True
      mixed_expr = {:logical_op, ["and",
        {:binary_op, [">", 
          {:binary_op, ["+", {:variable, ["x"], []}, {:variable, ["y"], []}], []},
          {:literal, [12], []}
        ], []},
        {:binary_op, [">", {:variable, ["x"], []}, {:variable, ["y"], []}], []}
      ], []}
      assert {:ok, "true"} = Renderer.render_node({:expression, [mixed_expr], []}, context)
    end

    test "handles operator precedence correctly in evaluation" do
      # This tests that the parser created the correct precedence structure
      # 2 + 3 > 4 should be parsed as (2 + 3) > 4, not 2 + (3 > 4)
      
      # 2 + 3 > 4 = 5 > 4 = True
      precedence_expr = {:binary_op, [">",
        {:binary_op, ["+", {:literal, [2], []}, {:literal, [3], []}], []},
        {:literal, [4], []}
      ], []}
      assert {:ok, "true"} = Renderer.render_node({:expression, [precedence_expr], []}, %{})
    end
  end
end