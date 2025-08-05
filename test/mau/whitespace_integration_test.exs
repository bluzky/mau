defmodule Mau.WhitespaceIntegrationTest do
  use ExUnit.Case, async: true
  alias Mau

  describe "whitespace control integration" do
    test "trims whitespace with left trim expression" do
      template = """
      Hello   {{- name }}   World
      """
      context = %{"name" => "Alice"}
      
      assert {:ok, result} = Mau.render(template, context)
      # Left trim should remove trailing whitespace before the expression
      assert result == "HelloAlice   World\n"
    end

    test "trims whitespace with right trim expression" do
      template = """
      Hello   {{ name -}}   World
      """
      context = %{"name" => "Alice"}
      
      assert {:ok, result} = Mau.render(template, context)
      # Right trim should remove leading whitespace after the expression
      assert result == "Hello   AliceWorld\n"
    end

    test "trims whitespace with both trim expression" do
      template = """
      Hello   {{- name -}}   World
      """
      context = %{"name" => "Alice"}
      
      assert {:ok, result} = Mau.render(template, context)
      # Both trim should remove whitespace on both sides
      assert result == "HelloAliceWorld\n"
    end

    test "trims whitespace with left trim tag" do
      template = """
      Hello   {%- assign greeting = "Hi" %}   World
      """
      context = %{}
      
      assert {:ok, result} = Mau.render(template, context)
      # Left trim should remove trailing whitespace before the tag
      assert result == "Hello   World\n"
    end

    test "trims whitespace with right trim tag" do
      template = """
      Hello   {% assign greeting = "Hi" -%}   World
      """
      context = %{}
      
      assert {:ok, result} = Mau.render(template, context)
      # Right trim should remove leading whitespace after the tag
      assert result == "Hello   World\n"
    end

    test "trims whitespace with both trim tag" do
      template = """
      Hello   {%- assign greeting = "Hi" -%}   World
      """
      context = %{}
      
      assert {:ok, result} = Mau.render(template, context)
      # Both trim should remove whitespace on both sides
      assert result == "HelloWorld\n"
    end

    test "handles multiple trim expressions in sequence" do
      template = """
      Start   {{- first -}}   Middle   {{- second -}}   End
      """
      context = %{"first" => "A", "second" => "B"}
      
      assert {:ok, result} = Mau.render(template, context)
      # Should trim around each expression
      assert result == "StartAMiddleBEnd\n"
    end

    test "handles trim in conditional blocks" do
      template = """
      Before   {%- if true -%}   Inside   {%- endif -%}   After
      """
      context = %{}
      
      assert {:ok, result} = Mau.render(template, context)
      # Should trim around the conditional block tags
      assert result == "BeforeInsideAfter\n"
    end

    test "handles trim in loop blocks" do
      template = """
      Start   {%- for item in items -%}{{ item }}{%- endfor -%}   End
      """
      context = %{"items" => ["A", "B", "C"]}
      
      assert {:ok, result} = Mau.render(template, context)
      # Should trim around the loop block
      assert result == "StartABCEnd\n"
    end

    test "preserves content when no trim is specified" do
      template = """
      Hello   {{ name }}   World
      """
      context = %{"name" => "Alice"}
      
      assert {:ok, result} = Mau.render(template, context)
      # Should preserve all whitespace when no trim is specified
      assert result == "Hello   Alice   World\n"
    end

    test "handles mixed trim and non-trim elements" do
      template = """
      A   {{- one }}   B   {{ two -}}   C   {{- three -}}   D
      """
      context = %{"one" => "1", "two" => "2", "three" => "3"}
      
      assert {:ok, result} = Mau.render(template, context)
      # Should apply different trim behaviors correctly
      assert result == "A1   B   2C3D\n"
    end

    test "handles newlines and complex whitespace" do
      template = """
      Line 1
        {{- indented }}
      Line 2
      """
      context = %{"indented" => "CONTENT"}
      
      assert {:ok, result} = Mau.render(template, context)
      # Should trim the newline and indentation before the expression
      assert result == "Line 1CONTENT\nLine 2\n"
    end

    test "handles empty result after trimming" do
      template = "   {{- empty -}}   "
      context = %{"empty" => ""}
      
      assert {:ok, result} = Mau.render(template, context)
      # Should result in empty string after trimming both sides
      assert result == ""
    end
  end
end