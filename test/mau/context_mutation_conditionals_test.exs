defmodule Mau.ContextMutationConditionalsTest do
  @moduledoc """
  Tests for context mutation within conditional blocks.

  These tests ensure that variable assignments and other context
  mutations within conditional blocks work correctly and maintain
  proper scope behavior.
  """

  use ExUnit.Case
  doctest Mau

  describe "Basic Context Mutation in Conditionals" do
    test "assign within if block affects subsequent output" do
      template = """
      Before: {{ x }}
      {% if condition %}
        {% assign x = "changed" %}
        Inside if: {{ x }}
      {% endif %}
      After: {{ x }}
      """

      context = %{"condition" => true, "x" => "original"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Before: original")
      assert String.contains?(result, "Inside if: changed")
      assert String.contains?(result, "After: changed")
    end

    test "assign within false if block does not affect output" do
      template = """
      Before: {{ x }}
      {% if condition %}
        {% assign x = "changed" %}
        Inside if: {{ x }}
      {% endif %}
      After: {{ x }}
      """

      context = %{"condition" => false, "x" => "original"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Before: original")
      refute String.contains?(result, "Inside if:")
      assert String.contains?(result, "After: original")
    end

    test "assign within else block affects output" do
      template = """
      Before: {{ x }}
      {% if condition %}
        {% assign x = "if_branch" %}
      {% else %}
        {% assign x = "else_branch" %}
      {% endif %}
      After: {{ x }}
      """

      context = %{"condition" => false, "x" => "original"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Before: original")
      assert String.contains?(result, "After: else_branch")
      refute String.contains?(result, "if_branch")
    end

    test "assign within elsif block affects output" do
      template = """
      Before: {{ x }}
      {% if condition1 %}
        {% assign x = "main_if_branch" %}
      {% elsif condition2 %}
        {% assign x = "elsif_branch" %}
      {% else %}
        {% assign x = "else_branch" %}
      {% endif %}
      After: {{ x }}
      """

      context = %{"condition1" => false, "condition2" => true, "x" => "original"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Before: original")
      assert String.contains?(result, "After: elsif_branch")
      refute String.contains?(result, "main_if_branch")
      refute String.contains?(result, "else_branch")
    end
  end

  describe "Multiple Assignments in Conditionals" do
    test "multiple assignments within same if block" do
      template = """
      {% if condition %}
        {% assign x = "first" %}
        {% assign y = "second" %}
        {% assign x = "updated" %}
      {% endif %}
      X: {{ x }}, Y: {{ y }}
      """

      context = %{"condition" => true}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "X: updated, Y: second")
    end

    test "assignments in different conditional branches" do
      template = """
      {% if mode == "a" %}
        {% assign result = "mode_a" %}
        {% assign count = 1 %}
      {% elsif mode == "b" %}
        {% assign result = "mode_b" %}
        {% assign count = 2 %}
      {% else %}
        {% assign result = "default" %}
        {% assign count = 0 %}
      {% endif %}
      Result: {{ result }}, Count: {{ count }}
      """

      # Test mode a
      context_a = %{"mode" => "a"}
      assert {:ok, result_a} = Mau.render(template, context_a)
      assert String.contains?(result_a, "Result: mode_a, Count: 1")

      # Test mode b
      context_b = %{"mode" => "b"}
      assert {:ok, result_b} = Mau.render(template, context_b)
      assert String.contains?(result_b, "Result: mode_b, Count: 2")

      # Test default
      context_default = %{"mode" => "c"}
      assert {:ok, result_default} = Mau.render(template, context_default)
      assert String.contains?(result_default, "Result: default, Count: 0")
    end

    test "assignments with expressions and calculations" do
      template = """
      {% if calculate %}
        {% assign total = base + bonus %}
        {% assign multiplied = total * factor %}
        {% assign message = "Calculated: " %}
      {% endif %}
      {{ message }}{{ multiplied }}
      """

      context = %{"calculate" => true, "base" => 100, "bonus" => 50, "factor" => 2}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Calculated: 300")
    end
  end

  describe "Nested Conditional Mutations" do
    test "nested if statements with assignments" do
      template = """
      {% if outer_condition %}
        {% assign level = "outer" %}
        {% if inner_condition %}
          {% assign level = "inner" %}
          {% assign status = "deep" %}
        {% endif %}
      {% endif %}
      Level: {{ level }}, Status: {{ status }}
      """

      # Both conditions true
      context_both = %{"outer_condition" => true, "inner_condition" => true}
      assert {:ok, result_both} = Mau.render(template, context_both)
      assert String.contains?(result_both, "Level: inner, Status: deep")

      # Only outer true
      context_outer = %{"outer_condition" => true, "inner_condition" => false}
      assert {:ok, result_outer} = Mau.render(template, context_outer)
      # status is undefined/empty
      assert String.contains?(result_outer, "Level: outer, Status:")

      # Neither true
      context_neither = %{"outer_condition" => false, "inner_condition" => false}
      assert {:ok, result_neither} = Mau.render(template, context_neither)
      # both undefined
      assert String.contains?(result_neither, "Level: , Status:")
    end

    test "deeply nested conditionals with cumulative assignments" do
      template = """
      {% assign score = 0 %}
      {% if level1 %}
        {% assign score = score + 10 %}
        {% if level2 %}
          {% assign score = score + 20 %}
          {% if level3 %}
            {% assign score = score + 30 %}
          {% endif %}
        {% endif %}
      {% endif %}
      Final score: {{ score }}
      """

      # All levels
      context_all = %{"level1" => true, "level2" => true, "level3" => true}
      assert {:ok, result_all} = Mau.render(template, context_all)
      assert String.contains?(result_all, "Final score: 60")

      # Two levels
      context_two = %{"level1" => true, "level2" => true, "level3" => false}
      assert {:ok, result_two} = Mau.render(template, context_two)
      assert String.contains?(result_two, "Final score: 30")

      # One level
      context_one = %{"level1" => true, "level2" => false, "level3" => false}
      assert {:ok, result_one} = Mau.render(template, context_one)
      assert String.contains?(result_one, "Final score: 10")

      # No levels
      context_none = %{"level1" => false, "level2" => false, "level3" => false}
      assert {:ok, result_none} = Mau.render(template, context_none)
      assert String.contains?(result_none, "Final score: 0")
    end
  end

  describe "Context Mutation with Loops" do
    test "assignments within conditional inside loop" do
      template = """
      {% assign total = 0 %}
      {% for item in items %}
        {% if item > threshold %}
          {% assign total = total + item %}
          {% assign last_added = item %}
        {% endif %}
      {% endfor %}
      Total: {{ total }}, Last added: {{ last_added }}
      """

      context = %{"items" => [5, 15, 8, 25, 3], "threshold" => 10}

      assert {:ok, result} = Mau.render(template, context)
      # Items > 10: 15, 25. Total = 15 + 25 = 40, Last = 25
      assert String.contains?(result, "Total: 40, Last added: 25")
    end

    test "conditional mutations affecting loop behavior" do
      template = """
      {% assign found = false %}
      {% assign index = 0 %}
      {% for item in items %}
        {% if not found and item == target %}
          {% assign found = true %}
          {% assign found_at = index %}
        {% endif %}
        {% assign index = index + 1 %}
      {% endfor %}
      {% if found %}
        Found "{{ target }}" at index {{ found_at }}
      {% else %}
        "{{ target }}" not found
      {% endif %}
      """

      # Target found
      context_found = %{"items" => ["apple", "banana", "cherry"], "target" => "banana"}
      assert {:ok, result_found} = Mau.render(template, context_found)
      assert String.contains?(result_found, "Found \"banana\" at index 1")

      # Target not found
      context_not_found = %{"items" => ["apple", "banana", "cherry"], "target" => "orange"}
      assert {:ok, result_not_found} = Mau.render(template, context_not_found)
      assert String.contains?(result_not_found, "\"orange\" not found")
    end

    test "nested loops with conditional assignments" do
      template = """
      {% assign matches = 0 %}
      {% for row in matrix %}
        {% for cell in row %}
          {% if cell == target %}
            {% assign matches = matches + 1 %}
            {% assign last_row = forloop.index %}
          {% endif %}
        {% endfor %}
      {% endfor %}
      Found {{ matches }} matches, last in row {{ last_row }}
      """

      context = %{
        "matrix" => [
          ["a", "b", "x"],
          ["x", "c", "d"],
          ["e", "f", "x"]
        ],
        "target" => "x"
      }

      assert {:ok, result} = Mau.render(template, context)
      # Found 3 matches for "x", last one in row 2 (0-based index)
      assert String.contains?(result, "Found 3 matches, last in row 2")
    end
  end

  describe "Context Mutation Scope and Persistence" do
    test "assignments persist after conditional block ends" do
      template = """
      Initial: {{ message }}
      {% if condition %}
        {% assign message = "set in conditional" %}
        {% assign new_var = "created in conditional" %}
      {% endif %}
      After conditional: {{ message }}
      New variable: {{ new_var }}
      """

      context = %{"condition" => true, "message" => "initial value"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Initial: initial value")
      assert String.contains?(result, "After conditional: set in conditional")
      assert String.contains?(result, "New variable: created in conditional")
    end

    test "assignments within false branches don't affect context" do
      template = """
      {% assign counter = 0 %}
      {% if false %}
        {% assign counter = 999 %}
        {% assign false_var = "should not exist" %}
      {% endif %}
      Counter: {{ counter }}
      False var: {{ false_var }}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Counter: 0")
      # Should be empty/undefined
      assert String.contains?(result, "False var:")
      refute String.contains?(result, "999")
      refute String.contains?(result, "should not exist")
    end

    test "variable shadowing and restoration" do
      template = """
      {% assign x = "global" %}
      Global: {{ x }}
      {% if condition %}
        {% assign x = "local" %}
        Local: {{ x }}
        {% if nested_condition %}
          {% assign x = "nested" %}
          Nested: {{ x }}
        {% endif %}
        After nested: {{ x }}
      {% endif %}
      Final: {{ x }}
      """

      context = %{"condition" => true, "nested_condition" => true}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Global: global")
      assert String.contains?(result, "Local: local")
      assert String.contains?(result, "Nested: nested")
      assert String.contains?(result, "After nested: nested")
      assert String.contains?(result, "Final: nested")
    end
  end

  describe "Complex Context Mutations" do
    test "building complex data structures conditionally" do
      template = """
      {% assign user_info = "" %}
      {% assign permissions = "" %}
      {% if user.active %}
        {% assign user_info = user.name %}
        {% if user.role == "admin" %}
          {% assign permissions = "full" %}
          {% assign user_info = user_info + " (Administrator)" %}
        {% elsif user.role == "moderator" %}
          {% assign permissions = "moderate" %}
          {% assign user_info = user_info + " (Moderator)" %}
        {% else %}
          {% assign permissions = "basic" %}
        {% endif %}
      {% else %}
        {% assign user_info = "Inactive User" %}
        {% assign permissions = "none" %}
      {% endif %}
      User: {{ user_info }}
      Permissions: {{ permissions }}
      """

      # Active admin
      admin_context = %{
        "user" => %{"name" => "Alice", "active" => true, "role" => "admin"}
      }

      assert {:ok, admin_result} = Mau.render(template, admin_context)
      assert String.contains?(admin_result, "User: Alice (Administrator)")
      assert String.contains?(admin_result, "Permissions: full")

      # Active regular user
      user_context = %{
        "user" => %{"name" => "Bob", "active" => true, "role" => "user"}
      }

      assert {:ok, user_result} = Mau.render(template, user_context)
      assert String.contains?(user_result, "User: Bob")
      refute String.contains?(user_result, "(Administrator)")
      assert String.contains?(user_result, "Permissions: basic")

      # Inactive user
      inactive_context = %{
        "user" => %{"name" => "Charlie", "active" => false, "role" => "admin"}
      }

      assert {:ok, inactive_result} = Mau.render(template, inactive_context)
      assert String.contains?(inactive_result, "User: Inactive User")
      assert String.contains?(inactive_result, "Permissions: none")
    end

    test "accumulating state across multiple conditionals" do
      template = """
      {% assign log = "" %}
      {% assign error_count = 0 %}
      {% assign warning_count = 0 %}

      {% for event in events %}
        {% if event.level == "error" %}
          {% assign error_count = error_count + 1 %}
          {% assign log = log + "ERROR: " + event.message + "; " %}
        {% elsif event.level == "warning" %}
          {% assign warning_count = warning_count + 1 %}
          {% assign log = log + "WARN: " + event.message + "; " %}
        {% endif %}
      {% endfor %}

      Summary: {{ error_count }} errors, {{ warning_count }} warnings
      Log: {{ log }}
      """

      context = %{
        "events" => [
          %{"level" => "info", "message" => "System started"},
          %{"level" => "warning", "message" => "Low disk space"},
          %{"level" => "error", "message" => "Database connection failed"},
          %{"level" => "warning", "message" => "Deprecated API used"},
          %{"level" => "error", "message" => "Authentication failed"}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Summary: 2 errors, 2 warnings")
      assert String.contains?(result, "ERROR: Database connection failed")
      assert String.contains?(result, "WARN: Low disk space")
      assert String.contains?(result, "ERROR: Authentication failed")
      # info level filtered out
      refute String.contains?(result, "System started")
    end
  end

  describe "Performance with Context Mutations" do
    test "many conditional assignments performance" do
      template = """
      {% assign result = 0 %}
      {% for i in range %}
        {% if i > 50 %}
          {% assign result = result + i %}
        {% endif %}
      {% endfor %}
      Result: {{ result }}
      """

      # Generate range 0-99
      range = Enum.to_list(0..99)
      context = %{"range" => range}

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, result} = Mau.render(template, context)
      end_time = System.monotonic_time(:millisecond)

      # Sum of 51-99: should be (51+99)*49/2 = 3675
      assert String.contains?(result, "Result: 3675")

      # Should complete within reasonable time
      assert end_time - start_time < 200
    end

    test "deep nesting with mutations performance" do
      template = """
      {% assign depth = 0 %}
      {% if l1 %}
        {% assign depth = 1 %}
        {% if l2 %}
          {% assign depth = 2 %}
          {% if l3 %}
            {% assign depth = 3 %}
            {% if l4 %}
              {% assign depth = 4 %}
              {% if l5 %}
                {% assign depth = 5 %}
              {% endif %}
            {% endif %}
          {% endif %}
        {% endif %}
      {% endif %}
      Max depth reached: {{ depth }}
      """

      context = %{"l1" => true, "l2" => true, "l3" => true, "l4" => true, "l5" => true}

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, result} = Mau.render(template, context)
      end_time = System.monotonic_time(:millisecond)

      assert String.contains?(result, "Max depth reached: 5")

      # Should complete very quickly
      assert end_time - start_time < 50
    end
  end

  describe "Edge Cases and Error Handling" do
    test "assigning to undefined variables" do
      template = """
      {% if condition %}
        {% assign undefined_var = "now defined" %}
      {% endif %}
      Value: {{ undefined_var }}
      """

      context = %{"condition" => true}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Value: now defined")
    end

    test "complex expressions in assignments" do
      template = """
      {% if calculate %}
        {% assign result = (a + b) * c - d / e %}
        {% assign formatted = "Result: " + result %}
      {% endif %}
      {{ formatted }}
      """

      context = %{
        "calculate" => true,
        "a" => 10,
        "b" => 5,
        "c" => 2,
        "d" => 20,
        "e" => 4
      }

      assert {:ok, result} = Mau.render(template, context)
      # (10 + 5) * 2 - 20 / 4 = 15 * 2 - 5 = 30 - 5 = 25
      assert String.contains?(result, "Result: 25")
    end

    test "assignment with filter expressions" do
      template = """
      {% if process %}
        {% assign processed = name | upper_case %}
        {% assign count = items | length %}
        {% assign first_item = items | first | upper_case %}
      {% endif %}
      Processed: {{ processed }}
      Count: {{ count }}
      First: {{ first_item }}
      """

      context = %{
        "process" => true,
        "name" => "hello world",
        "items" => ["apple", "banana", "cherry"]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Processed: HELLO WORLD")
      assert String.contains?(result, "Count: 3")
      assert String.contains?(result, "First: APPLE")
    end
  end
end
