defmodule Mau.ExpressionBlockTest do
  use ExUnit.Case

  alias Mau.Parser

  describe "Expression Block Parsing" do
    test "parses string literal expressions" do
      assert {:ok, {:expression, [{:literal, ["hello"], []}], []}} = 
        Parser.parse_expression_block("{{ \"hello\" }}")
      
      assert {:ok, {:expression, [{:literal, ["world"], []}], []}} = 
        Parser.parse_expression_block("{{ 'world' }}")
    end

    test "parses number literal expressions" do
      assert {:ok, {:expression, [{:literal, [42], []}], []}} = 
        Parser.parse_expression_block("{{ 42 }}")
      
      assert {:ok, {:expression, [{:literal, [3.14], []}], []}} = 
        Parser.parse_expression_block("{{ 3.14 }}")
      
      assert {:ok, {:expression, [{:literal, [-123], []}], []}} = 
        Parser.parse_expression_block("{{ -123 }}")
      
      assert {:ok, {:expression, [{:literal, [1.0e3], []}], []}} = 
        Parser.parse_expression_block("{{ 1e3 }}")
    end

    test "parses boolean literal expressions" do
      assert {:ok, {:expression, [{:literal, [true], []}], []}} = 
        Parser.parse_expression_block("{{ true }}")
      
      assert {:ok, {:expression, [{:literal, [false], []}], []}} = 
        Parser.parse_expression_block("{{ false }}")
    end

    test "parses null literal expressions" do
      assert {:ok, {:expression, [{:literal, [nil], []}], []}} = 
        Parser.parse_expression_block("{{ null }}")
    end

    test "handles whitespace variations" do
      # No spaces
      assert {:ok, {:expression, [{:literal, [42], []}], []}} = 
        Parser.parse_expression_block("{{42}}")
      
      # Multiple spaces
      assert {:ok, {:expression, [{:literal, [42], []}], []}} = 
        Parser.parse_expression_block("{{   42   }}")
      
      # Tabs and newlines
      assert {:ok, {:expression, [{:literal, [42], []}], []}} = 
        Parser.parse_expression_block("{{\t42\n}}")
    end

    test "fails on malformed expression blocks" do
      # Missing closing braces
      assert {:error, _} = Parser.parse_expression_block("{{ 42")
      assert {:error, _} = Parser.parse_expression_block("{{ 42 }")
      
      # Missing opening braces  
      assert {:error, _} = Parser.parse_expression_block("42 }}")
      assert {:error, _} = Parser.parse_expression_block("{ 42 }}")
      
      # Empty expression
      assert {:error, _} = Parser.parse_expression_block("{{}}")
      assert {:error, _} = Parser.parse_expression_block("{{ }}")
      
      # Invalid content (identifier starting with number)
      assert {:error, _} = Parser.parse_expression_block("{{ 123invalid }}")
    end

    test "fails on expressions with extra characters" do
      assert {:error, _} = Parser.parse_expression_block("{{ 42 }}extra")
      assert {:error, _} = Parser.parse_expression_block("prefix{{ 42 }}")
    end

    test "handles complex literals in expressions" do
      # String with escapes
      assert {:ok, {:expression, [{:literal, ["hello\nworld"], []}], []}} = 
        Parser.parse_expression_block("{{ \"hello\\nworld\" }}")
      
      # Unicode string
      assert {:ok, {:expression, [{:literal, ["café"], []}], []}} = 
        Parser.parse_expression_block("{{ \"caf\\u00e9\" }}")
      
      # Scientific notation
      assert {:ok, {:expression, [{:literal, [2.5e-10], []}], []}} = 
        Parser.parse_expression_block("{{ 2.5e-10 }}")
    end
  end
end