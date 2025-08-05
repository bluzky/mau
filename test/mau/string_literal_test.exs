defmodule Mau.StringLiteralTest do
  use ExUnit.Case

  alias Mau.Parser

  describe "String Literal Parsing" do
    test "parses double-quoted strings" do
      assert {:ok, {:literal, ["hello"], []}} = Parser.parse_string_literal("\"hello\"")
      assert {:ok, {:literal, [""], []}} = Parser.parse_string_literal("\"\"")

      assert {:ok, {:literal, ["Hello World"], []}} =
               Parser.parse_string_literal("\"Hello World\"")
    end

    test "parses single-quoted strings" do
      assert {:ok, {:literal, ["hello"], []}} = Parser.parse_string_literal("'hello'")
      assert {:ok, {:literal, [""], []}} = Parser.parse_string_literal("''")
      assert {:ok, {:literal, ["Hello World"], []}} = Parser.parse_string_literal("'Hello World'")
    end

    test "handles escape sequences in double quotes" do
      assert {:ok, {:literal, ["hello \"world\""], []}} =
               Parser.parse_string_literal("\"hello \\\"world\\\"\"")

      assert {:ok, {:literal, ["line1\nline2"], []}} =
               Parser.parse_string_literal("\"line1\\nline2\"")

      assert {:ok, {:literal, ["tab\there"], []}} = Parser.parse_string_literal("\"tab\\there\"")

      assert {:ok, {:literal, ["backslash\\here"], []}} =
               Parser.parse_string_literal("\"backslash\\\\here\"")
    end

    test "handles escape sequences in single quotes" do
      assert {:ok, {:literal, ["hello 'world'"], []}} =
               Parser.parse_string_literal("'hello \\'world\\''")

      assert {:ok, {:literal, ["line1\nline2"], []}} =
               Parser.parse_string_literal("'line1\\nline2'")

      assert {:ok, {:literal, ["tab\there"], []}} = Parser.parse_string_literal("'tab\\there'")
    end

    test "handles unicode escape sequences" do
      assert {:ok, {:literal, ["Hello 世"], []}} = Parser.parse_string_literal("\"Hello \\u4e16\"")
    end

    test "handles all standard escape sequences" do
      assert {:ok, {:literal, ["\b"], []}} = Parser.parse_string_literal("\"\\b\"")
      assert {:ok, {:literal, ["\f"], []}} = Parser.parse_string_literal("\"\\f\"")
      assert {:ok, {:literal, ["\r"], []}} = Parser.parse_string_literal("\"\\r\"")
      assert {:ok, {:literal, ["/"], []}} = Parser.parse_string_literal("\"\\/\"")
    end

    test "handles mixed content strings" do
      assert {:ok, {:literal, ["Mix 'single' and \"double\" quotes"], []}} =
               Parser.parse_string_literal("\"Mix 'single' and \\\"double\\\" quotes\"")
    end

    test "fails on unterminated strings" do
      assert {:error, _} = Parser.parse_string_literal("\"unterminated")
      assert {:error, _} = Parser.parse_string_literal("'unterminated")
    end

    test "fails on invalid escape sequences" do
      assert {:error, _} = Parser.parse_string_literal("\"\\x\"")
      assert {:error, _} = Parser.parse_string_literal("\"\\z\"")
    end
  end
end
