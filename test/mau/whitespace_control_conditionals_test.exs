defmodule Mau.WhitespaceControlConditionalsTest do
  @moduledoc """
  Tests for whitespace control in conditional expressions and blocks.

  These tests ensure that whitespace trimming operators (-) work correctly
  within conditional blocks and expressions, maintaining proper spacing
  and formatting in rendered output.
  """

  use ExUnit.Case
  doctest Mau

  describe "Basic Whitespace Control in Conditionals" do
    test "left trim in if tag" do
      template = """
      Before
      {%- if true %}
      Content
      {% endif %}
      After
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # Left trim should remove whitespace before the tag
      refute String.contains?(result, "Before   \n")
      assert String.contains?(result, "Before")
      assert String.contains?(result, "Content")
      assert String.contains?(result, "After")
    end

    test "right trim in if tag" do
      template = """
      Before
      {% if true -%}
         Content
      {% endif %}
      After
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # Right trim should remove whitespace after the tag
      assert String.contains?(result, "Before")
      refute String.contains?(result, "\n         Content")
      assert String.contains?(result, "Content")
      assert String.contains?(result, "After")
    end

    test "both trim in if tag" do
      template = """
      Before
      {%- if true -%}
         Content
      {% endif %}
      After
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # Both trims should remove whitespace on both sides
      assert String.contains?(result, "Before")
      assert String.contains?(result, "Content")
      assert String.contains?(result, "After")
      # Should be more compact
      refute String.contains?(result, "   \n")
      refute String.contains?(result, "\n         ")
    end

    test "left trim in endif tag" do
      template = """
      Before
      {% if true %}
      Content
      {%- endif %}
      After
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Before")
      assert String.contains?(result, "Content")
      refute String.contains?(result, "Content   \n")
      assert String.contains?(result, "After")
    end

    test "right trim in endif tag" do
      template = """
      Before
      {% if true %}
      Content
      {% endif -%}
         After
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Before")
      assert String.contains?(result, "Content")
      assert String.contains?(result, "After")
      refute String.contains?(result, "\n         After")
    end

    test "both trim in endif tag" do
      template = """
      Before
      {% if true %}
      Content
      {%- endif -%}
         After
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Before")
      assert String.contains?(result, "Content")
      assert String.contains?(result, "After")
      # Whitespace should be trimmed on both sides
      refute String.contains?(result, "Content   \n")
      refute String.contains?(result, "\n         After")
    end
  end

  describe "Whitespace Control in If-Else-Endif Chains" do
    test "whitespace control across if-else-endif" do
      template = """
      Start
      {%- if condition -%}
        If content
      {%- else -%}
        Else content
      {%- endif -%}
      End
      """

      # Test if branch
      context_true = %{"condition" => true}
      assert {:ok, result_true} = Mau.render(template, context_true)
      assert String.contains?(result_true, "Start")
      assert String.contains?(result_true, "If content")
      assert String.contains?(result_true, "End")
      refute String.contains?(result_true, "Else content")

      # Test else branch
      context_false = %{"condition" => false}
      assert {:ok, result_false} = Mau.render(template, context_false)
      assert String.contains?(result_false, "Start")
      assert String.contains?(result_false, "Else content")
      assert String.contains?(result_false, "End")
      refute String.contains?(result_false, "If content")
    end

    test "mixed trim patterns in if-elsif-else chain" do
      template = """
      Begin
      {%- if condition == "a" %}
        Content A
      {% elsif condition == "b" -%}
         Content B
      {%- else -%}
        Content C
      {% endif -%}
         Final
      """

      # Test condition a
      context_a = %{"condition" => "a"}
      assert {:ok, result_a} = Mau.render(template, context_a)
      assert String.contains?(result_a, "Begin")
      assert String.contains?(result_a, "Content A")
      assert String.contains?(result_a, "Final")

      # Test condition b
      context_b = %{"condition" => "b"}
      assert {:ok, result_b} = Mau.render(template, context_b)
      assert String.contains?(result_b, "Begin")
      assert String.contains?(result_b, "Content B")
      assert String.contains?(result_b, "Final")

      # Test else condition
      context_c = %{"condition" => "c"}
      assert {:ok, result_c} = Mau.render(template, context_c)
      assert String.contains?(result_c, "Begin")
      assert String.contains?(result_c, "Content C")
      assert String.contains?(result_c, "Final")
    end

    test "selective whitespace control" do
      template = """
      Line1
      {% if true -%}
        Trimmed right
      {% endif %}
      Line2

      Line3
      {%- if true %}
        Trimmed left
      {% endif %}
      Line4
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Line1")
      assert String.contains?(result, "Trimmed right")
      assert String.contains?(result, "Line2")
      assert String.contains?(result, "Line3")
      assert String.contains?(result, "Trimmed left")
      assert String.contains?(result, "Line4")
    end
  end

  describe "Whitespace Control in Nested Conditionals" do
    test "nested conditionals with whitespace control" do
      template = """
      Outer start
      {%- if outer_condition -%}
        Outer content
        {%- if inner_condition -%}
          Inner content
        {%- endif -%}
        More outer
      {%- endif -%}
      Outer end
      """

      # Both conditions true
      context_both = %{"outer_condition" => true, "inner_condition" => true}
      assert {:ok, result_both} = Mau.render(template, context_both)
      assert String.contains?(result_both, "Outer start")
      assert String.contains?(result_both, "Outer content")
      assert String.contains?(result_both, "Inner content")
      assert String.contains?(result_both, "More outer")
      assert String.contains?(result_both, "Outer end")

      # Only outer true
      context_outer = %{"outer_condition" => true, "inner_condition" => false}
      assert {:ok, result_outer} = Mau.render(template, context_outer)
      assert String.contains?(result_outer, "Outer content")
      assert String.contains?(result_outer, "More outer")
      refute String.contains?(result_outer, "Inner content")

      # Neither true
      context_neither = %{"outer_condition" => false, "inner_condition" => false}
      assert {:ok, result_neither} = Mau.render(template, context_neither)
      assert String.contains?(result_neither, "Outer start")
      assert String.contains?(result_neither, "Outer end")
      refute String.contains?(result_neither, "Outer content")
      refute String.contains?(result_neither, "Inner content")
    end

    test "asymmetric whitespace control in nested structure" do
      template = """
      Level 0
      {% if level1 -%}
        Level 1 content
        {%- if level2 %}
          Level 2 content
        {% endif -%}
        Back to level 1
      {%- endif %}
      Back to level 0
      """

      context = %{"level1" => true, "level2" => true}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Level 0")
      assert String.contains?(result, "Level 1 content")
      assert String.contains?(result, "Level 2 content")
      assert String.contains?(result, "Back to level 1")
      assert String.contains?(result, "Back to level 0")
    end
  end

  describe "Whitespace Control with Loops and Conditionals" do
    test "conditionals inside loops with whitespace control" do
      template = """
      List:
      {%- for item in items -%}
        {%- if item.active -%}
          Active: {{ item.name }}
        {%- else -%}
          Inactive: {{ item.name }}
        {%- endif -%}
      {%- endfor -%}
      End list
      """

      context = %{
        "items" => [
          %{"name" => "Item1", "active" => true},
          %{"name" => "Item2", "active" => false},
          %{"name" => "Item3", "active" => true}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "List:")
      assert String.contains?(result, "Active: Item1")
      assert String.contains?(result, "Inactive: Item2")
      assert String.contains?(result, "Active: Item3")
      assert String.contains?(result, "End list")
    end

    test "loops inside conditionals with whitespace control" do
      template = """
      {%- if show_list -%}
        Items:
        {%- for item in items -%}
          - {{ item }}
        {%- endfor -%}
        Done
      {%- else -%}
        No items to show
      {%- endif -%}
      """

      # Show list
      context_show = %{"show_list" => true, "items" => ["apple", "banana"]}
      assert {:ok, result_show} = Mau.render(template, context_show)
      assert String.contains?(result_show, "Items:")
      assert String.contains?(result_show, "- apple")
      assert String.contains?(result_show, "- banana")
      assert String.contains?(result_show, "Done")
      refute String.contains?(result_show, "No items")

      # Don't show list
      context_hide = %{"show_list" => false, "items" => ["apple", "banana"]}
      assert {:ok, result_hide} = Mau.render(template, context_hide)
      assert String.contains?(result_hide, "No items to show")
      refute String.contains?(result_hide, "Items:")
      refute String.contains?(result_hide, "apple")
    end
  end

  describe "Whitespace Control with Expressions" do
    test "expression blocks with whitespace control in conditionals" do
      template = """
      Value:
      {%- if show_value -%}
        {{- value -}}
      {%- else -%}
        N/A
      {%- endif -%}
       (processed)
      """

      context = %{"show_value" => true, "value" => "RESULT"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Value:")
      assert String.contains?(result, "RESULT")
      assert String.contains?(result, "(processed)")
      # Should be compact due to whitespace control

      # Test else branch
      context_false = %{"show_value" => false, "value" => "RESULT"}
      assert {:ok, result_false} = Mau.render(template, context_false)
      assert String.contains?(result_false, "Value:")
      assert String.contains?(result_false, "N/A")
      assert String.contains?(result_false, "(processed)")
      refute String.contains?(result_false, "RESULT")
    end

    test "mixed expression and tag whitespace control" do
      template = """
      Start
      {%- if condition -%}
        Before: {{- prefix -}}
        {%- if nested -%}
          {{- " NESTED " -}}
        {%- endif -%}
        {{- suffix -}} After
      {%- endif -%}
      End
      """

      context = %{
        "condition" => true,
        "nested" => true,
        "prefix" => "PRE",
        "suffix" => "POST"
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Start")
      assert String.contains?(result, "Before:")
      assert String.contains?(result, "PRE")
      assert String.contains?(result, "NESTED")
      assert String.contains?(result, "POST")
      assert String.contains?(result, "After")
      assert String.contains?(result, "End")
    end
  end

  describe "Complex Whitespace Control Scenarios" do
    test "table-like formatting with whitespace control" do
      template = """
      <table>
      {%- for row in rows -%}
        <tr>
        {%- for cell in row -%}
          {%- if cell.highlight -%}
            <td class="highlight">{{- cell.value -}}</td>
          {%- else -%}
            <td>{{- cell.value -}}</td>
          {%- endif -%}
        {%- endfor -%}
        </tr>
      {%- endfor -%}
      </table>
      """

      context = %{
        "rows" => [
          [
            %{"value" => "A1", "highlight" => false},
            %{"value" => "B1", "highlight" => true}
          ],
          [
            %{"value" => "A2", "highlight" => true},
            %{"value" => "B2", "highlight" => false}
          ]
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "<table>")
      assert String.contains?(result, "<tr>")
      assert String.contains?(result, "<td>A1</td>")
      assert String.contains?(result, "<td class=\"highlight\">B1</td>")
      assert String.contains?(result, "<td class=\"highlight\">A2</td>")
      assert String.contains?(result, "<td>B2</td>")
      assert String.contains?(result, "</table>")
    end

    test "conditional CSS class generation with tight control" do
      template = """
      <div class="base
      {%- if user.admin %} admin{% endif -%}
      {%- if user.active %} active{% endif -%}
      {%- if user.premium %} premium{% endif -%}
      ">Content</div>
      """

      # Admin, active, premium user
      context_full = %{
        "user" => %{"admin" => true, "active" => true, "premium" => true}
      }

      assert {:ok, result_full} = Mau.render(template, context_full)
      assert String.contains?(result_full, "class=\"base admin active premium\"")

      # Only active user
      context_active = %{
        "user" => %{"admin" => false, "active" => true, "premium" => false}
      }

      assert {:ok, result_active} = Mau.render(template, context_active)
      assert String.contains?(result_active, "class=\"base active\"")

      # No additional classes
      context_basic = %{
        "user" => %{"admin" => false, "active" => false, "premium" => false}
      }

      assert {:ok, result_basic} = Mau.render(template, context_basic)
      assert String.contains?(result_basic, "class=\"base\"")
    end

    test "JSON-like output formatting" do
      template = """
      {
        "status": "active",
      {%- if user.name -%}
        "name": "{{ user.name }}",
      {%- endif -%}
      {%- if user.email -%}
        "email": "{{ user.email }}",
      {%- endif -%}
        "role": "{{ user.role }}"
      }
      """

      context = %{
        "user" => %{
          "name" => "Alice",
          "email" => "alice@example.com",
          "role" => "admin"
        }
      }

      assert {:ok, result} = Mau.render(template, context)
      IO.inspect(result, label: "Rendered JSON")
      assert String.contains?(result, "\"status\": \"active\"")
      assert String.contains?(result, "\"name\": \"Alice\"")
      assert String.contains?(result, "\"email\": \"alice@example.com\"")
      assert String.contains?(result, "\"role\": \"admin\"")

      # Test with missing fields
      context_minimal = %{
        "user" => %{"role" => "user"}
      }

      assert {:ok, result_minimal} = Mau.render(template, context_minimal)
      assert String.contains?(result_minimal, "\"status\": \"active\"")
      assert String.contains?(result_minimal, "\"role\": \"user\"")
      refute String.contains?(result_minimal, "\"name\":")
      refute String.contains?(result_minimal, "\"email\":")
    end
  end

  describe "Edge Cases and Error Conditions" do
    test "whitespace control with only whitespace content" do
      template = """
      Before
      {%- if true -%}

      {%- endif -%}
      After
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Before")
      assert String.contains?(result, "After")
      # Should handle whitespace-only content gracefully
    end

    test "excessive whitespace with control" do
      template = """
      Start
      {%- if true -%}
                  Content
      {%- endif -%}
            End
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Start")
      assert String.contains?(result, "Content")
      assert String.contains?(result, "End")
    end

    test "whitespace control with false conditions" do
      template = """
      Before
      {%- if false -%}
        This should not appear
      {%- endif -%}
         After
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Before")
      assert String.contains?(result, "After")
      refute String.contains?(result, "This should not appear")
      # Whitespace should still be trimmed even though condition is false
    end

    test "mixed newline types with whitespace control" do
      # Test with different line endings
      template = "Before\r\n{%- if true -%}\r\nContent\n{%- endif -%}\r\nAfter"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Before")
      assert String.contains?(result, "Content")
      assert String.contains?(result, "After")
    end
  end

  describe "Performance with Whitespace Control" do
    test "many conditional blocks with whitespace control" do
      template = """
      {%- for i in range -%}
        {%- if i > 50 -%}
          Item {{ i }}
        {%- endif -%}
      {%- endfor -%}
      """

      range = Enum.to_list(0..99)
      context = %{"range" => range}

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, result} = Mau.render(template, context)
      end_time = System.monotonic_time(:millisecond)

      # Should contain items 51-99
      assert String.contains?(result, "Item 51")
      assert String.contains?(result, "Item 99")
      refute String.contains?(result, "Item 50")
      refute String.contains?(result, "Item 0")

      # Should complete within reasonable time
      assert end_time - start_time < 200
    end

    test "deeply nested conditionals with whitespace control performance" do
      template = """
      {%- if l1 -%}
        L1
        {%- if l2 -%}
          L2
          {%- if l3 -%}
            L3
            {%- if l4 -%}
              L4
              {%- if l5 -%}
                L5
              {%- endif -%}
            {%- endif -%}
          {%- endif -%}
        {%- endif -%}
      {%- endif -%}
      """

      context = %{"l1" => true, "l2" => true, "l3" => true, "l4" => true, "l5" => true}

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, result} = Mau.render(template, context)
      end_time = System.monotonic_time(:millisecond)

      assert String.contains?(result, "L1")
      assert String.contains?(result, "L5")

      # Should complete very quickly
      assert end_time - start_time < 50
    end
  end
end
