defmodule Mau.TagParserTest do
  use ExUnit.Case, async: true
  alias Mau.Parser

  describe "assignment tag parsing" do
    test "parses simple assignment tag" do
      template = "{% assign name = \"John\" %}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result == {:tag, [:assign, "name", {:literal, ["John"], []}], []}
    end

    test "parses assignment with variable expression" do
      template = "{% assign greeting = message %}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result == {:tag, [:assign, "greeting", {:variable, ["message"], []}], []}
    end

    test "parses assignment with arithmetic expression" do
      template = "{% assign total = price + tax %}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:tag,
                [
                  :assign,
                  "total",
                  {:binary_op, ["+", {:variable, ["price"], []}, {:variable, ["tax"], []}], []}
                ], []}
    end

    test "parses assignment with filter expression" do
      template = "{% assign upper_name = name | upper_case %}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:tag,
                [:assign, "upper_name", {:call, ["upper_case", [{:variable, ["name"], []}]], []}],
                []}
    end

    test "handles whitespace around assignment" do
      template = "{%  assign   name   =   \"John\"   %}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result == {:tag, [:assign, "name", {:literal, ["John"], []}], []}
    end

    test "parses assignment with complex variable path" do
      template = "{% assign user_name = user.profile.name %}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:tag,
                [
                  :assign,
                  "user_name",
                  {:variable, ["user", {:property, "profile"}, {:property, "name"}], []}
                ], []}
    end

    test "parses assignment with workflow variable" do
      template = "{% assign input_data = $input.data %}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:tag, [:assign, "input_data", {:variable, ["$input", {:property, "data"}], []}],
                []}
    end

    test "parses assignment with function call" do
      template = "{% assign rounded = round(price, 2) %}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:tag,
                [
                  :assign,
                  "rounded",
                  {:call, ["round", [{:variable, ["price"], []}, {:literal, [2], []}]], []}
                ], []}
    end
  end

  describe "mixed content with assignment tags" do
    test "parses text with assignment tag" do
      template = "Hello {% assign name = \"John\" %} world"

      assert {:ok, [text1, tag, text2], "", %{}, _, _} = Parser.parse_template(template)

      assert text1 == {:text, ["Hello "], []}
      assert tag == {:tag, [:assign, "name", {:literal, ["John"], []}], []}
      assert text2 == {:text, [" world"], []}
    end

    test "parses assignment with expression blocks" do
      template = "{% assign greeting = \"Hello\" %} {{ greeting }}"

      assert {:ok, [tag, text, expression], "", %{}, _, _} = Parser.parse_template(template)

      assert tag == {:tag, [:assign, "greeting", {:literal, ["Hello"], []}], []}
      assert text == {:text, [" "], []}
      assert expression == {:expression, [{:variable, ["greeting"], []}], []}
    end
  end
end
