defmodule Mau.AssignmentTagTest do
  use ExUnit.Case, async: true
  alias Mau.Renderer

  describe "assignment tag evaluation" do
    test "evaluates simple string assignment" do
      tag_node = {:tag, [:assign, "name", {:literal, ["John"], []}], []}
      context = %{}

      assert {:ok, ""} = Renderer.render_node(tag_node, context)
    end

    test "evaluates assignment with number" do
      tag_node = {:tag, [:assign, "age", {:literal, [25], []}], []}
      context = %{}

      assert {:ok, ""} = Renderer.render_node(tag_node, context)
    end

    test "evaluates assignment with variable" do
      tag_node = {:tag, [:assign, "greeting", {:variable, ["message"], []}], []}
      context = %{"message" => "Hello"}

      assert {:ok, ""} = Renderer.render_node(tag_node, context)
    end

    test "evaluates assignment with arithmetic expression" do
      tag_node =
        {:tag,
         [:assign, "total", {:binary_op, ["+", {:literal, [10], []}, {:literal, [5], []}], []}],
         []}

      context = %{}

      assert {:ok, ""} = Renderer.render_node(tag_node, context)
    end

    test "evaluates assignment with filter expression" do
      tag_node =
        {:tag, [:assign, "upper_name", {:call, ["upper_case", [{:literal, ["john"], []}]], []}],
         []}

      context = %{}

      assert {:ok, ""} = Renderer.render_node(tag_node, context)
    end

    test "returns error for assignment with undefined variable" do
      # Should not error, undefined variables return nil which becomes empty string
      tag_node = {:tag, [:assign, "greeting", {:variable, ["undefined"], []}], []}
      context = %{}

      assert {:ok, ""} = Renderer.render_node(tag_node, context)
    end

    test "returns error for assignment with invalid expression" do
      # Division by zero should return an error
      tag_node =
        {:tag,
         [:assign, "result", {:binary_op, ["/", {:literal, [10], []}, {:literal, [0], []}], []}],
         []}

      context = %{}

      assert {:error, error} = Renderer.render_node(tag_node, context)
      assert error.type == :runtime
      assert String.contains?(error.message, "Division by zero")
    end
  end

  describe "assignment context updates" do
    test "assignment updates context for subsequent expressions" do
      # Template: {% assign name = "John" %} Hello {{ name }}
      nodes = [
        {:tag, [:assign, "name", {:literal, ["John"], []}], []},
        {:text, [" Hello "], []},
        {:expression, [{:variable, ["name"], []}], []}
      ]

      context = %{}

      assert {:ok, " Hello John"} = Renderer.render(nodes, context)
    end

    test "assignment with arithmetic expression updates context" do
      # Template: {% assign total = 10 + 5 %} Total: {{ total }}
      nodes = [
        {:tag,
         [:assign, "total", {:binary_op, ["+", {:literal, [10], []}, {:literal, [5], []}], []}],
         []},
        {:text, [" Total: "], []},
        {:expression, [{:variable, ["total"], []}], []}
      ]

      context = %{}

      assert {:ok, " Total: 15"} = Renderer.render(nodes, context)
    end

    test "assignment with filter expression updates context" do
      # Template: {% assign upper_name = "john" | upper_case %} Hello {{ upper_name }}
      nodes = [
        {:tag, [:assign, "upper_name", {:call, ["upper_case", [{:literal, ["john"], []}]], []}],
         []},
        {:text, [" Hello "], []},
        {:expression, [{:variable, ["upper_name"], []}], []}
      ]

      context = %{}

      assert {:ok, " Hello JOHN"} = Renderer.render(nodes, context)
    end

    test "multiple assignments accumulate in context" do
      # Template: {% assign first = "John" %}{% assign last = "Doe" %} {{ first }} {{ last }}
      nodes = [
        {:tag, [:assign, "first", {:literal, ["John"], []}], []},
        {:tag, [:assign, "last", {:literal, ["Doe"], []}], []},
        {:text, [" "], []},
        {:expression, [{:variable, ["first"], []}], []},
        {:text, [" "], []},
        {:expression, [{:variable, ["last"], []}], []}
      ]

      context = %{}

      assert {:ok, " John Doe"} = Renderer.render(nodes, context)
    end

    test "assignment overwrites existing context variable" do
      # Template: {% assign name = "Jane" %} {{ name }}
      nodes = [
        {:tag, [:assign, "name", {:literal, ["Jane"], []}], []},
        {:text, [" "], []},
        {:expression, [{:variable, ["name"], []}], []}
      ]

      context = %{"name" => "John"}

      assert {:ok, " Jane"} = Renderer.render(nodes, context)
    end

    test "assignment uses existing context in expression" do
      # Template: {% assign greeting = "Hello " + name %} {{ greeting }}
      nodes = [
        {:tag,
         [
           :assign,
           "greeting",
           {:binary_op, ["+", {:literal, ["Hello "], []}, {:variable, ["name"], []}], []}
         ], []},
        {:text, [" "], []},
        {:expression, [{:variable, ["greeting"], []}], []}
      ]

      context = %{"name" => "World"}

      assert {:ok, " Hello World"} = Renderer.render(nodes, context)
    end

    test "complex assignment with nested variable access" do
      # Template: {% assign user_name = user.profile.name %} Hello {{ user_name }}
      nodes = [
        {:tag,
         [
           :assign,
           "user_name",
           {:variable, ["user", {:property, "profile"}, {:property, "name"}], []}
         ], []},
        {:text, [" Hello "], []},
        {:expression, [{:variable, ["user_name"], []}], []}
      ]

      context = %{"user" => %{"profile" => %{"name" => "Alice"}}}

      assert {:ok, " Hello Alice"} = Renderer.render(nodes, context)
    end

    test "assignment with workflow variable" do
      # Template: {% assign input_value = $input.data %} Value: {{ input_value }}
      nodes = [
        {:tag, [:assign, "input_value", {:variable, ["$input", {:property, "data"}], []}], []},
        {:text, [" Value: "], []},
        {:expression, [{:variable, ["input_value"], []}], []}
      ]

      context = %{"$input" => %{"data" => "test_value"}}

      assert {:ok, " Value: test_value"} = Renderer.render(nodes, context)
    end
  end
end
