defmodule Mau.IntegrationTest do
  use ExUnit.Case

  alias Mau

  describe "Expression Integration" do
    test "renders pure text templates" do
      assert {:ok, "Hello world"} = Mau.render("Hello world", %{})
      assert {:ok, ""} = Mau.render("", %{})
      assert {:ok, "Multiple words here"} = Mau.render("Multiple words here", %{})
    end

    test "renders pure expression templates" do
      assert {:ok, "hello"} = Mau.render(~s({{ "hello" }}), %{})
      assert {:ok, "42"} = Mau.render("{{ 42 }}", %{})
      assert {:ok, "true"} = Mau.render("{{ true }}", %{})
      assert {:ok, "false"} = Mau.render("{{ false }}", %{})
      assert {:ok, ""} = Mau.render("{{ null }}", %{})
    end

    test "renders mixed text and expression templates" do
      assert {:ok, "Hello world!"} = Mau.render(~s(Hello {{ "world" }}!), %{})
      assert {:ok, "The answer is 42."} = Mau.render("The answer is {{ 42 }}.", %{})
      assert {:ok, "Status: true"} = Mau.render("Status: {{ true }}", %{})
    end

    test "renders multiple expressions in one template" do
      template = ~s(Name: {{ "John" }}, Age: {{ 30 }}, Active: {{ true }})
      expected = "Name: John, Age: 30, Active: true"
      assert {:ok, ^expected} = Mau.render(template, %{})
    end

    test "renders expressions with various literal types" do
      # String literals
      assert {:ok, "café"} = Mau.render(~s({{ "café" }}), %{})
      assert {:ok, "hello\nworld"} = Mau.render(~s({{ "hello\\nworld" }}), %{})

      # Number literals
      assert {:ok, "3.14"} = Mau.render("{{ 3.14 }}", %{})
      assert {:ok, "-123"} = Mau.render("{{ -123 }}", %{})
      assert {:ok, "1.0e3"} = Mau.render("{{ 1e3 }}", %{})

      # Boolean and null literals
      assert {:ok, "true"} = Mau.render("{{ true }}", %{})
      assert {:ok, "false"} = Mau.render("{{ false }}", %{})
      assert {:ok, ""} = Mau.render("{{ null }}", %{})
    end

    test "handles whitespace in expressions" do
      assert {:ok, "42"} = Mau.render("{{42}}", %{})
      assert {:ok, "42"} = Mau.render("{{ 42 }}", %{})
      assert {:ok, "42"} = Mau.render("{{   42   }}", %{})
      assert {:ok, "42"} = Mau.render("{{\t42\n}}", %{})
    end

    test "compilation and rendering work together" do
      template = ~s(Hello {{ "world" }}!)

      # Compile then render
      assert {:ok, ast} = Mau.compile(template)
      assert {:ok, "Hello world!"} = Mau.render(ast, %{})

      # Direct render
      assert {:ok, "Hello world!"} = Mau.render(template, %{})
    end

    test "error handling for malformed expressions" do
      # Malformed expression blocks
      assert {:ok, "{{ incomplete"} = Mau.render("{{ incomplete", %{})
      assert {:ok, "{ not expression }"} = Mau.render("{ not expression }", %{})
    end

    test "complex mixed content" do
      template = """
      Welcome {{ "John" }}!

      Your score is {{ 95 }} points.
      Premium user: {{ true }}
      Balance: {{ null }}
      """

      expected = """
      Welcome John!

      Your score is 95 points.
      Premium user: true
      Balance: 
      """

      assert {:ok, ^expected} = Mau.render(template, %{})
    end

    test "render_map integration with expressions" do
      data = %{
        greeting: ~s(Hello {{ "world" }}!),
        count: "Items: {{ 42 }}",
        status: "Active: {{ true }}",
        plain: "No expressions here"
      }

      expected = %{
        greeting: "Hello world!",
        count: "Items: 42",
        status: "Active: true",
        plain: "No expressions here"
      }

      assert {:ok, ^expected} = Mau.render_map(data, %{})
    end

    test "nested render_map with expressions" do
      data = %{
        user: %{
          name: ~s({{ "Alice" }}),
          details: %{
            age: "Age: {{ 25 }}",
            active: "Status: {{ true }}"
          }
        },
        system: %{
          version: ~s(v{{ "2.1" }})
        }
      }

      expected = %{
        user: %{
          name: "Alice",
          details: %{
            age: "Age: 25",
            active: "Status: true"
          }
        },
        system: %{
          version: "v2.1"
        }
      }

      assert {:ok, ^expected} = Mau.render_map(data, %{})
    end
  end
end
