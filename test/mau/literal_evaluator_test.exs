defmodule Mau.LiteralEvaluatorTest do
  use ExUnit.Case

  alias Mau.Renderer

  describe "Literal Expression Evaluation" do
    test "evaluates string literals" do
      ast = {:expression, [{:literal, ["hello"], []}], []}
      assert {:ok, "hello"} = Renderer.render_node(ast, %{})
      
      ast = {:expression, [{:literal, ["world"], []}], []}
      assert {:ok, "world"} = Renderer.render_node(ast, %{})
      
      # Empty string
      ast = {:expression, [{:literal, [""], []}], []}
      assert {:ok, ""} = Renderer.render_node(ast, %{})
    end

    test "evaluates integer literals" do
      ast = {:expression, [{:literal, [42], []}], []}
      assert {:ok, "42"} = Renderer.render_node(ast, %{})
      
      ast = {:expression, [{:literal, [0], []}], []}
      assert {:ok, "0"} = Renderer.render_node(ast, %{})
      
      ast = {:expression, [{:literal, [-123], []}], []}
      assert {:ok, "-123"} = Renderer.render_node(ast, %{})
    end

    test "evaluates float literals" do
      ast = {:expression, [{:literal, [3.14], []}], []}
      assert {:ok, "3.14"} = Renderer.render_node(ast, %{})
      
      ast = {:expression, [{:literal, [0.0], []}], []}
      assert {:ok, "0.0"} = Renderer.render_node(ast, %{})
      
      ast = {:expression, [{:literal, [-2.5], []}], []}
      assert {:ok, "-2.5"} = Renderer.render_node(ast, %{})
      
      # Scientific notation
      ast = {:expression, [{:literal, [1.0e3], []}], []}
      assert {:ok, "1.0e3"} = Renderer.render_node(ast, %{})
      
      ast = {:expression, [{:literal, [1.5e-2], []}], []}
      assert {:ok, "0.015"} = Renderer.render_node(ast, %{})
    end

    test "evaluates boolean literals" do
      ast = {:expression, [{:literal, [true], []}], []}
      assert {:ok, "true"} = Renderer.render_node(ast, %{})
      
      ast = {:expression, [{:literal, [false], []}], []}
      assert {:ok, "false"} = Renderer.render_node(ast, %{})
    end

    test "evaluates null literals" do
      ast = {:expression, [{:literal, [nil], []}], []}
      assert {:ok, ""} = Renderer.render_node(ast, %{})
    end

    test "handles string literals with special characters" do
      # Newlines
      ast = {:expression, [{:literal, ["hello\nworld"], []}], []}
      assert {:ok, "hello\nworld"} = Renderer.render_node(ast, %{})
      
      # Tabs
      ast = {:expression, [{:literal, ["hello\tworld"], []}], []}
      assert {:ok, "hello\tworld"} = Renderer.render_node(ast, %{})
      
      # Unicode
      ast = {:expression, [{:literal, ["café"], []}], []}
      assert {:ok, "café"} = Renderer.render_node(ast, %{})
    end

    test "context is not used for literal evaluation" do
      ast = {:expression, [{:literal, ["hello"], []}], []}
      assert {:ok, "hello"} = Renderer.render_node(ast, %{})
      assert {:ok, "hello"} = Renderer.render_node(ast, %{name: "John", value: 42})
    end

    test "handles edge case values" do
      # Very large numbers
      ast = {:expression, [{:literal, [999999999999999999], []}], []}
      assert {:ok, "999999999999999999"} = Renderer.render_node(ast, %{})
      
      # Very small floats
      ast = {:expression, [{:literal, [0.000001], []}], []}
      assert {:ok, "1.0e-6"} = Renderer.render_node(ast, %{})
    end

    test "handles unknown expression types gracefully" do
      # Variable expressions are now supported and return empty string for undefined vars
      ast = {:expression, [{:variable, ["name"], []}], []}
      assert {:ok, ""} = Renderer.render_node(ast, %{})
      
      # With context it should return the value
      assert {:ok, "Alice"} = Renderer.render_node(ast, %{"name" => "Alice"})
    end
  end
end