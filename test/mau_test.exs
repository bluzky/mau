defmodule MauTest do
  use ExUnit.Case
  doctest Mau

  describe "Integration Tests - Group 1: Plain Text Templates" do
    test "compile and render plain text" do
      assert {:ok, [{:text, ["Hello world"], []}]} = Mau.compile("Hello world")
      assert {:ok, "Hello world"} = Mau.render("Hello world", %{})
    end

    test "compile with strict mode returns warnings tuple" do
      assert {:ok, [{:text, ["Hello"], []}], []} = Mau.compile("Hello", strict_mode: true)
    end

    test "compile with ease mode returns simple tuple" do
      assert {:ok, [{:text, ["Hello"], []}]} = Mau.compile("Hello", strict_mode: false)
    end

    test "render_map with plain text values" do
      input = %{
        message: "Hello world",
        title: "Welcome",
        nested: %{
          content: "Nested content"
        }
      }

      expected = %{
        message: "Hello world",
        title: "Welcome",
        nested: %{
          content: "Nested content"
        }
      }

      assert {:ok, ^expected} = Mau.render_map(input, %{})
    end

    test "render_map preserves non-string values" do
      input = %{
        text: "Hello",
        number: 42,
        boolean: true,
        list: [1, 2, 3],
        nil_value: nil
      }

      assert {:ok, ^input} = Mau.render_map(input, %{})
    end

    @tag :render_map_array
    test "render_map processes arrays with template strings" do
      input = %{
        messages: [
          "Hello {{ name }}!",
          "Count: {{ count }}",
          "Status: {{ active }}"
        ],
        plain_list: [1, 2, 3]
      }

      context = %{
        "name" => "world",
        "count" => 42,
        "active" => true
      }

      expected = %{
        messages: [
          "Hello world!",
          "Count: 42",
          "Status: true"
        ],
        plain_list: [1, 2, 3]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    @tag :render_map_array
    test "render_map processes nested arrays with template strings" do
      input = %{
        nested_arrays: [
          ["Hello {{ user.name }}!", "Count: {{ items | length }}"],
          ["Status: {{ user.active }}", "Value: {{ nil_value }}"]
        ],
        mixed_nested: [
          %{
            message: "{{ greeting }} {{ user.name }}!"
          },
          [
            "Nested: {{ nested.value }}",
            %{
              deep: [
                "Deep: {{ user.active }}",
                "Deeper: {{ nested.deep_value }}"
              ]
            }
          ]
        ]
      }

      context = %{
        "greeting" => "Hello",
        "user" => %{
          "name" => "world",
          "active" => true
        },
        "items" => [1, 2, 3, 4, 5],
        "nil_value" => nil,
        "nested" => %{
          "value" => 123,
          "deep_value" => 456
        }
      }

      expected = %{
        nested_arrays: [
          ["Hello world!", "Count: 5"],
          ["Status: true", "Value: "]
        ],
        mixed_nested: [
          %{
            message: "Hello world!"
          },
          [
            "Nested: 123",
            %{
              deep: [
                "Deep: true",
                "Deeper: 456"
              ]
            }
          ]
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end

  describe "Options - max_template_size and max_loop_iterations" do
    test "max_template_size limits template compilation" do
      large_template = String.duplicate("Hello", 1000)
      
      # Should compile with default (no limit)
      assert {:ok, _} = Mau.compile(large_template)
      
      # Should fail with small limit
      assert {:error, error} = Mau.compile(large_template, max_template_size: 10)
      assert error.message =~ "Template size"
      assert error.message =~ "exceeds maximum 10 bytes"
    end

    test "max_template_size limits template rendering" do
      large_template = String.duplicate("Hello", 1000)
      
      # Should render with default (no limit)
      assert {:ok, _} = Mau.render(large_template, %{})
      
      # Should fail with small limit
      assert {:error, error} = Mau.render(large_template, %{}, max_template_size: 10)
      assert error.message =~ "Template size"
      assert error.message =~ "exceeds maximum 10 bytes"
    end

    test "max_loop_iterations limits loop processing" do
      template = "{% for item in items %}{{ item }}{% endfor %}"
      context = %{"items" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]}
      
      # Should render all items with default limit (10000)
      assert {:ok, "12345678910"} = Mau.render(template, context)
      
      # Should fail when custom limit is exceeded
      assert {:error, error} = Mau.render(template, context, max_loop_iterations: 3)
      assert error.message =~ "Loop iteration count 10 exceeds maximum 3"
      
      # Should handle limit larger than collection
      assert {:ok, "12345678910"} = Mau.render(template, context, max_loop_iterations: 20)
    end

    test "default max_loop_iterations is 10000" do
      # Create a large collection to test the default limit
      large_items = Enum.to_list(1..15000)
      template = "{% for item in items %}{{ item }},{% endfor %}"
      context = %{"items" => large_items}
      
      # Should fail with default limit (10000) when collection exceeds limit
      assert {:error, error} = Mau.render(template, context)
      assert error.message =~ "Loop iteration count 15000 exceeds maximum 10000"
      
      # Should render all items when limit is explicitly set higher
      {:ok, result_unlimited} = Mau.render(template, context, max_loop_iterations: 20000)
      item_count_unlimited = (result_unlimited |> String.split(",") |> length()) - 1
      assert item_count_unlimited == 15000
    end

    test "loops within default limit work correctly" do
      # Create a collection within the default limit
      items = Enum.to_list(1..5000)
      template = "{% for item in items %}{{ item }},{% endfor %}"
      context = %{"items" => items}
      
      # Should render successfully with default limit
      {:ok, result} = Mau.render(template, context)
      item_count = (result |> String.split(",") |> length()) - 1  # -1 for empty string at end
      assert item_count == 5000
    end

    test "max_template_size accepts zero and negative values gracefully" do
      template = "Hello"
      
      # Should ignore invalid limits
      assert {:ok, _} = Mau.compile(template, max_template_size: 0)
      assert {:ok, _} = Mau.compile(template, max_template_size: -1)
      assert {:ok, _} = Mau.render(template, %{}, max_template_size: 0)
      assert {:ok, _} = Mau.render(template, %{}, max_template_size: -1)
    end
  end
end
