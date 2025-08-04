defmodule Mau.FilterEvaluatorTest do
  use ExUnit.Case, async: true
  alias Mau.Renderer

  describe "filter evaluation" do
    test "evaluates simple string filter" do
      # {:call, ["upper_case", [value]], []}
      call_node = {:call, ["upper_case", [{:literal, ["hello"], []}]], []}
      context = %{}

      assert {:ok, "HELLO"} = Renderer.render_node({:expression, [call_node], []}, context)
    end

    test "evaluates filter with arguments" do
      call_node = {:call, ["truncate", [{:literal, ["hello world"], []}, {:literal, [5], []}]], []}
      context = %{}

      assert {:ok, "hello"} = Renderer.render_node({:expression, [call_node], []}, context)
    end

    test "evaluates filter with variable input" do
      call_node = {:call, ["upper_case", [{:variable, ["name"], []}]], []}
      context = %{"name" => "world"}

      assert {:ok, "WORLD"} = Renderer.render_node({:expression, [call_node], []}, context)
    end

    test "evaluates chained filters" do
      # Nested call: upper_case(truncate("hello world", 5))
      inner_call = {:call, ["truncate", [{:literal, ["hello world"], []}, {:literal, [5], []}]], []}
      outer_call = {:call, ["upper_case", [inner_call]], []}
      context = %{}

      assert {:ok, "HELLO"} = Renderer.render_node({:expression, [outer_call], []}, context)
    end

    test "evaluates number filters" do
      call_node = {:call, ["round", [{:literal, [3.14159], []}, {:literal, [2], []}]], []}
      context = %{}

      assert {:ok, "3.14"} = Renderer.render_node({:expression, [call_node], []}, context)
    end

    test "evaluates collection filters" do
      call_node = {:call, ["length", [{:variable, ["items"], []}]], []}
      context = %{"items" => [1, 2, 3, 4]}

      assert {:ok, "4"} = Renderer.render_node({:expression, [call_node], []}, context)
    end

    test "evaluates join filter" do
      call_node = {:call, ["join", [{:variable, ["items"], []}, {:literal, [", "], []}]], []}
      context = %{"items" => ["a", "b", "c"]}

      assert {:ok, "a, b, c"} = Renderer.render_node({:expression, [call_node], []}, context)
    end

    test "evaluates math filters" do
      call_node = {:call, ["abs", [{:literal, [-5], []}]], []}
      context = %{}

      assert {:ok, "5"} = Renderer.render_node({:expression, [call_node], []}, context)
    end

    test "evaluates default filter with nil input" do
      call_node = {:call, ["default", [{:variable, ["missing"], []}, {:literal, ["fallback"], []}]], []}
      context = %{}

      assert {:ok, "fallback"} = Renderer.render_node({:expression, [call_node], []}, context)
    end

    test "evaluates default filter with existing value" do
      call_node = {:call, ["default", [{:variable, ["name"], []}, {:literal, ["fallback"], []}]], []}
      context = %{"name" => "actual"}

      assert {:ok, "actual"} = Renderer.render_node({:expression, [call_node], []}, context)
    end

    test "returns error for unknown filter" do
      call_node = {:call, ["unknown_filter", [{:literal, ["value"], []}]], []}
      context = %{}

      assert {:error, error} = Renderer.render_node({:expression, [call_node], []}, context)
      assert error.type == :runtime
      assert String.contains?(error.message, "Unknown filter or function: unknown_filter")
    end

    test "handles filter errors gracefully" do
      # Try to get sqrt of negative number
      call_node = {:call, ["sqrt", [{:literal, [-1], []}]], []}
      context = %{}

      assert {:error, error} = Renderer.render_node({:expression, [call_node], []}, context)
      assert error.type == :runtime
      assert String.contains?(error.message, "Filter error in sqrt")
    end

    test "evaluates filters with complex expressions as arguments" do
      # truncate(name + " world", price * 2)
      name_plus_world = {:binary_op, ["+", {:variable, ["name"], []}, {:literal, [" world"], []}], []}
      price_times_two = {:binary_op, ["*", {:variable, ["price"], []}, {:literal, [2], []}], []}
      call_node = {:call, ["truncate", [name_plus_world, price_times_two]], []}
      context = %{"name" => "hello", "price" => 3}

      assert {:ok, "hello "} = Renderer.render_node({:expression, [call_node], []}, context)
    end

    test "evaluates nested arithmetic with filters" do
      # (price | round(2)) + tax
      rounded_price = {:call, ["round", [{:variable, ["price"], []}, {:literal, [2], []}]], []}
      addition = {:binary_op, ["+", rounded_price, {:variable, ["tax"], []}], []}
      context = %{"price" => 9.999, "tax" => 1.5}

      assert {:ok, "11.5"} = Renderer.render_node({:expression, [addition], []}, context)
    end
  end

  describe "argument evaluation errors" do
    test "returns error when argument evaluation fails" do
      # upper_case(undefined_var)
      call_node = {:call, ["upper_case", [{:variable, ["undefined_var"], []}]], []}
      context = %{}

      # This should succeed but with nil converted to empty string
      assert {:ok, ""} = Renderer.render_node({:expression, [call_node], []}, context)
    end

    test "propagates arithmetic error in arguments" do
      # round(10 / 0)
      division_by_zero = {:binary_op, ["/", {:literal, [10], []}, {:literal, [0], []}], []}
      call_node = {:call, ["round", [division_by_zero]], []}
      context = %{}

      assert {:error, error} = Renderer.render_node({:expression, [call_node], []}, context)
      assert error.type == :runtime
      assert String.contains?(error.message, "Division by zero")
    end
  end
end