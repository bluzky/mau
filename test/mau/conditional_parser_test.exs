defmodule Mau.ConditionalParserTest do
  use ExUnit.Case, async: true
  doctest Mau.Parser

  alias Mau.Parser

  describe "conditional tag parsing" do
    test "parses if tag with simple condition" do
      template = "{% if user.active %}"

      assert {:ok, [ast]} = Parser.parse(template)
      assert {:tag, [:if, {:variable, ["user", {:property, "active"}], []}], []} = ast
    end

    test "parses if tag with boolean literal" do
      template = "{% if true %}"

      assert {:ok, [ast]} = Parser.parse(template)
      assert {:tag, [:if, {:literal, [true], []}], []} = ast
    end

    test "parses if tag with comparison expression" do
      template = "{% if age >= 18 %}"

      assert {:ok, [ast]} = Parser.parse(template)
      assert {:tag, [:if, comparison_ast], []} = ast
      # The exact structure of comparison_ast will depend on the binary operation structure
      assert match?({:binary_op, [">=", _, _], []}, comparison_ast)
    end

    test "parses elsif tag with condition" do
      template = "{% elsif status == \"active\" %}"

      assert {:ok, [ast]} = Parser.parse(template)
      assert {:tag, [:elsif, comparison_ast], []} = ast
      assert match?({:binary_op, ["==", _, _], []}, comparison_ast)
    end

    test "parses else tag" do
      template = "{% else %}"

      assert {:ok, [ast]} = Parser.parse(template)
      assert {:tag, [:else], []} = ast
    end

    test "parses endif tag" do
      template = "{% endif %}"

      assert {:ok, [ast]} = Parser.parse(template)
      assert {:tag, [:endif], []} = ast
    end

    test "parses conditional block with content" do
      template = """
      {% if user.active %}
      Welcome back!
      {% endif %}
      """

      assert {:ok, nodes} = Parser.parse(template)
      # if tag, text content, endif tag, final text
      assert length(nodes) == 4

      [if_tag, content, endif_tag, trailing_text] = nodes
      assert match?({:tag, [:if, _], []}, if_tag)
      assert match?({:text, ["\nWelcome back!\n"], []}, content)
      assert match?({:tag, [:endif], []}, endif_tag)
      assert match?({:text, ["\n"], []}, trailing_text)
    end

    test "parses full conditional block structure" do
      template = """
      {% if score >= 90 %}
      Excellent!
      {% elsif score >= 70 %}
      Good job!
      {% else %}
      Keep trying!
      {% endif %}
      """

      assert {:ok, nodes} = Parser.parse(template)
      # Multiple tags and text nodes
      assert length(nodes) > 5

      # Find all tag nodes
      tag_nodes =
        Enum.filter(nodes, fn
          {:tag, _, _} -> true
          _ -> false
        end)

      # if, elsif, else, endif
      assert length(tag_nodes) == 4

      [if_tag, elsif_tag, else_tag, endif_tag] = tag_nodes
      assert match?({:tag, [:if, _], []}, if_tag)
      assert match?({:tag, [:elsif, _], []}, elsif_tag)
      assert match?({:tag, [:else], []}, else_tag)
      assert match?({:tag, [:endif], []}, endif_tag)
    end
  end
end
