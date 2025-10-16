defmodule Mau.ArrayLiteralTest do
  @moduledoc """
  Tests for array literal parsing and rendering.
  """

  use ExUnit.Case
  alias Mau.Parser

  describe "array literal parsing" do
    test "parses empty array" do
      assert {:ok, ast} = Parser.parse("{{ [] }}")
      assert [{:expression, [{:literal, [[]], []}], []}] = ast
    end

    test "parses array with single number" do
      assert {:ok, ast} = Parser.parse("{{ [1] }}")

      assert [{:expression, [array_literal], []}] = ast
      assert {:literal, [elements], []} = array_literal
      assert [_] = elements
    end

    test "parses array with multiple numbers" do
      assert {:ok, ast} = Parser.parse("{{ [1, 2, 3] }}")

      assert [{:expression, [array_literal], []}] = ast
      assert {:literal, [elements], []} = array_literal
      assert length(elements) == 3
    end

    test "parses array with strings" do
      assert {:ok, ast} = Parser.parse(~s({{ ["a", "b", "c"] }}))

      assert [{:expression, [array_literal], []}] = ast
      assert {:literal, [elements], []} = array_literal
      assert length(elements) == 3
    end

    test "parses array with mixed types" do
      assert {:ok, ast} = Parser.parse(~s({{ [1, "two", true, null] }}))

      assert [{:expression, [array_literal], []}] = ast
      assert {:literal, [elements], []} = array_literal
      assert length(elements) == 4
    end

    test "parses array with variables" do
      assert {:ok, ast} = Parser.parse("{{ [user.name, user.email] }}")

      assert [{:expression, [array_literal], []}] = ast
      assert {:literal, [elements], []} = array_literal
      assert length(elements) == 2
    end

    test "parses array with whitespace variations" do
      assert {:ok, _} = Parser.parse("{{ [1,2,3] }}")
      assert {:ok, _} = Parser.parse("{{ [ 1, 2, 3 ] }}")
      assert {:ok, _} = Parser.parse("{{ [  1  ,  2  ,  3  ] }}")
    end

    test "parses nested arrays" do
      assert {:ok, ast} = Parser.parse("{{ [[1, 2], [3, 4]] }}")

      assert [{:expression, [array_literal], []}] = ast
      assert {:literal, [elements], []} = array_literal
      assert length(elements) == 2
    end
  end

  describe "array literal rendering" do
    test "renders empty array" do
      assert {:ok, result} = Mau.render("{{ [] }}", %{})
      assert result == "[]"
    end

    test "renders array with numbers" do
      assert {:ok, result} = Mau.render("{{ [1, 2, 3] }}", %{})
      assert result == "[1, 2, 3]"
    end

    test "renders array with strings" do
      assert {:ok, result} = Mau.render(~s({{ ["a", "b", "c"] }}), %{})
      assert result == ~s(["a", "b", "c"])
    end

    test "renders array with mixed types" do
      assert {:ok, result} = Mau.render(~s({{ [1, "two", true, false, null] }}), %{})
      assert result =~ "1"
      assert result =~ "two"
      assert result =~ "true"
      assert result =~ "false"
    end

    test "renders array with variables" do
      context = %{"name" => "Alice", "age" => 30}
      assert {:ok, result} = Mau.render("{{ [name, age] }}", context)
      assert result =~ "Alice"
      assert result =~ "30"
    end

    test "preserves types when preserve_types is true" do
      assert {:ok, result} = Mau.render("{{ [1, 2, 3] }}", %{}, preserve_types: true)
      assert result == [1, 2, 3]
    end

    test "evaluates expressions in array" do
      assert {:ok, result} =
               Mau.render("{{ [1 + 1, 2 * 3, 10 / 2] }}", %{}, preserve_types: true)

      assert result == [2, 6, 5.0]
    end

    test "evaluates nested property access in array" do
      context = %{
        "user" => %{
          "profile" => %{
            "name" => "Alice",
            "email" => "alice@example.com"
          }
        }
      }

      assert {:ok, result} =
               Mau.render("{{ [user.profile.name, user.profile.email] }}", context,
                 preserve_types: true
               )

      assert result == ["Alice", "alice@example.com"]
    end

    test "renders nested arrays" do
      assert {:ok, result} = Mau.render("{{ [[1, 2], [3, 4]] }}", %{}, preserve_types: true)
      assert result == [[1, 2], [3, 4]]
    end
  end

  describe "array literals with filters" do
    test "applies length filter to array literal" do
      assert {:ok, result} = Mau.render("{{ [1, 2, 3] | length }}", %{})
      assert result == "3"
    end

    test "applies join filter to array literal" do
      template = "{{ [\"a\", \"b\", \"c\"] | join(\", \") }}"
      assert {:ok, result} = Mau.render(template, %{})
      assert result == "a, b, c"
    end

    test "applies first filter to array literal" do
      assert {:ok, result} = Mau.render("{{ [1, 2, 3] | first }}", %{})
      assert result == "1"
    end

    test "applies last filter to array literal" do
      assert {:ok, result} = Mau.render("{{ [1, 2, 3] | last }}", %{})
      assert result == "3"
    end

    test "applies contains filter to array literal" do
      assert {:ok, result} = Mau.render("{{ [1, 2, 3] | contains(2) }}", %{})
      assert result == "true"
    end

    test "chains multiple filters on array literal" do
      assert {:ok, result} = Mau.render("{{ [3, 1, 2] | sort | first }}", %{})
      assert result == "1"
    end
  end

  describe "array literals in conditionals" do
    test "checks if value is in array using contains filter" do
      template = """
      {% if [1, 2, 3] | contains(status) %}
        Status is valid
      {% else %}
        Status is invalid
      {% endif %}
      """

      assert {:ok, result} = Mau.render(template, %{"status" => 2})
      assert String.contains?(result, "Status is valid")

      assert {:ok, result} = Mau.render(template, %{"status" => 5})
      assert String.contains?(result, "Status is invalid")
    end

    test "checks array length in conditional" do
      template = """
      {% if [1, 2, 3] | length > 2 %}
        Has items
      {% endif %}
      """

      assert {:ok, result} = Mau.render(template, %{})
      assert String.contains?(result, "Has items")
    end

    test "uses array literal with variable in conditional" do
      template = """
      {% if ["admin", "moderator"] | contains(role) %}
        Has elevated permissions
      {% endif %}
      """

      assert {:ok, result} = Mau.render(template, %{"role" => "admin"})
      assert String.contains?(result, "Has elevated permissions")

      assert {:ok, result} = Mau.render(template, %{"role" => "user"})
      refute String.contains?(result, "Has elevated permissions")
    end
  end

  describe "array literals in loops" do
    test "iterates over array literal" do
      template = """
      {% for item in [1, 2, 3] %}
        {{ item }}
      {% endfor %}
      """

      assert {:ok, result} = Mau.render(template, %{})
      assert String.contains?(result, "1")
      assert String.contains?(result, "2")
      assert String.contains?(result, "3")
    end

    test "iterates over array literal with strings" do
      template = """
      {% for name in ["Alice", "Bob", "Charlie"] %}
        Hello {{ name }}!
      {% endfor %}
      """

      assert {:ok, result} = Mau.render(template, %{})
      assert String.contains?(result, "Hello Alice!")
      assert String.contains?(result, "Hello Bob!")
      assert String.contains?(result, "Hello Charlie!")
    end
  end

  describe "array literals in assignments" do
    test "assigns array literal to variable" do
      template = """
      {% assign numbers = [1, 2, 3] %}
      {{ numbers | length }}
      """

      assert {:ok, result} = Mau.render(template, %{})
      assert String.contains?(result, "3")
    end

    test "assigns and uses array literal" do
      template = """
      {% assign colors = ["red", "green", "blue"] %}
      {% for color in colors %}
        {{ color }}
      {% endfor %}
      """

      assert {:ok, result} = Mau.render(template, %{})
      assert String.contains?(result, "red")
      assert String.contains?(result, "green")
      assert String.contains?(result, "blue")
    end
  end

  describe "edge cases" do
    test "array with trailing comma falls back to text" do
      # Trailing commas are not supported - parser falls back to text
      assert {:ok, result} = Parser.parse("{{ [1, 2, 3,] }}")
      # Should parse as text since array is invalid
      assert [{:text, _, _}] = result
    end

    test "unclosed array bracket falls back to text" do
      # Missing closing bracket - parser falls back to text
      assert {:ok, result} = Parser.parse("{{ [1, 2, 3 }}")
      assert [{:text, _, _}] = result
    end

    test "array with missing comma falls back to text" do
      # Missing comma between elements - parser falls back to text
      assert {:ok, result} = Parser.parse("{{ [1 2 3] }}")
      assert [{:text, _, _}] = result
    end
  end
end
