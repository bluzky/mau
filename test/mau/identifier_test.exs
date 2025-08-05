defmodule Mau.IdentifierTest do
  use ExUnit.Case
  alias Mau.Parser

  describe "identifier parsing" do
    test "parses basic identifier" do
      assert {:ok, "user"} = Parser.parse_identifier("user")
    end

    test "parses identifier with underscores" do
      assert {:ok, "user_name"} = Parser.parse_identifier("user_name")
    end

    test "parses identifier with numbers" do
      assert {:ok, "user123"} = Parser.parse_identifier("user123")
    end

    test "parses identifier starting with underscore" do
      assert {:ok, "_private"} = Parser.parse_identifier("_private")
    end

    test "parses workflow variable with $ prefix" do
      assert {:ok, "$input"} = Parser.parse_identifier("$input")
    end

    test "parses complex workflow variable" do
      assert {:ok, "$variables"} = Parser.parse_identifier("$variables")
    end

    test "parses workflow variable with underscores" do
      assert {:ok, "$user_data"} = Parser.parse_identifier("$user_data")
    end

    test "fails on identifier starting with number" do
      assert {:error, _} = Parser.parse_identifier("123user")
    end

    test "fails on identifier with special characters" do
      assert {:error, _} = Parser.parse_identifier("user-name")
    end

    test "fails on empty input" do
      assert {:error, _} = Parser.parse_identifier("")
    end
  end
end
