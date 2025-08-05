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
end
