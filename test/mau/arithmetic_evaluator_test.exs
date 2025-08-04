defmodule Mau.ArithmeticEvaluatorTest do
  use ExUnit.Case

  alias Mau.Renderer

  describe "Arithmetic Expression Evaluation" do
    test "evaluates simple addition" do
      ast = {:expression, [{:binary_op, ["+", {:literal, [2], []}, {:literal, [3], []}], []}], []}
      assert {:ok, "5"} = Renderer.render_node(ast, %{})
    end

    test "evaluates simple subtraction" do
      ast = {:expression, [{:binary_op, ["-", {:literal, [10], []}, {:literal, [3], []}], []}], []}
      assert {:ok, "7"} = Renderer.render_node(ast, %{})
    end

    test "evaluates simple multiplication" do
      ast = {:expression, [{:binary_op, ["*", {:literal, [4], []}, {:literal, [6], []}], []}], []}
      assert {:ok, "24"} = Renderer.render_node(ast, %{})
    end

    test "evaluates simple division" do
      ast = {:expression, [{:binary_op, ["/", {:literal, [15], []}, {:literal, [3], []}], []}], []}
      assert {:ok, "5.0"} = Renderer.render_node(ast, %{})
    end

    test "evaluates modulo operation" do
      ast = {:expression, [{:binary_op, ["%", {:literal, [10], []}, {:literal, [3], []}], []}], []}
      assert {:ok, "1"} = Renderer.render_node(ast, %{})
    end

    test "evaluates float arithmetic" do
      ast = {:expression, [{:binary_op, ["+", {:literal, [3.14], []}, {:literal, [2.86], []}], []}], []}
      assert {:ok, "6.0"} = Renderer.render_node(ast, %{})
      
      ast = {:expression, [{:binary_op, ["*", {:literal, [2.5], []}, {:literal, [4], []}], []}], []}
      assert {:ok, "10.0"} = Renderer.render_node(ast, %{})
    end

    test "evaluates string concatenation with +" do
      ast = {:expression, [{:binary_op, ["+", {:literal, ["hello"], []}, {:literal, [" world"], []}], []}], []}
      assert {:ok, "hello world"} = Renderer.render_node(ast, %{})
    end

    test "evaluates mixed type concatenation" do
      # String + number
      ast = {:expression, [{:binary_op, ["+", {:literal, ["count: "], []}, {:literal, [42], []}], []}], []}
      assert {:ok, "count: 42"} = Renderer.render_node(ast, %{})
      
      # Number + string
      ast = {:expression, [{:binary_op, ["+", {:literal, [42], []}, {:literal, [" items"], []}], []}], []}
      assert {:ok, "42 items"} = Renderer.render_node(ast, %{})
    end

    test "respects operator precedence in evaluation" do
      # 2 + 3 * 4 = 2 + 12 = 14
      ast = {:expression, [
        {:binary_op, ["+", 
          {:literal, [2], []}, 
          {:binary_op, ["*", {:literal, [3], []}, {:literal, [4], []}], []}
        ], []}
      ], []}
      assert {:ok, "14"} = Renderer.render_node(ast, %{})
    end

    test "evaluates left-associative operations correctly" do
      # 10 - 3 - 2 = (10 - 3) - 2 = 7 - 2 = 5
      ast = {:expression, [
        {:binary_op, ["-", 
          {:binary_op, ["-", {:literal, [10], []}, {:literal, [3], []}], []}, 
          {:literal, [2], []}
        ], []}
      ], []}
      assert {:ok, "5"} = Renderer.render_node(ast, %{})
    end

    test "evaluates parentheses correctly" do
      # (2 + 3) * 4 = 5 * 4 = 20
      ast = {:expression, [
        {:binary_op, ["*", 
          {:binary_op, ["+", {:literal, [2], []}, {:literal, [3], []}], []}, 
          {:literal, [4], []}
        ], []}
      ], []}
      assert {:ok, "20"} = Renderer.render_node(ast, %{})
    end

    test "evaluates variables in arithmetic expressions" do
      context = %{"x" => 10, "y" => 5}
      
      ast = {:expression, [
        {:binary_op, ["+", 
          {:variable, ["x"], []}, 
          {:variable, ["y"], []}
        ], []}
      ], []}
      assert {:ok, "15"} = Renderer.render_node(ast, context)
    end

    test "evaluates complex variable paths in arithmetic" do
      context = %{"user" => %{"age" => 25}}
      
      ast = {:expression, [
        {:binary_op, ["*", 
          {:variable, ["user", {:property, "age"}], []}, 
          {:literal, [2], []}
        ], []}
      ], []}
      assert {:ok, "50"} = Renderer.render_node(ast, context)
    end

    test "handles division by zero error" do
      ast = {:expression, [{:binary_op, ["/", {:literal, [10], []}, {:literal, [0], []}], []}], []}
      assert {:error, %Mau.Error{type: :runtime, message: "Division by zero"}} = 
        Renderer.render_node(ast, %{})
    end

    test "handles modulo by zero error" do
      ast = {:expression, [{:binary_op, ["%", {:literal, [10], []}, {:literal, [0], []}], []}], []}
      assert {:error, %Mau.Error{type: :runtime, message: "Modulo by zero"}} = 
        Renderer.render_node(ast, %{})
    end

    test "handles unsupported operations gracefully" do
      # String subtraction should fail
      ast = {:expression, [{:binary_op, ["-", {:literal, ["hello"], []}, {:literal, ["world"], []}], []}], []}
      assert {:error, %Mau.Error{type: :runtime}} = Renderer.render_node(ast, %{})
      
      # Modulo with floats should fail  
      ast = {:expression, [{:binary_op, ["%", {:literal, [10.5], []}, {:literal, [3.2], []}], []}], []}
      assert {:error, %Mau.Error{type: :runtime}} = Renderer.render_node(ast, %{})
    end

    test "handles undefined variables in arithmetic" do
      # Undefined variables should be treated as nil/empty, leading to conversion issues
      ast = {:expression, [
        {:binary_op, ["+", 
          {:variable, ["undefined"], []}, 
          {:literal, [5], []}
        ], []}
      ], []}
      # This should concatenate nil (empty string) with "5" = "5"
      assert {:ok, "5"} = Renderer.render_node(ast, %{})
    end

    test "evaluates complex nested arithmetic" do
      # ((2 + 3) * 4) / 2 = (5 * 4) / 2 = 20 / 2 = 10
      ast = {:expression, [
        {:binary_op, ["/", 
          {:binary_op, ["*", 
            {:binary_op, ["+", {:literal, [2], []}, {:literal, [3], []}], []}, 
            {:literal, [4], []}
          ], []}, 
          {:literal, [2], []}
        ], []}
      ], []}
      assert {:ok, "10.0"} = Renderer.render_node(ast, %{})
    end

    test "evaluates negative numbers in arithmetic" do
      # -5 + 10 = 5
      ast = {:expression, [
        {:binary_op, ["+", 
          {:literal, [-5], []}, 
          {:literal, [10], []}
        ], []}
      ], []}
      assert {:ok, "5"} = Renderer.render_node(ast, %{})
    end
  end
end