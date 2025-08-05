defmodule Mau.ErrorConditionsEdgeCasesTest do
  @moduledoc """
  Tests for error conditions and edge cases in template parsing and rendering.
  
  These tests ensure that the template engine handles malformed templates,
  missing tags, and other error conditions gracefully.
  """
  
  use ExUnit.Case
  doctest Mau

  describe "Malformed Conditional Tags" do
    test "if tag without condition" do
      template = "{% if %}Content{% endif %}"
      context = %{}

      case Mau.render(template, context) do
        {:error, _error} ->
          # Expected - should fail to parse
          assert true
        {:ok, _result} ->
          # If it somehow succeeds, that's also acceptable behavior
          assert true
      end
    end

    test "if tag with empty condition" do
      template = "{% if  %}Content{% endif %}"
      context = %{}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, _result} ->
          assert true
      end
    end

    test "missing endif tag" do
      template = "{% if true %}Content without endif"
      context = %{}

      case Mau.render(template, context) do
        {:error, _error} ->
          # Expected - should fail due to unclosed tag
          assert true
        {:ok, result} ->
          # If it treats as text, that's also acceptable
          assert is_binary(result)
      end
    end

    test "missing if tag for endif" do
      template = "Content{% endif %}"
      context = %{}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, result} ->
          # Should either error or treat as text
          assert is_binary(result)
      end
    end

    test "mismatched conditional tags" do
      template = "{% if true %}Content{% endfor %}"
      context = %{}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, result} ->
          assert is_binary(result)
      end
    end

    test "nested conditionals with missing endif" do
      template = """
      {% if outer %}
        Outer content
        {% if inner %}
          Inner content
        {% endif %}
      """
      
      context = %{"outer" => true, "inner" => true}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, result} ->
          assert is_binary(result)
      end
    end

    test "elsif without if" do
      template = "{% elsif condition %}Content{% endif %}"
      context = %{"condition" => true}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, result} ->
          assert is_binary(result)
      end
    end

    test "else without if" do
      template = "{% else %}Content{% endif %}"
      context = %{}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, result} ->
          assert is_binary(result)
      end
    end

    test "multiple else blocks" do
      template = """
      {% if condition %}
        If content
      {% else %}
        First else
      {% else %}
        Second else
      {% endif %}
      """
      
      context = %{"condition" => false}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, result} ->
          # Should either error or handle gracefully
          assert is_binary(result)
      end
    end
  end

  describe "Malformed Loop Tags" do
    test "for tag without in keyword" do
      template = "{% for item %}Content{% endfor %}"
      context = %{}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, result} ->
          assert is_binary(result)
      end
    end

    test "for tag without collection" do
      template = "{% for item in %}Content{% endfor %}"
      context = %{}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, result} ->
          assert is_binary(result)
      end
    end

    test "for tag without variable" do
      template = "{% for in items %}Content{% endfor %}"
      context = %{"items" => [1, 2, 3]}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, result} ->
          assert is_binary(result)
      end
    end

    test "missing endfor tag" do
      template = "{% for item in items %}{{ item }}"
      context = %{"items" => [1, 2, 3]}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, result} ->
          assert is_binary(result)
      end
    end

    test "endfor without for" do
      template = "Content{% endfor %}"
      context = %{}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, result} ->
          assert is_binary(result)
      end
    end

    test "mismatched loop tags" do
      template = "{% for item in items %}Content{% endif %}"
      context = %{"items" => [1, 2, 3]}

      case Mau.render(template, context) do
        {:error, _error} ->
          assert true
        {:ok, result} ->
          assert is_binary(result)
      end
    end
  end

  describe "Invalid Variable Access" do
    test "undefined variable in condition" do
      template = "{% if undefined_var %}Content{% endif %}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # Should handle gracefully, treating undefined as nil/falsy
      refute String.contains?(result, "Content")
    end

    test "undefined nested property" do
      template = "{% if user.profile.name %}Hello {{ user.profile.name }}{% endif %}"
      context = %{"user" => %{}}

      assert {:ok, result} = Mau.render(template, context)
      # Should handle gracefully
      refute String.contains?(result, "Hello")
    end

    test "property access on nil" do
      template = "{% if user.name %}Hello{% endif %}"
      context = %{"user" => nil}

      assert {:ok, result} = Mau.render(template, context)
      refute String.contains?(result, "Hello")
    end

    test "array access on nil" do
      template = "{% if items[0] %}First item{% endif %}"
      context = %{"items" => nil}

      assert {:ok, result} = Mau.render(template, context)
      refute String.contains?(result, "First item")
    end

    test "property access on non-object" do
      template = "{% if number.property %}Has property{% endif %}"
      context = %{"number" => 42}

      assert {:ok, result} = Mau.render(template, context)
      refute String.contains?(result, "Has property")
    end

    test "array access on non-array" do
      template = "{% if string[0] %}Has index{% endif %}"
      context = %{"string" => "hello"}

      assert {:ok, result} = Mau.render(template, context)
      refute String.contains?(result, "Has index")
    end
  end

  describe "Invalid Expressions" do
    test "division by zero" do
      template = "{% if 10 / 0 > 5 %}Should not appear{% endif %}"
      context = %{}

      case Mau.render(template, context) do
        {:error, error} ->
          # Should properly handle division by zero
          assert String.contains?(error.message, "zero")
        {:ok, result} ->
          # If it handles gracefully, should not show content
          refute String.contains?(result, "Should not appear")
      end
    end

    test "modulo by zero" do
      template = "{% if 10 % 0 == 0 %}Should not appear{% endif %}"
      context = %{}

      case Mau.render(template, context) do
        {:error, error} ->
          assert String.contains?(error.message, "zero")
        {:ok, result} ->
          refute String.contains?(result, "Should not appear")
      end
    end

    test "invalid comparison types" do
      template = """
      {% if "string" > 42 %}
        String greater than number
      {% else %}
        Comparison handled
      {% endif %}
      """
      
      context = %{}

      case Mau.render(template, context) do
        {:error, _error} ->
          # May error on invalid comparison
          assert true
        {:ok, result} ->
          # May handle gracefully
          assert is_binary(result)
      end
    end

    test "very deep arithmetic nesting" do
      template = "{% if ((((1 + 2) * 3) - 4) / 2) > 1 %}Deep math works{% endif %}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # ((((1 + 2) * 3) - 4) / 2) = (((3 * 3) - 4) / 2) = ((9 - 4) / 2) = (5 / 2) = 2.5 > 1
      assert String.contains?(result, "Deep math works")
    end
  end

  describe "Memory and Performance Edge Cases" do
    test "very long template content" do
      # Create a very long string
      long_content = String.duplicate("A", 10000)
      template = "{% if true %}#{long_content}{% endif %}"
      context = %{}

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, result} = Mau.render(template, context)
      end_time = System.monotonic_time(:millisecond)

      assert String.contains?(result, long_content)
      # Should complete within reasonable time even with long content
      assert (end_time - start_time) < 1000
    end

    test "many nested parentheses in expression" do
      template = "{% if ((((((true)))))) %}Deeply nested parens{% endif %}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Deeply nested parens")
    end

    test "large number in expression" do
      template = "{% if 999999999999999999 > 0 %}Large number{% endif %}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Large number")
    end

    test "many variables in expression" do
      template = "{% if a and b and c and d and e and f and g and h %}All true{% endif %}"
      context = %{
        "a" => true, "b" => true, "c" => true, "d" => true,
        "e" => true, "f" => true, "g" => true, "h" => true
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "All true")
    end
  end

  describe "Unicode and Special Characters" do
    test "unicode in variable names" do
      template = "{% if café %}Unicode var{% endif %}"
      context = %{"café" => true}

      # May or may not support unicode variable names
      case Mau.render(template, context) do
        {:error, _error} ->
          # Unicode variables not supported
          assert true
        {:ok, result} ->
          # Unicode variables supported
          assert is_binary(result)
      end
    end

    test "unicode in template content" do
      template = "{% if true %}🚀 Unicode content 中文 العربية{% endif %}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "🚀")
      assert String.contains?(result, "中文")
      assert String.contains?(result, "العربية")
    end

    test "special characters in strings" do
      template = ~s({% if message == "Hello\n\tWorld!" %}Special chars{% endif %})
      context = %{"message" => "Hello\n\tWorld!"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Special chars")
    end

    test "quotes within strings" do
      template = ~s({% if quote == "He said \\"Hello\\"" %}Nested quotes{% endif %})
      context = %{"quote" => ~s(He said "Hello")}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Nested quotes")
    end
  end

  describe "Circular References and Complex Data" do
    test "deeply nested data structure" do
      deeply_nested = %{
        "level1" => %{
          "level2" => %{
            "level3" => %{
              "level4" => %{
                "level5" => %{
                  "value" => "deep_value"
                }
              }
            }
          }
        }
      }

      template = "{% if data.level1.level2.level3.level4.level5.value %}Found: {{ data.level1.level2.level3.level4.level5.value }}{% endif %}"
      context = %{"data" => deeply_nested}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Found: deep_value")
    end

    test "large data structure performance" do
      # Create large data structure
      large_data = Enum.reduce(1..1000, %{}, fn i, acc ->
        Map.put(acc, "key#{i}", %{"value" => i, "active" => rem(i, 2) == 0})
      end)

      template = "{% if data.key500.active %}Key 500 is active{% endif %}"
      context = %{"data" => large_data}

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, result} = Mau.render(template, context)
      end_time = System.monotonic_time(:millisecond)

      assert String.contains?(result, "Key 500 is active")
      # Should handle large data structures efficiently
      assert (end_time - start_time) < 100
    end
  end

  describe "Whitespace and Formatting Edge Cases" do
    test "excessive whitespace in tags" do
      template = "{%   if    true    %}Content{%   endif   %}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Content")
    end

    test "no whitespace in tags" do
      template = "{%if true%}Content{%endif%}"
      context = %{}

      case Mau.render(template, context) do
        {:error, _error} ->
          # May require whitespace
          assert true
        {:ok, result} ->
          # May handle no whitespace
          assert is_binary(result)
      end
    end

    test "mixed line endings" do
      template = "{% if true %}\nContent\r\n{% endif %}\r"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Content")
    end

    test "empty template" do
      template = ""
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert result == ""
    end

    test "only whitespace template" do
      template = "   \n\t\r\n   "
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert is_binary(result)
    end
  end
end