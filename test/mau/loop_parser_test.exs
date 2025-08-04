defmodule Mau.LoopParserTest do
  use ExUnit.Case, async: true
  alias Mau.Parser

  describe "for tag parsing" do
    test "parses simple for loop with variable" do
      template = "{% for item in items %}"
      {:ok, [ast]} = Parser.parse(template)
      
      assert {:tag, [:for, "item", {:variable, ["items"], []}], []} = ast
    end

    test "parses for loop with string literal" do
      template = "{% for char in \"abc\" %}"
      {:ok, [ast]} = Parser.parse(template)
      
      assert {:tag, [:for, "char", {:literal, ["abc"], []}], []} = ast
    end

    test "parses for loop with complex expression" do
      template = "{% for user in users | sort %}"
      {:ok, [ast]} = Parser.parse(template)
      
      assert {:tag, [:for, "user", {:call, ["sort", [_]], []}], []} = ast
    end

    test "parses for loop with property access" do
      template = "{% for order in user.orders %}"
      {:ok, [ast]} = Parser.parse(template)
      
      assert {:tag, [:for, "order", {:variable, ["user", {:property, "orders"}], []}], []} = ast
    end

    test "parses endfor tag" do
      template = "{% endfor %}"
      {:ok, [ast]} = Parser.parse(template)
      
      assert {:tag, [:endfor], []} = ast
    end

    test "handles whitespace in for tag" do
      template = "{%   for   item   in   items   %}"
      {:ok, [ast]} = Parser.parse(template)
      
      assert {:tag, [:for, "item", {:variable, ["items"], []}], []} = ast
    end

    test "parses workflow variable collection" do
      template = "{% for item in $input.results %}"
      {:ok, [ast]} = Parser.parse(template)
      
      assert {:tag, [:for, "item", {:variable, ["$input", {:property, "results"}], []}], []} = ast
    end

    test "handles mixed content with for loop" do
      template = "Before {% for item in items %} item content {% endfor %} After"
      {:ok, ast} = Parser.parse(template)
      
      assert [
        {:text, ["Before "], []},
        {:tag, [:for, "item", _], []},
        {:text, [" item content "], []},
        {:tag, [:endfor], []},
        {:text, [" After"], []}
      ] = ast
    end
  end

  describe "error handling" do
    test "handles invalid for syntax" do
      template = "{% for item %}"
      {:ok, _ast} = Parser.parse(template)
      # Parser should handle this gracefully, treating as text
    end

    test "handles missing 'in' keyword" do
      template = "{% for item items %}"
      {:ok, _ast} = Parser.parse(template)
      # Parser should handle this gracefully
    end
  end
end