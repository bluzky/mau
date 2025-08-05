defmodule Mau.ArrayIndexTest do
  use ExUnit.Case
  alias Mau.Parser

  describe "variable path with array indices (literal only)" do
    test "parses simple array index with integer literal" do
      assert {:ok, {:variable, ["users", {:index, {:literal, [0], []}}], []}} = Parser.parse_variable_path("users[0]")
    end

    test "parses multiple array indices" do
      assert {:ok, {:variable, ["matrix", {:index, {:literal, [0], []}}, {:index, {:literal, [1], []}}], []}} = 
        Parser.parse_variable_path("matrix[0][1]")
    end

    test "parses mixed property access and array index" do
      assert {:ok, {:variable, ["user", {:property, "orders"}, {:index, {:literal, [0], []}}], []}} = 
        Parser.parse_variable_path("user.orders[0]")
    end

    test "parses array index followed by property" do
      assert {:ok, {:variable, ["users", {:index, {:literal, [0], []}}, {:property, "name"}], []}} = 
        Parser.parse_variable_path("users[0].name")
    end

    test "parses string key index" do
      assert {:ok, {:variable, ["data", {:index, {:literal, ["key"], []}}], []}} = 
        Parser.parse_variable_path("data[\"key\"]")
    end

    test "parses atom key index" do
      assert {:ok, {:variable, ["config", {:index, {:literal, [:name], []}}], []}} = 
        Parser.parse_variable_path("config[:name]")
    end

    test "parses array index with whitespace" do
      assert {:ok, {:variable, ["users", {:index, {:literal, [0], []}}], []}} = 
        Parser.parse_variable_path("users[ 0 ]")
    end

    test "now supports variable indices (parsing only - see bracket_variable_access_test for evaluation)" do
      assert {:ok, {:variable, ["users", {:index, {:variable, ["i"], []}}], []}} = 
        Parser.parse_variable_path("users[i]")
      assert {:ok, {:variable, ["users", {:index, {:variable, ["index"], []}}], []}} = 
        Parser.parse_variable_path("users[index]")
      assert {:ok, {:variable, ["$input", {:property, "data"}, {:index, {:variable, ["current_index"], []}}, {:property, "value"}], []}} = 
        Parser.parse_variable_path("$input.data[current_index].value")
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