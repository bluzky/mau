defmodule Mau.ArithmeticIntegrationTest do
  use ExUnit.Case

  alias Mau.Parser
  alias Mau

  describe "Arithmetic Expression Integration" do
    test "parses and renders simple arithmetic in templates" do
      assert {:ok, "7"} = Mau.render("{{ 3 + 4 }}", %{})
      assert {:ok, "6"} = Mau.render("{{ 10 - 4 }}", %{})
      assert {:ok, "15"} = Mau.render("{{ 3 * 5 }}", %{})
      assert {:ok, "4.0"} = Mau.render("{{ 12 / 3 }}", %{})
      assert {:ok, "2"} = Mau.render("{{ 17 % 5 }}", %{})
    end

    test "handles operator precedence in templates" do
      assert {:ok, "14"} = Mau.render("{{ 2 + 3 * 4 }}", %{})
      assert {:ok, "20"} = Mau.render("{{ (2 + 3) * 4 }}", %{})
      assert {:ok, "8.0"} = Mau.render("{{ 10 - 8 / 4 }}", %{})  # 10 - (8/4) = 10 - 2.0 = 8.0
      assert {:ok, "0.5"} = Mau.render("{{ (10 - 8) / 4 }}", %{})
    end

    test "combines arithmetic with variables" do
      context = %{"age" => 25, "years" => 5}
      
      assert {:ok, "30"} = Mau.render("{{ age + years }}", context)
      assert {:ok, "20"} = Mau.render("{{ age - years }}", context)
      assert {:ok, "125"} = Mau.render("{{ age * years }}", context)
      assert {:ok, "5.0"} = Mau.render("{{ age / years }}", context)
    end

    test "combines arithmetic with complex variable paths" do
      context = %{
        "user" => %{"age" => 30},
        "rates" => [2.5, 3.0, 1.8]
      }
      
      assert {:ok, "60"} = Mau.render("{{ user.age * 2 }}", context)
      assert {:ok, "5.5"} = Mau.render("{{ rates[0] + rates[1] }}", context)
    end

    test "handles string concatenation in templates" do
      assert {:ok, "hello world"} = Mau.render(~s({{ "hello" + " world" }}), %{})
      
      context = %{"name" => "Alice", "age" => 25}
      assert {:ok, "Alice is 25"} = Mau.render(~s({{ name + " is " + age }}), context)
    end

    test "works with mixed content templates" do
      context = %{"price" => 19.99, "tax" => 1.5}
      template = "Total: ${{ price + tax }}"
      assert {:ok, "Total: $21.49"} = Mau.render(template, context)
      
      template = "The result of {{ 5 }} + {{ 3 }} is {{ 5 + 3 }}."
      assert {:ok, "The result of 5 + 3 is 8."} = Mau.render(template, %{})
    end

    test "handles complex arithmetic in mixed templates" do
      context = %{"items" => 12, "price" => 9.99}
      template = "Order total: {{ items }} items at ${{ price }} each = ${{ items * price }}"
      assert {:ok, "Order total: 12 items at $9.99 each = $119.88"} = Mau.render(template, context)
    end

    test "handles nested parentheses in templates" do
      assert {:ok, "13.0"} = Mau.render("{{ ((2 + 3) * 4 + 6) / 2 }}", %{})  # (5 * 4 + 6) / 2 = 26 / 2 = 13.0
      assert {:ok, "17"} = Mau.render("{{ 5 + (3 * (2 + 2)) }}", %{})
    end

    test "handles float arithmetic in templates" do
      assert {:ok, "6.28"} = Mau.render("{{ 3.14 * 2 }}", %{})
      assert {:ok, "7.5"} = Mau.render("{{ 15 / 2 }}", %{})
      assert {:ok, "5.59"} = Mau.render("{{ 3.14 + 2.45 }}", %{})
    end

    test "handles negative numbers in templates" do
      assert {:ok, "5"} = Mau.render("{{ -3 + 8 }}", %{})
      assert {:ok, "-15"} = Mau.render("{{ -3 * 5 }}", %{})
      assert {:ok, "12"} = Mau.render("{{ -4 + 16 }}", %{})
    end

    test "handles arithmetic with workflow variables" do
      context = %{"$input" => %{"count" => 10}, "$variables" => %{"multiplier" => 3}}
      
      assert {:ok, "30"} = Mau.render("{{ $input.count * $variables.multiplier }}", context)
      assert {:ok, "13"} = Mau.render("{{ $input.count + $variables.multiplier }}", context)
    end

    test "handles error cases gracefully in templates" do
      # Division by zero
      assert {:error, %Mau.Error{type: :runtime, message: "Division by zero"}} = 
        Mau.render("{{ 5 / 0 }}", %{})
      
      # Unsupported operation
      assert {:error, %Mau.Error{type: :runtime}} = 
        Mau.render(~s({{ "hello" - "world" }}), %{})
    end

    test "handles undefined variables in arithmetic templates" do
      # Should treat undefined as empty string and concatenate
      assert {:ok, "5"} = Mau.render("{{ undefined + 5 }}", %{})
      assert {:ok, "hello"} = Mau.render(~s({{ "hello" + undefined }}), %{})
    end

    test "preserves whitespace around arithmetic expressions" do
      assert {:ok, "Result: 8 done"} = Mau.render("Result: {{ 3 + 5 }} done", %{})
      assert {:ok, "A + B = 7"} = Mau.render("A + B = {{ 3 + 4 }}", %{})
    end

    test "handles multiple arithmetic expressions in one template" do
      template = "{{ 2 + 3 }} + {{ 4 * 5 }} = {{ (2 + 3) + (4 * 5) }}"
      assert {:ok, "5 + 20 = 25"} = Mau.render(template, %{})
    end

    test "works with all arithmetic operators in complex expressions" do
      # Test combining all operators with proper precedence
      template = "{{ 2 + 3 * 4 - 10 / 2 + 15 % 4 }}"
      # 2 + (3 * 4) - (10 / 2) + (15 % 4) = 2 + 12 - 5.0 + 3 = 12.0
      assert {:ok, "12.0"} = Mau.render(template, %{})
    end

    test "parses and renders correctly maintain AST structure" do
      {:ok, ast} = Parser.parse("{{ 2 + 3 * 4 }}")
      
      # Verify AST structure reflects proper precedence
      expected_expression = {:binary_op, ["+", 
        {:literal, [2], []}, 
        {:binary_op, ["*", {:literal, [3], []}, {:literal, [4], []}], []}
      ], []}
      
      assert [{:expression, [^expected_expression], []}] = ast
      
      # Verify it renders correctly
      assert {:ok, "14"} = Mau.render(ast, %{})
    end
  end
end