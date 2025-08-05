defmodule Mau.DeeplyNestedConditionalsTest do
  @moduledoc """
  Tests for deeply nested conditional structures (3+ levels deep).

  These tests ensure that the template engine can handle complex nested
  conditional logic without stack overflow or performance degradation.
  """

  use ExUnit.Case
  doctest Mau

  describe "Deeply Nested Conditionals" do
    test "3-level nested conditionals - all true" do
      template = """
      {% if a %}
        Level 1
        {% if b %}
          Level 2
          {% if c %}
            Level 3: SUCCESS
          {% endif %}
        {% endif %}
      {% endif %}
      """

      context = %{"a" => true, "b" => true, "c" => true}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Level 1")
      assert String.contains?(result, "Level 2")
      assert String.contains?(result, "Level 3: SUCCESS")
    end

    test "3-level nested conditionals - middle false" do
      template = """
      {% if a %}
        Level 1
        {% if b %}
          Level 2
          {% if c %}
            Level 3: SUCCESS
          {% endif %}
        {% endif %}
      {% endif %}
      """

      context = %{"a" => true, "b" => false, "c" => true}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Level 1")
      refute String.contains?(result, "Level 2")
      refute String.contains?(result, "Level 3: SUCCESS")
    end

    test "4-level nested conditionals" do
      template = """
      {% if a %}
        A
        {% if b %}
          B
          {% if c %}
            C
            {% if d %}
              D: DEEP SUCCESS
            {% endif %}
          {% endif %}
        {% endif %}
      {% endif %}
      """

      context = %{"a" => true, "b" => true, "c" => true, "d" => true}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "A")
      assert String.contains?(result, "B")
      assert String.contains?(result, "C")
      assert String.contains?(result, "D: DEEP SUCCESS")
    end

    test "5-level nested conditionals with mixed conditions" do
      template = """
      {% if user.active %}
        User Active
        {% if user.admin %}
          Admin Panel
          {% if settings.debug %}
            Debug Mode
            {% if environment == "development" %}
              Dev Environment
              {% if feature_flags.advanced %}
                Advanced Features Enabled
              {% endif %}
            {% endif %}
          {% endif %}
        {% endif %}
      {% endif %}
      """

      context = %{
        "user" => %{"active" => true, "admin" => true},
        "settings" => %{"debug" => true},
        "environment" => "development",
        "feature_flags" => %{"advanced" => true}
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "User Active")
      assert String.contains?(result, "Admin Panel")
      assert String.contains?(result, "Debug Mode")
      assert String.contains?(result, "Dev Environment")
      assert String.contains?(result, "Advanced Features Enabled")
    end

    test "nested conditionals with elsif branches" do
      template = """
      {% if level == 1 %}
        Level 1
        {% if sublevel == "a" %}
          Sublevel A
          {% if subsublevel == "alpha" %}
            Subsublevel Alpha
          {% elsif subsublevel == "beta" %}
            Subsublevel Beta
          {% else %}
            Subsublevel Other
          {% endif %}
        {% endif %}
      {% elsif level == 2 %}
        Level 2
      {% else %}
        Default Level
      {% endif %}
      """

      context = %{
        "level" => 1,
        "sublevel" => "a",
        "subsublevel" => "beta"
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Level 1")
      assert String.contains?(result, "Sublevel A")
      assert String.contains?(result, "Subsublevel Beta")
      refute String.contains?(result, "Subsublevel Alpha")
    end

    test "deeply nested with complex expressions" do
      template = """
      {% if score > 90 %}
        Excellent
        {% if bonus_points >= 10 %}
          With Bonus
          {% if achievements.count > 5 %}
            Achievement Master
            {% if total_time < 300 %}
              Speed Demon: {{ user.name }}
            {% endif %}
          {% endif %}
        {% endif %}
      {% endif %}
      """

      context = %{
        "score" => 95,
        "bonus_points" => 15,
        "achievements" => %{"count" => 8},
        "total_time" => 250,
        "user" => %{"name" => "Alice"}
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Excellent")
      assert String.contains?(result, "With Bonus")
      assert String.contains?(result, "Achievement Master")
      assert String.contains?(result, "Speed Demon: Alice")
    end

    test "nested conditionals with logical operators" do
      template = """
      {% if a and b %}
        AB True
        {% if c or d %}
          CD True
          {% if not e and f %}
            Not E and F
            {% if (g == 1 or g == 2) and h != 3 %}
              Complex Logic Success
            {% endif %}
          {% endif %}
        {% endif %}
      {% endif %}
      """

      context = %{
        "a" => true,
        "b" => true,
        "c" => false,
        "d" => true,
        "e" => false,
        "f" => true,
        "g" => 2,
        "h" => 5
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "AB True")
      assert String.contains?(result, "CD True")
      assert String.contains?(result, "Not E and F")
      assert String.contains?(result, "Complex Logic Success")
    end

    test "nested conditionals with early termination" do
      template = """
      {% if level1 %}
        L1
        {% if level2 %}
          L2
          {% if level3 %}
            L3
            {% if level4 %}
              L4: Should not appear
            {% endif %}
          {% endif %}
        {% endif %}
      {% endif %}
      """

      context = %{
        "level1" => true,
        "level2" => true,
        "level3" => false,
        "level4" => true
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "L1")
      assert String.contains?(result, "L2")
      refute String.contains?(result, "L3")
      refute String.contains?(result, "L4: Should not appear")
    end

    test "asymmetric nested structure" do
      template = """
      {% if path == "deep" %}
        {% if step == 1 %}
          {% if valid %}
            {% if confirmed %}
              {% if final %}
                Deep Path Success
              {% endif %}
            {% endif %}
          {% endif %}
        {% endif %}
      {% elsif path == "shallow" %}
        Shallow Path
      {% else %}
        Unknown Path
      {% endif %}
      """

      # Test deep path
      deep_context = %{
        "path" => "deep",
        "step" => 1,
        "valid" => true,
        "confirmed" => true,
        "final" => true
      }

      assert {:ok, result} = Mau.render(template, deep_context)
      assert String.contains?(result, "Deep Path Success")

      # Test shallow path
      shallow_context = %{"path" => "shallow"}

      assert {:ok, result} = Mau.render(template, shallow_context)
      assert String.contains?(result, "Shallow Path")
    end

    test "performance with very deep nesting (6 levels)" do
      template = """
      {% if l1 %}1
        {% if l2 %}2
          {% if l3 %}3
            {% if l4 %}4
              {% if l5 %}5
                {% if l6 %}6: SUCCESS{% endif %}
              {% endif %}
            {% endif %}
          {% endif %}
        {% endif %}
      {% endif %}
      """

      context = %{
        "l1" => true,
        "l2" => true,
        "l3" => true,
        "l4" => true,
        "l5" => true,
        "l6" => true
      }

      # Should complete without performance issues
      start_time = System.monotonic_time(:millisecond)
      assert {:ok, result} = Mau.render(template, context)
      end_time = System.monotonic_time(:millisecond)

      assert String.contains?(result, "6: SUCCESS")
      # Should complete within reasonable time (less than 100ms)
      assert end_time - start_time < 100
    end
  end

  describe "Deeply Nested with Mixed Content" do
    test "nested conditionals with text and expressions" do
      template = """
      Welcome {{ user.name }}!
      {% if user.premium %}
        <div class="premium">
          Premium features available
          {% if user.plan == "pro" %}
            <div class="pro">
              Pro plan active
              {% if user.trial_days > 0 %}
                <span>{{ user.trial_days }} trial days remaining</span>
              {% else %}
                <span>Full access enabled</span>
              {% endif %}
            </div>
          {% endif %}
        </div>
      {% else %}
        <div class="basic">Basic plan</div>
      {% endif %}
      """

      context = %{
        "user" => %{
          "name" => "John",
          "premium" => true,
          "plan" => "pro",
          "trial_days" => 0
        }
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Welcome John!")
      assert String.contains?(result, "Premium features available")
      assert String.contains?(result, "Pro plan active")
      assert String.contains?(result, "Full access enabled")
      refute String.contains?(result, "trial days remaining")
    end
  end
end
