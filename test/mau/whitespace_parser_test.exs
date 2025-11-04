defmodule Mau.WhitespaceParserTest do
  use ExUnit.Case, async: true
  alias Mau.Parser

  describe "expression trim token parsing" do
    test "parses normal expression without trim" do
      result = Parser.parse("{{ name }}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:expression, [_], opts} = node
      assert Keyword.get(opts, :trim_left) == nil
      assert Keyword.get(opts, :trim_right) == nil
    end

    test "parses expression with left trim" do
      result = Parser.parse("{{- name }}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:expression, [_], opts} = node
      assert Keyword.get(opts, :trim_left) == true
      assert Keyword.get(opts, :trim_right) == nil
    end

    test "parses expression with right trim" do
      result = Parser.parse("{{ name -}}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:expression, [_], opts} = node
      assert Keyword.get(opts, :trim_left) == nil
      assert Keyword.get(opts, :trim_right) == true
    end

    test "parses expression with both trim" do
      result = Parser.parse("{{- name -}}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:expression, [_], opts} = node
      assert Keyword.get(opts, :trim_left) == true
      assert Keyword.get(opts, :trim_right) == true
    end

    test "parses complex expression with trim" do
      result = Parser.parse("{{- user.name | upper_case -}}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:expression, [_], opts} = node
      assert Keyword.get(opts, :trim_left) == true
      assert Keyword.get(opts, :trim_right) == true
    end
  end

  describe "tag trim token parsing" do
    test "parses normal tag without trim" do
      result = Parser.parse("{% assign name = \"value\" %}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:tag, [:assign, _, _], opts} = node
      assert Keyword.get(opts, :trim_left) == nil
      assert Keyword.get(opts, :trim_right) == nil
    end

    test "parses tag with left trim" do
      result = Parser.parse("{%- assign name = \"value\" %}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:tag, [:assign, _, _], opts} = node
      assert Keyword.get(opts, :trim_left) == true
      assert Keyword.get(opts, :trim_right) == nil
    end

    test "parses tag with right trim" do
      result = Parser.parse("{% assign name = \"value\" -%}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:tag, [:assign, _, _], opts} = node
      assert Keyword.get(opts, :trim_left) == nil
      assert Keyword.get(opts, :trim_right) == true
    end

    test "parses tag with both trim" do
      result = Parser.parse("{%- assign name = \"value\" -%}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:tag, [:assign, _, _], opts} = node
      assert Keyword.get(opts, :trim_left) == true
      assert Keyword.get(opts, :trim_right) == true
    end

    test "parses conditional tags with trim" do
      result = Parser.parse("{%- if condition -%}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:tag, [:if, _], opts} = node
      assert Keyword.get(opts, :trim_left) == true
      assert Keyword.get(opts, :trim_right) == true
    end

    test "parses loop tags with trim" do
      result = Parser.parse("{%- for item in items -%}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:tag, [:for, _, _], opts} = node
      assert Keyword.get(opts, :trim_left) == true
      assert Keyword.get(opts, :trim_right) == true
    end
  end

  describe "mixed content with trim tokens" do
    test "parses mixed content with various trim combinations" do
      template = """
      Start  {{- name }}  Middle  {{ value -}}  End
      """

      result = Parser.parse(template)
      assert {:ok, nodes} = result

      # Should have: text, expression(left_trim), text, expression(right_trim), text
      assert length(nodes) == 5

      [text1, expr1, text2, expr2, text3] = nodes

      assert {:text, ["Start  "], []} = text1
      assert {:expression, [_], opts1} = expr1
      assert Keyword.get(opts1, :trim_left) == true

      assert {:text, ["  Middle  "], []} = text2
      assert {:expression, [_], opts2} = expr2
      assert Keyword.get(opts2, :trim_right) == true

      assert {:text, ["  End\n"], []} = text3
    end
  end

  describe "negative numbers vs whitespace control disambiguation" do
    test "parses {{-1}} as negative number (no trim)" do
      result = Parser.parse("{{-1}}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:expression, [{:literal, [-1], []}], opts} = node
      # Should NOT have trim flags since this is a negative number
      assert Keyword.get(opts, :trim_left) == nil
      assert Keyword.get(opts, :trim_right) == nil
    end

    test "parses {{-5 + 3}} as negative number expression" do
      result = Parser.parse("{{-5 + 3}}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:expression, [{:binary_op, ["+", {:literal, [-5], []}, {:literal, [3], []}], []}], opts} = node
      assert Keyword.get(opts, :trim_left) == nil
    end

    test "parses {{-3.14}} as negative float" do
      result = Parser.parse("{{-3.14}}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:expression, [{:literal, [value], []}], opts} = node
      assert_in_delta value, -3.14, 0.001
      assert Keyword.get(opts, :trim_left) == nil
    end

    test "parses {{- 5}} with space as whitespace control" do
      result = Parser.parse("{{- 5}}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:expression, [{:literal, [5], []}], opts} = node
      # Should have trim flag since there's a space after {{-
      assert Keyword.get(opts, :trim_left) == true
    end

    test "parses {{- name}} with space as whitespace control" do
      result = Parser.parse("{{- name}}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:expression, [{:variable, ["name"], []}], opts} = node
      assert Keyword.get(opts, :trim_left) == true
    end

    test "parses {{-1 * 2}} as negative number multiplication" do
      result = Parser.parse("{{-1 * 2}}")

      assert {:ok, nodes} = result
      assert [node] = nodes
      assert {:expression, [{:binary_op, ["*", {:literal, [-1], []}, {:literal, [2], []}], []}], opts} = node
      assert Keyword.get(opts, :trim_left) == nil
    end
  end
end
