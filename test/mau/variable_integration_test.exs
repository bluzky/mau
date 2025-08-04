defmodule Mau.VariableIntegrationTest do
  use ExUnit.Case
  alias Mau.Parser
  alias Mau

  describe "variable integration tests" do
    test "parses and renders simple variable expression" do
      template = "{{ user }}"
      context = %{"user" => "Alice"}
      
      assert {:ok, [ast_node]} = Parser.parse(template)
      {:expression, [variable_ast], []} = ast_node
      assert {:variable, ["user"], []} = variable_ast
      
      assert {:ok, "Alice"} = Mau.render(template, context)
    end

    test "parses and renders property access expression" do
      template = "{{ user.name }}"
      context = %{"user" => %{"name" => "Bob"}}
      
      assert {:ok, [ast_node]} = Parser.parse(template)
      {:expression, [variable_ast], []} = ast_node
      assert {:variable, ["user", {:property, "name"}], []} = variable_ast
      
      assert {:ok, "Bob"} = Mau.render(template, context)
    end

    test "parses and renders array index expression" do
      template = "{{ users[0] }}"
      context = %{"users" => ["Alice", "Bob"]}
      
      assert {:ok, [ast_node]} = Parser.parse(template)
      {:expression, [variable_ast], []} = ast_node
      assert {:variable, ["users", {:index, 0}], []} = variable_ast
      
      assert {:ok, "Alice"} = Mau.render(template, context)
    end

    test "parses and renders workflow variable" do
      template = "{{ $input.data }}"
      context = %{"$input" => %{"data" => "workflow data"}}
      
      assert {:ok, [ast_node]} = Parser.parse(template)
      {:expression, [variable_ast], []} = ast_node
      assert {:variable, ["$input", {:property, "data"}], []} = variable_ast
      
      assert {:ok, "workflow data"} = Mau.render(template, context)
    end

    test "renders mixed content with variables and text" do
      template = "Hello {{ user.name }}! You have {{ count }} messages."
      context = %{
        "user" => %{"name" => "Alice"},
        "count" => 5
      }
      
      assert {:ok, "Hello Alice! You have 5 messages."} = Mau.render(template, context)
    end

    test "renders complex nested access" do
      template = "{{ users[0].profile.email }}"
      context = %{
        "users" => [
          %{"profile" => %{"email" => "alice@example.com"}},
          %{"profile" => %{"email" => "bob@example.com"}}
        ]
      }
      
      assert {:ok, "alice@example.com"} = Mau.render(template, context)
    end

    test "renders workflow variables with complex paths" do
      template = "{{ $variables.settings.theme }}"
      context = %{
        "$variables" => %{
          "settings" => %{
            "theme" => "dark",
            "language" => "en"
          }
        }
      }
      
      assert {:ok, "dark"} = Mau.render(template, context)
    end

    test "handles undefined variables gracefully" do
      template = "{{ undefined_var }}"
      context = %{}
      
      assert {:ok, ""} = Mau.render(template, context)
    end

    test "handles undefined properties gracefully" do
      template = "{{ user.undefined_property }}"
      context = %{"user" => %{"name" => "Alice"}}
      
      assert {:ok, ""} = Mau.render(template, context)
    end

    test "handles mixed literals and variables" do
      template = ~s(Number: {{ 42 }}, User: {{ user }}, Bool: {{ true }})
      context = %{"user" => "Alice"}
      
      assert {:ok, "Number: 42, User: Alice, Bool: true"} = Mau.render(template, context)
    end

    test "parses variables with underscores" do
      template = "{{ user_name }}"
      context = %{"user_name" => "alice_smith"}
      
      assert {:ok, "alice_smith"} = Mau.render(template, context)
    end

    test "parses workflow variables with underscores" do
      template = "{{ $user_data.profile_info }}"
      context = %{"$user_data" => %{"profile_info" => "public"}}
      
      assert {:ok, "public"} = Mau.render(template, context)
    end

    test "parses multiple array indices" do
      template = "{{ matrix[1][2] }}"
      context = %{"matrix" => [[1, 2, 3], [4, 5, 6], [7, 8, 9]]}
      
      assert {:ok, "6"} = Mau.render(template, context)
    end

    test "formats different data types correctly" do
      template = "String: {{ str }}, Number: {{ num }}, Bool: {{ bool }}, Nil: {{ nil_val }}"
      context = %{
        "str" => "hello",
        "num" => 42.5,
        "bool" => false,
        "nil_val" => nil
      }
      
      assert {:ok, "String: hello, Number: 42.5, Bool: false, Nil: "} = Mau.render(template, context)
    end
  end
end