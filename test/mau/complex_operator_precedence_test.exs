defmodule Mau.ComplexOperatorPrecedenceTest do
  @moduledoc """
  Tests for complex operator precedence in conditional expressions.

  These tests ensure that logical operators (and, or), comparison operators,
  arithmetic operators, and parentheses are evaluated in the correct order
  according to standard precedence rules.
  """

  use ExUnit.Case
  doctest Mau

  describe "Basic Logical Operator Precedence" do
    test "and has higher precedence than or" do
      # a or b and c should be evaluated as: a or (b and c)
      template = """
      {% if false or true and false %}
        Should not appear
      {% else %}
        And has higher precedence than or
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # false or (true and false) = false or false = false
      assert String.contains?(result, "And has higher precedence than or")
      refute String.contains?(result, "Should not appear")
    end

    test "and precedence with multiple operands" do
      # a or b and c or d should be: a or (b and c) or d
      template = """
      {% if false or false and true or false %}
        Should not appear
      {% else %}
        Complex and/or precedence correct
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # false or (false and true) or false = false or false or false = false
      assert String.contains?(result, "Complex and/or precedence correct")
      refute String.contains?(result, "Should not appear")
    end

    test "and precedence changes result" do
      # true or false and false should be: true or (false and false) = true
      template = """
      {% if true or false and false %}
        And precedence makes this true
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # true or (false and false) = true or false = true
      assert String.contains?(result, "And precedence makes this true")
      refute String.contains?(result, "Should not appear")
    end

    test "left-to-right evaluation within same precedence" do
      # a and b and c should be: (a and b) and c
      template = """
      {% if true and true and false %}
        Should not appear
      {% else %}
        Left-to-right evaluation correct
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # (true and true) and false = true and false = false
      assert String.contains?(result, "Left-to-right evaluation correct")
      refute String.contains?(result, "Should not appear")
    end
  end

  describe "Parentheses Override Precedence" do
    test "parentheses force or before and" do
      # (a or b) and c should override natural precedence
      template = """
      {% if (false or true) and false %}
        Should not appear
      {% else %}
        Parentheses override precedence
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # (false or true) and false = true and false = false
      assert String.contains?(result, "Parentheses override precedence")
      refute String.contains?(result, "Should not appear")
    end

    test "parentheses change evaluation result" do
      # Compare: a or b and c vs (a or b) and c
      template1 = """
      {% if false or true and true %}Without parens: true{% endif %}
      """

      template2 = """
      {% if (false or true) and true %}With parens: true{% endif %}
      """

      context = %{}

      assert {:ok, result1} = Mau.render(template1, context)
      assert {:ok, result2} = Mau.render(template2, context)

      # false or (true and true) = false or true = true
      assert String.contains?(result1, "Without parens: true")
      # (false or true) and true = true and true = true
      assert String.contains?(result2, "With parens: true")
    end

    test "nested parentheses" do
      # ((a or b) and (c or d)) or e
      template = """
      {% if ((false or true) and (false or false)) or false %}
        Should not appear
      {% else %}
        Nested parentheses evaluated correctly
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # ((false or true) and (false or false)) or false
      # = (true and false) or false = false or false = false
      assert String.contains?(result, "Nested parentheses evaluated correctly")
      refute String.contains?(result, "Should not appear")
    end

    test "multiple levels of parentheses nesting" do
      # (((a and b) or (c and d)) and ((e or f) and (g or h)))
      template = """
      {% if (((true and false) or (true and true)) and ((false or true) and (true or false))) %}
        Complex nested parentheses work
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # (((true and false) or (true and true)) and ((false or true) and (true or false)))
      # = ((false or true) and (true and true)) = (true and true) = true
      assert String.contains?(result, "Complex nested parentheses work")
      refute String.contains?(result, "Should not appear")
    end
  end

  describe "Comparison Operators with Logical Operators" do
    test "comparison operators have higher precedence than logical" do
      # a == b and c == d should be: (a == b) and (c == d)
      template = """
      {% if 1 == 1 and 2 == 3 %}
        Should not appear
      {% else %}
        Comparison before logical
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # (1 == 1) and (2 == 3) = true and false = false
      assert String.contains?(result, "Comparison before logical")
      refute String.contains?(result, "Should not appear")
    end

    test "mixed comparison and logical operators" do
      # a > b or c < d and e == f
      # Should be: (a > b) or ((c < d) and (e == f))
      template = """
      {% if 5 > 10 or 3 < 8 and 4 == 4 %}
        Mixed operators evaluated correctly
      {% else %}
        Should not appear  
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # (5 > 10) or ((3 < 8) and (4 == 4)) = false or (true and true) = false or true = true
      assert String.contains?(result, "Mixed operators evaluated correctly")
      refute String.contains?(result, "Should not appear")
    end

    test "string comparisons with logical operators" do
      template = """
      {% if "apple" < "banana" and "zebra" > "apple" or "test" == "test" %}
        String comparisons with logical work
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # ("apple" < "banana" and "zebra" > "apple") or "test" == "test"
      # = (true and true) or true = true or true = true
      assert String.contains?(result, "String comparisons with logical work")
      refute String.contains?(result, "Should not appear")
    end
  end

  describe "Arithmetic Operators with Logical Operators" do
    test "arithmetic has higher precedence than comparison" do
      # a + b > c * d should be: (a + b) > (c * d)
      template = """
      {% if 2 + 3 > 2 * 2 %}
        Arithmetic before comparison
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # (2 + 3) > (2 * 2) = 5 > 4 = true
      assert String.contains?(result, "Arithmetic before comparison")
      refute String.contains?(result, "Should not appear")
    end

    test "complex arithmetic with logical operators" do
      # a * b + c > d - e and f / g == h
      template = """
      {% if 2 * 3 + 1 > 10 - 3 and 8 / 2 == 4 %}
        Complex arithmetic with logical
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # ((2 * 3) + 1) > (10 - 3) and (8 / 2) == 4
      # = (6 + 1) > 7 and 4.0 == 4 = 7 > 7 and true = false and true = false
      assert String.contains?(result, "Should not appear")
      refute String.contains?(result, "Complex arithmetic with logical")
    end

    test "parentheses override arithmetic precedence" do
      # (a + b) * c vs a + b * c
      template1 = """
      {% if (2 + 3) * 2 == 10 %}Parentheses: true{% endif %}
      """

      template2 = """
      {% if 2 + 3 * 2 == 8 %}No parentheses: true{% endif %}
      """

      context = %{}

      assert {:ok, result1} = Mau.render(template1, context)
      assert {:ok, result2} = Mau.render(template2, context)

      # (2 + 3) * 2 = 5 * 2 = 10
      assert String.contains?(result1, "Parentheses: true")
      # 2 + (3 * 2) = 2 + 6 = 8
      assert String.contains?(result2, "No parentheses: true")
    end
  end

  describe "Unary Operators with Precedence" do
    test "not operator with logical operators" do
      # not a and b should be: (not a) and b
      template = """
      {% if not false and true %}
        Not has higher precedence
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # (not false) and true = true and true = true
      assert String.contains?(result, "Not has higher precedence")
      refute String.contains?(result, "Should not appear")
    end

    test "not with parentheses" do
      # not (a and b) vs (not a) and b
      template1 = """
      {% if not (true and false) %}Not with parens: true{% endif %}
      """

      template2 = """
      {% if (not true) and false %}Not without parens: true{% endif %}
      """

      context = %{}

      assert {:ok, result1} = Mau.render(template1, context)
      assert {:ok, result2} = Mau.render(template2, context)

      # not (true and false) = not false = true
      assert String.contains?(result1, "Not with parens: true")
      # (not true) and false = false and false = false
      refute String.contains?(result2, "Not without parens: true")
    end

    test "multiple not operators" do
      # not not a should be: not (not a)
      template = """
      {% if not not true %}
        Double not works
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # not (not true) = not false = true
      assert String.contains?(result, "Double not works")
      refute String.contains?(result, "Should not appear")
    end
  end

  describe "Variable Access with Precedence" do
    test "property access in complex expressions" do
      # user.active and user.role == "admin"
      template = """
      {% if user.active and user.role == "admin" %}
        Admin user is active
      {% else %}
        Not active admin
      {% endif %}
      """

      context = %{
        "user" => %{"active" => true, "role" => "admin"}
      }

      assert {:ok, result} = Mau.render(template, context)
      # user.active and (user.role == "admin") = true and true = true
      assert String.contains?(result, "Admin user is active")
      refute String.contains?(result, "Not active admin")
    end

    test "array access in complex expressions" do
      # items[0] > 5 and items[1] < 10
      template = """
      {% if items[0] > 5 and items[1] < 10 %}
        Array conditions met
      {% else %}
        Array conditions not met
      {% endif %}
      """

      context = %{"items" => [8, 7, 15]}

      assert {:ok, result} = Mau.render(template, context)
      # (items[0] > 5) and (items[1] < 10) = (8 > 5) and (7 < 10) = true and true = true
      assert String.contains?(result, "Array conditions met")
      refute String.contains?(result, "Array conditions not met")
    end

    test "nested property access with precedence" do
      # config.database.enabled and config.cache.type == "redis"
      template = """
      {% if config.database.enabled and config.cache.type == "redis" %}
        Database and Redis cache enabled
      {% else %}
        Configuration mismatch
      {% endif %}
      """

      context = %{
        "config" => %{
          "database" => %{"enabled" => true},
          "cache" => %{"type" => "redis"}
        }
      }

      assert {:ok, result} = Mau.render(template, context)
      # config.database.enabled and (config.cache.type == "redis")
      # = true and true = true
      assert String.contains?(result, "Database and Redis cache enabled")
      refute String.contains?(result, "Configuration mismatch")
    end
  end

  describe "Complex Real-World Precedence Scenarios" do
    test "user permissions and role-based access" do
      # (user.active and user.role == "admin") or (user.role == "moderator" and user.permissions.moderate)
      template = """
      {% if user.active and user.role == "admin" or user.role == "moderator" and user.permissions.moderate %}
        Access granted
      {% else %}
        Access denied
      {% endif %}
      """

      # Test admin user
      admin_context = %{
        "user" => %{
          "active" => true,
          "role" => "admin",
          "permissions" => %{"moderate" => false}
        }
      }

      assert {:ok, admin_result} = Mau.render(template, admin_context)

      # (user.active and user.role == "admin") or (user.role == "moderator" and user.permissions.moderate)
      # = (true and true) or (false and false) = true or false = true
      assert String.contains?(admin_result, "Access granted")

      # Test moderator user with permissions
      mod_context = %{
        "user" => %{
          "active" => false,
          "role" => "moderator",
          "permissions" => %{"moderate" => true}
        }
      }

      assert {:ok, mod_result} = Mau.render(template, mod_context)
      # (false and false) or (true and true) = false or true = true
      assert String.contains?(mod_result, "Access granted")

      # Test regular user
      user_context = %{
        "user" => %{
          "active" => true,
          "role" => "user",
          "permissions" => %{"moderate" => false}
        }
      }

      assert {:ok, user_result} = Mau.render(template, user_context)
      # (true and false) or (false and false) = false or false = false
      assert String.contains?(user_result, "Access denied")
    end

    test "feature flags and environment conditions" do
      # env == "production" and features.new_ui or env == "staging" and features.beta_features
      template = """
      {% if env == "production" and features.new_ui or env == "staging" and features.beta_features %}
        Feature enabled
      {% else %}
        Feature disabled
      {% endif %}
      """

      production_context = %{
        "env" => "production",
        "features" => %{"new_ui" => true, "beta_features" => false}
      }

      assert {:ok, prod_result} = Mau.render(template, production_context)
      # (env == "production" and features.new_ui) or (env == "staging" and features.beta_features)
      # = (true and true) or (false and false) = true or false = true
      assert String.contains?(prod_result, "Feature enabled")

      staging_context = %{
        "env" => "staging",
        "features" => %{"new_ui" => false, "beta_features" => true}
      }

      assert {:ok, staging_result} = Mau.render(template, staging_context)
      # (false and false) or (true and true) = false or true = true
      assert String.contains?(staging_result, "Feature enabled")
    end

    test "numeric calculations with comparisons and logic" do
      # score * multiplier > threshold and bonus_points + base_score >= min_score or vip_status
      template = """
      {% if score * multiplier > threshold and bonus_points + base_score >= min_score or vip_status %}
        Qualification met
      {% else %}
        Qualification failed
      {% endif %}
      """

      context = %{
        "score" => 85,
        "multiplier" => 1.2,
        "threshold" => 100,
        "bonus_points" => 20,
        "base_score" => 75,
        "min_score" => 90,
        "vip_status" => false
      }

      assert {:ok, result} = Mau.render(template, context)

      # ((score * multiplier) > threshold) and ((bonus_points + base_score) >= min_score) or vip_status
      # = ((85 * 1.2) > 100) and ((20 + 75) >= 90) or false
      # = (102.0 > 100) and (95 >= 90) or false = true and true or false = true
      assert String.contains?(result, "Qualification met")
    end
  end

  describe "Edge Cases and Error Conditions" do
    test "precedence with undefined variables" do
      # undefined_var and true or false should handle gracefully
      template = """
      {% if undefined_var and true or false %}
        Should not appear
      {% else %}
        Undefined handled in precedence
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # (undefined_var and true) or false = (nil and true) or false = false or false = false
      assert String.contains?(result, "Undefined handled in precedence")
      refute String.contains?(result, "Should not appear")
    end

    test "precedence with nil values" do
      # nil_val == nil and true or false
      template = """
      {% if nil_val == nil and true or false %}
        Nil comparison with precedence
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{"nil_val" => nil}

      assert {:ok, result} = Mau.render(template, context)
      # (nil_val == nil and true) or false = (true and true) or false = true
      assert String.contains?(result, "Nil comparison with precedence")
      refute String.contains?(result, "Should not appear")
    end
  end
end
