defmodule Mau.BooleanNullLiteralTest do
  use ExUnit.Case

  alias Mau.Parser

  describe "Boolean Literal Parsing" do
    test "parses true literal" do
      assert {:ok, {:literal, [true], []}} = Parser.parse_boolean_literal("true")
    end

    test "parses false literal" do
      assert {:ok, {:literal, [false], []}} = Parser.parse_boolean_literal("false")
    end

    test "fails on invalid boolean formats" do
      assert {:error, _} = Parser.parse_boolean_literal("True")
      assert {:error, _} = Parser.parse_boolean_literal("TRUE")
      assert {:error, _} = Parser.parse_boolean_literal("False")
      assert {:error, _} = Parser.parse_boolean_literal("FALSE")
      assert {:error, _} = Parser.parse_boolean_literal("yes")
      assert {:error, _} = Parser.parse_boolean_literal("no")
      assert {:error, _} = Parser.parse_boolean_literal("1")
      assert {:error, _} = Parser.parse_boolean_literal("0")
    end

    test "fails on booleans with extra characters" do
      assert {:error, _} = Parser.parse_boolean_literal("truex")
      assert {:error, _} = Parser.parse_boolean_literal("falsex")
      assert {:error, _} = Parser.parse_boolean_literal("true ")
      assert {:error, _} = Parser.parse_boolean_literal(" false")
    end
  end

  describe "Null Literal Parsing" do
    test "parses null literal" do
      assert {:ok, {:literal, [nil], []}} = Parser.parse_null_literal("null")
    end

    test "fails on invalid null formats" do
      assert {:error, _} = Parser.parse_null_literal("Null")
      assert {:error, _} = Parser.parse_null_literal("NULL")
      assert {:error, _} = Parser.parse_null_literal("nil")
      assert {:error, _} = Parser.parse_null_literal("None")
      assert {:error, _} = Parser.parse_null_literal("undefined")
    end

    test "fails on null with extra characters" do
      assert {:error, _} = Parser.parse_null_literal("nullx")
      assert {:error, _} = Parser.parse_null_literal("null ")
      assert {:error, _} = Parser.parse_null_literal(" null")
    end
  end
end
