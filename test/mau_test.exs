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
      
      # Should render only first 3 items with custom limit
      assert {:ok, "123"} = Mau.render(template, context, max_loop_iterations: 3)
      
      # Should handle limit larger than collection
      assert {:ok, "12345678910"} = Mau.render(template, context, max_loop_iterations: 20)
    end

    test "default max_loop_iterations is 10000" do
      # Create a large collection to test the default limit
      large_items = Enum.to_list(1..15000)
      template = "{% for item in items %}{{ item }},{% endfor %}"
      context = %{"items" => large_items}
      
      # Should stop at 10000 items with default limit
      {:ok, result} = Mau.render(template, context)
      item_count = (result |> String.split(",") |> length()) - 1  # -1 for empty string at end
      assert item_count == 10000
      
      # Should render all items when limit is explicitly set higher
      {:ok, result_unlimited} = Mau.render(template, context, max_loop_iterations: 20000)
      item_count_unlimited = (result_unlimited |> String.split(",") |> length()) - 1
      assert item_count_unlimited == 15000
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
