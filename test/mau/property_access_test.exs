defmodule Mau.PropertyAccessTest do
  use ExUnit.Case
  alias Mau.Parser

  describe "variable path parsing" do
    test "parses simple identifier as single segment path" do
      assert {:ok, {:variable, ["user"], []}} = Parser.parse_variable_path("user")
    end

    test "parses single property access" do
      assert {:ok, {:variable, ["user", {:property, "name"}], []}} =
               Parser.parse_variable_path("user.name")
    end

    test "parses multiple property accesses" do
      assert {:ok, {:variable, ["user", {:property, "profile"}, {:property, "email"}], []}} =
               Parser.parse_variable_path("user.profile.email")
    end

    test "parses workflow variable with properties" do
      assert {:ok, {:variable, ["$input", {:property, "data"}], []}} =
               Parser.parse_variable_path("$input.data")
    end

    test "parses complex workflow variable path" do
      assert {:ok,
              {:variable,
               [
                 "$variables",
                 {:property, "user_data"},
                 {:property, "settings"},
                 {:property, "theme"}
               ],
               []}} =
               Parser.parse_variable_path("$variables.user_data.settings.theme")
    end

    test "parses identifier with underscores and properties" do
      assert {:ok, {:variable, ["user_info", {:property, "personal_data"}], []}} =
               Parser.parse_variable_path("user_info.personal_data")
    end

    test "parses workflow variable with underscores" do
      assert {:ok, {:variable, ["$user_data", {:property, "profile_info"}], []}} =
               Parser.parse_variable_path("$user_data.profile_info")
    end

    test "fails on empty input" do
      assert {:error, _} = Parser.parse_variable_path("")
    end

    test "fails on malformed property access" do
      assert {:error, _} = Parser.parse_variable_path("user.")
    end

    test "fails on property starting with number" do
      assert {:error, _} = Parser.parse_variable_path("user.123field")
    end
  end
end
