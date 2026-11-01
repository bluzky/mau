defmodule Mau.BooleanIntegrationTest do
  use ExUnit.Case

  alias Mau

  describe "Boolean Expression Integration" do
    test "renders simple comparison expressions" do
      assert {:ok, "true"} = Mau.render("{{ 5 > 3 }}", %{})
      assert {:ok, "false"} = Mau.render("{{ 3 > 5 }}", %{})
      assert {:ok, "true"} = Mau.render("{{ 5 >= 5 }}", %{})
      assert {:ok, "false"} = Mau.render("{{ 3 >= 5 }}", %{})
      assert {:ok, "true"} = Mau.render("{{ 3 < 5 }}", %{})
      assert {:ok, "false"} = Mau.render("{{ 5 < 3 }}", %{})
      assert {:ok, "true"} = Mau.render("{{ 5 <= 5 }}", %{})
      assert {:ok, "false"} = Mau.render("{{ 5 <= 3 }}", %{})
    end

    test "renders equality expressions" do
      assert {:ok, "true"} = Mau.render("{{ 5 == 5 }}", %{})
      assert {:ok, "false"} = Mau.render("{{ 5 == 3 }}", %{})
      assert {:ok, "false"} = Mau.render("{{ 5 != 5 }}", %{})
      assert {:ok, "true"} = Mau.render("{{ 5 != 3 }}", %{})
      assert {:ok, "true"} = Mau.render(~s({{ "hello" == "hello" }}), %{})
      assert {:ok, "false"} = Mau.render(~s({{ "hello" == "world" }}), %{})
    end

    test "renders logical expressions" do
      assert {:ok, "true"} = Mau.render("{{ true and true }}", %{})
      assert {:ok, "false"} = Mau.render("{{ true and false }}", %{})
      assert {:ok, "false"} = Mau.render("{{ false and true }}", %{})
      assert {:ok, "false"} = Mau.render("{{ false and false }}", %{})

      assert {:ok, "true"} = Mau.render("{{ true or true }}", %{})
      assert {:ok, "true"} = Mau.render("{{ true or false }}", %{})
      assert {:ok, "true"} = Mau.render("{{ false or true }}", %{})
      assert {:ok, "false"} = Mau.render("{{ false or false }}", %{})
    end

    test "handles operator precedence correctly" do
      # Arithmetic before comparison
      assert {:ok, "true"} = Mau.render("{{ 2 + 3 > 4 }}", %{})
      assert {:ok, "false"} = Mau.render("{{ 2 + 1 > 4 }}", %{})

      # Comparison before logical
      assert {:ok, "true"} = Mau.render("{{ 5 > 3 and 2 < 4 }}", %{})
      assert {:ok, "false"} = Mau.render("{{ 5 < 3 and 2 < 4 }}", %{})

      # AND before OR
      # true or (false and false) = true or false = true
      assert {:ok, "true"} = Mau.render("{{ true or false and false }}", %{})
      # (false and true) or false = false or false = false
      assert {:ok, "false"} = Mau.render("{{ false and true or false }}", %{})
    end

    test "handles parentheses for precedence override" do
      # (true) and false = false
      assert {:ok, "false"} = Mau.render("{{ (true or false) and false }}", %{})
      # true or (false) = true
      assert {:ok, "true"} = Mau.render("{{ true or (false and false) }}", %{})
      # 5 > 4 = true
      assert {:ok, "true"} = Mau.render("{{ (2 + 3) > (1 + 3) }}", %{})
      # 3 > 4 = false
      assert {:ok, "false"} = Mau.render("{{ (2 + 1) > (1 + 3) }}", %{})
    end

    test "combines with variables" do
      context = %{
        "age" => 25,
        "name" => "Alice",
        "is_admin" => true,
        "is_active" => false,
        "score" => 85
      }

      assert {:ok, "true"} = Mau.render("{{ age > 18 }}", context)
      assert {:ok, "false"} = Mau.render("{{ age < 18 }}", context)
      assert {:ok, "true"} = Mau.render("{{ name == \"Alice\" }}", context)
      assert {:ok, "false"} = Mau.render("{{ name == \"Bob\" }}", context)
      assert {:ok, "false"} = Mau.render("{{ is_admin and is_active }}", context)
      assert {:ok, "true"} = Mau.render("{{ is_admin or is_active }}", context)
    end

    test "combines with complex variable paths" do
      context = %{
        "user" => %{
          "profile" => %{
            "age" => 30,
            "permissions" => ["read", "write"]
          }
        },
        "limits" => %{
          "min_age" => 18,
          "max_age" => 65
        }
      }

      assert {:ok, "true"} = Mau.render("{{ user.profile.age > limits.min_age }}", context)
      assert {:ok, "true"} = Mau.render("{{ user.profile.age < limits.max_age }}", context)

      assert {:ok, "true"} =
               Mau.render(
                 "{{ user.profile.age >= limits.min_age and user.profile.age <= limits.max_age }}",
                 context
               )
    end

    test "works in mixed content templates" do
      context = %{"is_admin" => true, "username" => "Alice"}

      template = "Welcome {{ username }}! Admin: {{ is_admin }}"
      assert {:ok, "Welcome Alice! Admin: true"} = Mau.render(template, context)

      context = %{"is_admin" => false, "username" => "Bob"}
      assert {:ok, "Welcome Bob! Admin: false"} = Mau.render(template, context)
    end

    test "handles string comparisons" do
      assert {:ok, "true"} = Mau.render(~s({{ "apple" < "banana" }}), %{})
      assert {:ok, "false"} = Mau.render(~s({{ "banana" < "apple" }}), %{})
      assert {:ok, "true"} = Mau.render(~s({{ "apple" <= "apple" }}), %{})

      context = %{"fruit1" => "apple", "fruit2" => "banana"}
      assert {:ok, "true"} = Mau.render("{{ fruit1 < fruit2 }}", context)
    end

    test "handles truthiness in logical operations" do
      context = %{
        "empty_string" => "",
        "zero" => 0,
        "empty_list" => [],
        "empty_map" => %{},
        "nil_value" => nil,
        "false_value" => false,
        "non_empty_string" => "hello",
        "positive_number" => 5,
        "non_empty_list" => [1, 2, 3]
      }

      # Falsy values
      assert {:ok, "false"} = Mau.render("{{ nil_value and true }}", context)
      assert {:ok, "false"} = Mau.render("{{ false_value and true }}", context)

      # Truthy values
      assert {:ok, "true"} = Mau.render("{{ empty_string and true }}", context)
      assert {:ok, "true"} = Mau.render("{{ zero and true }}", context)
      assert {:ok, "true"} = Mau.render("{{ empty_list and true }}", context)
      assert {:ok, "true"} = Mau.render("{{ empty_map and true }}", context)
      assert {:ok, "true"} = Mau.render("{{ non_empty_string and true }}", context)
      assert {:ok, "true"} = Mau.render("{{ positive_number and true }}", context)
      assert {:ok, "true"} = Mau.render("{{ non_empty_list and true }}", context)

      # OR with falsy first operand
      assert {:ok, "true"} = Mau.render("{{ nil_value or true }}", context)
      assert {:ok, "false"} = Mau.render("{{ nil_value or false }}", context)
    end

    test "handles complex nested expressions" do
      context = %{
        "user" => %{"age" => 25, "role" => "admin"},
        "min_age" => 18,
        "max_age" => 65,
        "required_role" => "admin"
      }

      # Complex boolean logic: user is valid if age is in range AND has required role
      template =
        "{{ (user.age >= min_age and user.age <= max_age) and user.role == required_role }}"

      assert {:ok, "true"} = Mau.render(template, context)

      # Test with invalid age
      context = %{context | "user" => %{"age" => 15, "role" => "admin"}}
      assert {:ok, "false"} = Mau.render(template, context)

      # Test with invalid role
      context = %{context | "user" => %{"age" => 25, "role" => "user"}}
      assert {:ok, "false"} = Mau.render(template, context)
    end

    test "handles arithmetic within boolean expressions" do
      context = %{"x" => 10, "y" => 5, "threshold" => 12}

      assert {:ok, "true"} = Mau.render("{{ (x + y) > threshold }}", context)
      assert {:ok, "false"} = Mau.render("{{ (x - y) > threshold }}", context)
      assert {:ok, "true"} = Mau.render("{{ (x * y) > threshold }}", context)
      assert {:ok, "false"} = Mau.render("{{ (x / y) > threshold }}", context)
    end

    test "handles multiple boolean expressions in one template" do
      context = %{"a" => 5, "b" => 3, "c" => 7}

      template = "A: {{ a > b }}, B: {{ b < c }}, C: {{ a > b and b < c }}"
      assert {:ok, "A: true, B: true, C: true"} = Mau.render(template, context)

      template = "Max: {{ a > b and a > c }}, Min: {{ b < a and b < c }}"
      assert {:ok, "Max: false, Min: true"} = Mau.render(template, context)
    end

    test "handles error cases gracefully" do
      # Unsupported comparison
      assert {:error, %Mau.Error{type: :runtime, message: message}} =
               Mau.render(~s({{ "hello" > 5 }}), %{})

      assert String.contains?(message, "Unsupported binary operation")

      # Division by zero in boolean context
      assert {:error, %Mau.Error{type: :runtime, message: "Division by zero"}} =
               Mau.render("{{ (5 / 0) > 1 }}", %{})
    end

    test "preserves whitespace around boolean expressions" do
      assert {:ok, "Result: true done"} = Mau.render("Result: {{ 5 > 3 }} done", %{})
      assert {:ok, "Check: false!"} = Mau.render("Check: {{ 3 > 5 }}!", %{})
    end

    test "works with workflow variables" do
      context = %{
        "$input" => %{"score" => 85},
        "$variables" => %{"passing_grade" => 70, "honor_grade" => 90}
      }

      assert {:ok, "true"} = Mau.render("{{ $input.score > $variables.passing_grade }}", context)
      assert {:ok, "false"} = Mau.render("{{ $input.score > $variables.honor_grade }}", context)

      assert {:ok, "true"} =
               Mau.render(
                 "{{ $input.score >= $variables.passing_grade and $input.score < $variables.honor_grade }}",
                 context
               )
    end

    test "handles float zero correctly" do
      assert {:ok, "true"} = Mau.render("{{ 0.0 and true }}", %{})
      assert {:ok, "true"} = Mau.render("{{ 0.1 and true }}", %{})
      assert {:ok, "true"} = Mau.render("{{ -0.1 and true }}", %{})
    end
  end

  describe "Comparison precedence" do
    test "relational operators bind tighter than equality" do
      assert {:ok, "true"} = Mau.render("{{ 1 < 2 == true }}", %{})
      assert {:ok, "true"} = Mau.render("{{ true == 1 < 2 }}", %{})
      assert {:ok, "false"} = Mau.render("{{ 1 == 1 < 2 }}", %{})
      assert {:ok, "true"} = Mau.render("{{ x < y != y < x }}", %{"x" => 1, "y" => 2})
    end

    test "builds the comparison tree with relational operators inside equality" do
      assert {:ok, [{:expression, [{:binary_op, ["==", {:binary_op, ["<", _, _], _}, _], _}], _}]} =
               Mau.Parser.parse("{{ 1 < 2 == true }}")
    end

    test "keeps arithmetic above comparison and logic below it" do
      assert {:ok, "true"} = Mau.render("{{ 1 + 1 < 3 == true }}", %{})
      assert {:ok, "true"} = Mau.render("{{ 1 == 1 and 2 > 1 }}", %{})
      assert {:ok, "true"} = Mau.render("{{ not 1 < 2 == false }}", %{})
    end

    test "comparing a boolean to a number is still an error" do
      assert {:error, %Mau.Error{type: :runtime}} = Mau.render("{{ 1 < 2 < 3 }}", %{})
    end
  end

  describe "Keyword boundaries" do
    @context %{"a" => true, "b" => false, "orb" => "O", "andy" => "A"}

    test "and and or need a word boundary after them" do
      for template <- ["{{ a orb }}", "{{ a andy }}", "{{ a or_b }}", "{{ a or1 }}", "{% if a orb %}T{% endif %}"] do
        assert {:error, %Mau.Error{type: :syntax}} = Mau.render(template, @context, strict_mode: true)
        assert {:ok, ^template} = Mau.render(template, @context)
      end
    end

    test "operators still work next to punctuation and whitespace" do
      assert {:ok, "true"} = Mau.render("{{ a or(b) }}", @context)
      assert {:ok, "false"} = Mau.render("{{ a and(b) }}", @context)
      assert {:ok, "true"} = Mau.render("{{ (a)or(b) }}", @context)
      assert {:ok, "true"} = Mau.render("{{ a or\nb }}", @context)
      assert {:ok, "x"} = Mau.render("{{ a and'x' }}", @context)
    end

    test "variables that start with a keyword work as operands" do
      assert {:ok, "true"} = Mau.render("{{ a or orb }}", @context)
      assert {:ok, "true"} = Mau.render("{{ orb or a }}", @context)
      assert {:ok, "true"} = Mau.render("{{ andy and a }}", @context)
      assert {:ok, "O"} = Mau.render("{{ orb }}", @context)
    end
  end
end
