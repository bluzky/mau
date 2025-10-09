defmodule Mau.AtomLiteralTest do
  use ExUnit.Case

  alias Mau.Parser
  alias Mau

  describe "Atom Literal Parsing" do
    test "parses simple atom literals" do
      {:ok, ast} = Parser.parse("{{ :test }}")
      expected_expression = {:literal, [:test], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "parses atom literals with underscores" do
      {:ok, ast} = Parser.parse("{{ :atom_key }}")
      expected_expression = {:literal, [:atom_key], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "parses atom literals with numbers" do
      {:ok, ast} = Parser.parse("{{ :key123 }}")
      expected_expression = {:literal, [:key123], []}
      assert [{:expression, [^expected_expression], []}] = ast
    end

    test "renders atom literals correctly" do
      assert {:ok, ":test"} = Mau.render("{{ :test }}", %{})
      assert {:ok, ":atom_key"} = Mau.render("{{ :atom_key }}", %{})
      assert {:ok, ":key123"} = Mau.render("{{ :key123 }}", %{})
    end
  end

  describe "Atom Key Access" do
    test "accesses map values with atom keys using bracket notation" do
      context = %{
        "user" => %{:name => "Alice", :age => 30, :active => true}
      }

      assert {:ok, "Alice"} = Mau.render("{{ user[:name] }}", context)
      assert {:ok, "30"} = Mau.render("{{ user[:age] }}", context)
      assert {:ok, "true"} = Mau.render("{{ user[:active] }}", context)
    end

    test "accesses root context with atom keys using dot notation" do
      context = %{
        user: %{name: "Dan", age: 25}
      }

      assert {:ok, "Dan"} = Mau.render("{{ user.name }}", context)
      assert {:ok, "25"} = Mau.render("{{ user.age }}", context)
    end

    test "accesses nested atom keys in root context" do
      context = %{
        config: %{database: %{host: "localhost", port: 5432}}
      }

      assert {:ok, "localhost"} = Mau.render("{{ config.database.host }}", context)
      assert {:ok, "5432"} = Mau.render("{{ config.database.port }}", context)
    end

    test "falls back to atom keys when string keys not found" do
      # String key takes precedence
      context = %{
        "user" => %{name: "Alice"},
        user: %{name: "Bob"}
      }

      assert {:ok, "Alice"} = Mau.render("{{ user.name }}", context)

      # Atom key used when string key absent
      context2 = %{user: %{name: "Charlie"}}
      assert {:ok, "Charlie"} = Mau.render("{{ user.name }}", context2)
    end

    test "returns empty string for non-existent atom keys" do
      context = %{"user" => %{:name => "Alice"}}
      assert {:ok, ""} = Mau.render("{{ user[:missing] }}", context)
    end

    test "works with nested atom key access" do
      context = %{
        "config" => %{
          :database => %{:host => "localhost", :port => 5432}
        }
      }

      assert {:ok, "localhost"} = Mau.render("{{ config[:database][:host] }}", context)
      assert {:ok, "5432"} = Mau.render("{{ config[:database][:port] }}", context)
    end

    test "combines with other access patterns" do
      context = %{
        "data" => %{
          :users => [
            %{"name" => "Alice", :id => 1},
            %{"name" => "Bob", :id => 2}
          ]
        }
      }

      assert {:ok, "Alice"} = Mau.render("{{ data[:users][0][\"name\"] }}", context)
      assert {:ok, "2"} = Mau.render("{{ data[:users][1][:id] }}", context)
    end
  end

  describe "String and Integer Key Access" do
    test "accesses map values with string keys" do
      context = %{
        "user" => %{"name" => "Alice", "age" => 30}
      }

      assert {:ok, "Alice"} = Mau.render("{{ user[\"name\"] }}", context)
      assert {:ok, "30"} = Mau.render("{{ user[\"age\"] }}", context)
    end

    test "accesses array values with integer indices" do
      context = %{
        "items" => ["first", "second", "third"]
      }

      assert {:ok, "first"} = Mau.render("{{ items[0] }}", context)
      assert {:ok, "second"} = Mau.render("{{ items[1] }}", context)
      assert {:ok, "third"} = Mau.render("{{ items[2] }}", context)
    end

    test "returns empty string for out-of-bounds indices" do
      context = %{"items" => ["first", "second"]}
      assert {:ok, ""} = Mau.render("{{ items[5] }}", context)
      assert {:ok, ""} = Mau.render("{{ items[-1] }}", context)
    end

    test "handles mixed key types in same template" do
      context = %{
        "data" => %{
          :users => ["Alice", "Bob"],
          "count" => 2,
          :active => true
        }
      }

      template =
        "Users: {{ data[:users][0] }}, {{ data[:users][1] }}. Count: {{ data[\"count\"] }}. Active: {{ data[:active] }}"

      expected = "Users: Alice, Bob. Count: 2. Active: true"
      assert {:ok, ^expected} = Mau.render(template, context)
    end
  end

  describe "Variable Index Support" do
    test "now parses templates with variable indices successfully" do
      # Variable indices are now supported (updated behavior)
      assert {:ok,
              [
                {:expression, [{:variable, ["items", {:index, {:variable, ["index"], []}}], []}],
                 []}
              ]} =
               Parser.parse("{{ items[index] }}")

      assert {:ok,
              [
                {:expression, [{:variable, ["user", {:index, {:variable, ["field"], []}}], []}],
                 []}
              ]} =
               Parser.parse("{{ user[field] }}")

      assert {:ok,
              [
                {:expression, [{:variable, ["data", {:index, {:variable, ["key_var"], []}}], []}],
                 []}
              ]} =
               Parser.parse("{{ data[key_var] }}")
    end

    test "only accepts literal values in array index syntax" do
      # These should parse successfully as expressions
      {:ok, ast1} = Parser.parse("{{ items[0] }}")
      assert [{:expression, [_], []}] = ast1

      {:ok, ast2} = Parser.parse("{{ user[\"key\"] }}")
      assert [{:expression, [_], []}] = ast2

      {:ok, ast3} = Parser.parse("{{ data[:atom] }}")
      assert [{:expression, [_], []}] = ast3
    end

    test "renders variable index templates with undefined variables as empty" do
      # Variable indices now parse successfully but render empty when variables are undefined
      assert {:ok, ""} = Mau.render("{{ items[index] }}", %{})
      assert {:ok, "Value: "} = Mau.render("Value: {{ user[field] }}", %{})
    end
  end
end
