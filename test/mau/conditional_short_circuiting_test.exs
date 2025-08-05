defmodule Mau.ConditionalShortCircuitingTest do
  @moduledoc """
  Tests for conditional short-circuiting behavior.

  These tests ensure that logical operators (and, or) properly
  short-circuit evaluation and don't evaluate unnecessary expressions
  that could cause errors or side effects.
  """

  use ExUnit.Case
  doctest Mau

  describe "AND Short-Circuiting" do
    test "false and undefined_var should not evaluate undefined_var" do
      template = """
      {% if false and undefined_var %}
        Should not appear
      {% else %}
        False and skipped undefined
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "False and skipped undefined")
      refute String.contains?(result, "Should not appear")
    end

    test "false and error_expression should not cause error" do
      # This tests that the error expression is never evaluated
      template = """
      {% if false and (10 / 0 > 5) %}
        Should not appear due to division by zero
      {% else %}
        Short-circuited successfully
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Short-circuited successfully")
      refute String.contains?(result, "Should not appear")
    end

    test "nil and undefined_var should short-circuit" do
      template = """
      {% if nil_value and undefined_var %}
        Should not appear
      {% else %}
        Nil and short-circuited
      {% endif %}
      """

      context = %{"nil_value" => nil}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Nil and short-circuited")
      refute String.contains?(result, "Should not appear")
    end

    test "zero and undefined_var should short-circuit" do
      template = """
      {% if zero_value and undefined_var %}
        Should not appear
      {% else %}
        Zero and short-circuited
      {% endif %}
      """

      context = %{"zero_value" => 0}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Zero and short-circuited")
      refute String.contains?(result, "Should not appear")
    end

    test "empty string and undefined_var should short-circuit" do
      template = """
      {% if empty_string and undefined_var %}
        Should not appear
      {% else %}
        Empty string and short-circuited
      {% endif %}
      """

      context = %{"empty_string" => ""}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Empty string and short-circuited")
      refute String.contains?(result, "Should not appear")
    end

    test "true and undefined_var should evaluate undefined_var" do
      # When first operand is true, second operand must be evaluated
      template = """
      {% if true and undefined_var %}
        Should not appear because undefined_var is falsy
      {% else %}
        True but undefined_var is falsy
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # undefined_var should be treated as nil/falsy
      assert String.contains?(result, "True but undefined_var is falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "truthy and truthy should both be evaluated" do
      template = """
      {% if first_value and second_value %}
        Both values are truthy
      {% else %}
        At least one is falsy
      {% endif %}
      """

      context = %{"first_value" => "hello", "second_value" => 42}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Both values are truthy")
      refute String.contains?(result, "At least one is falsy")
    end

    test "chained and operations with short-circuiting" do
      template = """
      {% if false and undefined_var and another_undefined %}
        Should not appear
      {% else %}
        Chained and short-circuited at first false
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Chained and short-circuited at first false")
      refute String.contains?(result, "Should not appear")
    end
  end

  describe "OR Short-Circuiting" do
    test "true or undefined_var should not evaluate undefined_var" do
      template = """
      {% if true or undefined_var %}
        True or skipped undefined
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "True or skipped undefined")
      refute String.contains?(result, "Should not appear")
    end

    test "true or error_expression should not cause error" do
      template = """
      {% if true or (10 / 0 > 5) %}
        Short-circuited successfully
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Short-circuited successfully")
      refute String.contains?(result, "Should not appear")
    end

    test "truthy string or undefined_var should short-circuit" do
      template = """
      {% if non_empty_string or undefined_var %}
        String or short-circuited
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{"non_empty_string" => "hello"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "String or short-circuited")
      refute String.contains?(result, "Should not appear")
    end

    test "positive number or undefined_var should short-circuit" do
      template = """
      {% if positive_num or undefined_var %}
        Number or short-circuited
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{"positive_num" => 42}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Number or short-circuited")
      refute String.contains?(result, "Should not appear")
    end

    test "false or undefined_var should evaluate undefined_var" do
      # When first operand is false, second operand must be evaluated
      template = """
      {% if false or undefined_var %}
        Should not appear because undefined_var is falsy
      {% else %}
        False or undefined_var both falsy
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # undefined_var should be treated as nil/falsy
      assert String.contains?(result, "False or undefined_var both falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "falsy or truthy should evaluate both" do
      template = """
      {% if false_value or true_value %}
        Second value is truthy
      {% else %}
        Both values are falsy
      {% endif %}
      """

      context = %{"false_value" => false, "true_value" => "hello"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Second value is truthy")
      refute String.contains?(result, "Both values are falsy")
    end

    test "chained or operations with short-circuiting" do
      template = """
      {% if true or undefined_var or another_undefined %}
        Chained or short-circuited at first true
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Chained or short-circuited at first true")
      refute String.contains?(result, "Should not appear")
    end

    test "chained or with all falsy values" do
      template = """
      {% if false or nil_value or zero_value or empty_string %}
        Should not appear
      {% else %}
        All or values are falsy
      {% endif %}
      """

      context = %{
        "nil_value" => nil,
        "zero_value" => 0,
        "empty_string" => ""
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "All or values are falsy")
      refute String.contains?(result, "Should not appear")
    end
  end

  describe "Mixed AND/OR Short-Circuiting" do
    test "false and true or undefined should short-circuit properly" do
      # (false and true) or undefined_var
      # Should short-circuit the 'and' but evaluate the 'or'
      template = """
      {% if false and true or undefined_var %}
        Should not appear
      {% else %}
        Mixed short-circuit handled correctly
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Mixed short-circuit handled correctly")
      refute String.contains?(result, "Should not appear")
    end

    test "true or false and undefined should short-circuit at or" do
      # true or (false and undefined_var)
      # Should short-circuit at 'or' and never evaluate the 'and' part
      template = """
      {% if true or false and undefined_var %}
        Or short-circuited before and
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Or short-circuited before and")
      refute String.contains?(result, "Should not appear")
    end

    test "complex mixed expression with short-circuiting" do
      template = """
      {% if false and error_expr or true and success_var %}
        Complex expression handled
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{"success_var" => "yes"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Complex expression handled")
      refute String.contains?(result, "Should not appear")
    end
  end

  describe "Short-Circuiting with Property Access" do
    test "false and undefined.property should short-circuit" do
      template = """
      {% if false and undefined_object.some_property %}
        Should not appear
      {% else %}
        Property access short-circuited
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Property access short-circuited")
      refute String.contains?(result, "Should not appear")
    end

    test "true or undefined.property should short-circuit" do
      template = """
      {% if true or undefined_object.some_property %}
        Property access short-circuited
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Property access short-circuited")
      refute String.contains?(result, "Should not appear")
    end

    test "nil object and property access should short-circuit" do
      template = """
      {% if nil_object and nil_object.property %}
        Should not appear
      {% else %}
        Nil object short-circuited
      {% endif %}
      """

      context = %{"nil_object" => nil}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Nil object short-circuited")
      refute String.contains?(result, "Should not appear")
    end
  end

  describe "Short-Circuiting with Array Access" do
    test "false and undefined[0] should short-circuit" do
      template = """
      {% if false and undefined_array[0] %}
        Should not appear
      {% else %}
        Array access short-circuited
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Array access short-circuited")
      refute String.contains?(result, "Should not appear")
    end

    test "true or undefined[0] should short-circuit" do
      template = """
      {% if true or undefined_array[0] %}
        Array access short-circuited
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Array access short-circuited")
      refute String.contains?(result, "Should not appear")
    end

    test "empty array and array[0] should short-circuit" do
      template = """
      {% if empty_array and empty_array[0] %}
        Should not appear
      {% else %}
        Empty array short-circuited
      {% endif %}
      """

      context = %{"empty_array" => []}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Empty array short-circuited")
      refute String.contains?(result, "Should not appear")
    end
  end

  describe "Short-Circuiting Performance" do
    test "short-circuiting should not evaluate expensive operations" do
      # This test ensures that short-circuiting actually improves performance
      # by not evaluating expensive expressions
      template = """
      {% if false and complex_calculation %}
        Should not appear
      {% else %}
        Expensive operation avoided
      {% endif %}
      """

      # We don't actually include complex_calculation in context
      # If short-circuiting works, it should never try to access it
      context = %{}

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, result} = Mau.render(template, context)
      end_time = System.monotonic_time(:millisecond)

      assert String.contains?(result, "Expensive operation avoided")
      # Should complete very quickly since expensive operation is skipped
      assert end_time - start_time < 10
    end

    test "multiple short-circuits in sequence" do
      template = """
      {% if false and undefined1 and undefined2 and undefined3 %}
        Should not appear
      {% else %}
        Multiple short-circuits successful
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Multiple short-circuits successful")
      refute String.contains?(result, "Should not appear")
    end
  end

  describe "Short-Circuiting in Loops" do
    test "short-circuiting within loop iterations" do
      template = """
      {% for item in items %}
        {% if item.active and item.permissions.admin %}
          Admin: {{ item.name }}
        {% elsif item.active or item.guest %}
          User: {{ item.name }}
        {% else %}
          Inactive: {{ item.name }}
        {% endif %}
      {% endfor %}
      """

      context = %{
        "items" => [
          %{"name" => "Alice", "active" => true, "permissions" => %{"admin" => true}},
          %{"name" => "Bob", "active" => false, "guest" => true},
          %{"name" => "Charlie", "active" => false, "guest" => false},
          # No permissions object
          %{"name" => "Dave", "active" => true}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Admin: Alice")
      assert String.contains?(result, "User: Bob")
      assert String.contains?(result, "Inactive: Charlie")
      # active=true or guest is short-circuited
      assert String.contains?(result, "User: Dave")
    end
  end
end
