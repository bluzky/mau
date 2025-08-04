defmodule Mau.ArrayIndexTest do
  use ExUnit.Case
  alias Mau.Parser

  describe "variable path with array indices" do
    test "parses simple array index with literal" do
      assert {:ok, {:variable, ["users", {:index, 0}], []}} = Parser.parse_variable_path("users[0]")
    end

    test "parses array index with variable" do
      assert {:ok, {:variable, ["users", {:index, "i"}], []}} = Parser.parse_variable_path("users[i]")
    end

    test "parses multiple array indices" do
      assert {:ok, {:variable, ["matrix", {:index, 0}, {:index, 1}], []}} = Parser.parse_variable_path("matrix[0][1]")
    end

    test "parses mixed property access and array index" do
      assert {:ok, {:variable, ["user", {:property, "orders"}, {:index, 0}], []}} = 
        Parser.parse_variable_path("user.orders[0]")
    end

    test "parses array index followed by property" do
      assert {:ok, {:variable, ["users", {:index, 0}, {:property, "name"}], []}} = 
        Parser.parse_variable_path("users[0].name")
    end

    test "parses complex path with workflow variable" do
      assert {:ok, {:variable, ["$input", {:property, "data"}, {:index, "current_index"}, {:property, "value"}], []}} = 
        Parser.parse_variable_path("$input.data[current_index].value")
    end

    test "parses array index with whitespace" do
      assert {:ok, {:variable, ["users", {:index, 0}], []}} = Parser.parse_variable_path("users[ 0 ]")
    end

    test "parses array index with variable and whitespace" do
      assert {:ok, {:variable, ["users", {:index, "index"}], []}} = Parser.parse_variable_path("users[ index ]")
    end

    test "fails on empty array index" do
      assert {:error, _} = Parser.parse_variable_path("users[]")
    end

    test "fails on unclosed array index" do
      assert {:error, _} = Parser.parse_variable_path("users[0")
    end

    test "fails on unopened array index" do
      assert {:error, _} = Parser.parse_variable_path("users0]")
    end
  end
end