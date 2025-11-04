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

  describe "negative numbers vs whitespace control disambiguation" do
    test "renders {{-1 * 1.00}} as negative number multiplication" do
      template = "{{-1 * 1.00}}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "-1.0"
    end

    test "renders {{-5 + 3}} as negative number addition" do
      template = "{{-5 + 3}}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "-2"
    end

    test "renders {{-3.14}} as negative float" do
      template = "{{-3.14}}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "-3.14"
    end

    test "renders {{-1 * -2}} as negative numbers multiplication" do
      template = "{{-1 * -2}}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "2"
    end

    test "renders {{- 5}} with space as whitespace trim" do
      template = "  {{- 5}}  "
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # Should trim left whitespace
      assert result == "5  "
    end

    test "renders {{- -5}} with space as trim followed by negative number" do
      template = "  {{- -5}}  "
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # Should trim left whitespace and render negative number
      assert result == "-5  "
    end

    test "renders complex expression starting with negative number" do
      template = "Result: {{-10 / 2 + 3}}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "Result: -2.0"
    end

    test "treats {{-var}} as literal text (invalid syntax)" do
      template = "{{-var}}"
      context = %{"var" => 42}

      # {{-var}} is not valid syntax because:
      # - It's not whitespace control (no space after {{-)
      # - It's not a negative number literal (var is not a number)
      # - Unary minus on variables is not supported
      # So it's treated as literal text
      assert {:ok, result} = Mau.render(template, context)
      assert result == "{{-var}}"
    end

    test "preserves negative numbers in arithmetic expressions" do
      template = "{{ 10 + -5 }}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "5"
    end

    test "handles negative numbers at start of complex expressions" do
      template = "{{-1 * 2 + 3 * 4}}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "10"
    end

    test "distinguishes between trim and negative in mixed content" do
      template = "A{{-1}}B  {{- 2}}C"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # {{-1}} is negative one (no trim), {{- 2}} is trim with value 2
      assert result == "A-1B2C"
    end
  end
end
