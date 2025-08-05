defmodule Mau.TruthinessEdgeCasesTest do
  @moduledoc """
  Tests for truthiness evaluation edge cases.
  
  These tests ensure that the template engine properly evaluates
  truthiness for various data types and edge cases according to
  template language conventions.
  """
  
  use ExUnit.Case
  doctest Mau

  describe "Basic Truthiness Rules" do
    test "nil is falsy" do
      template = """
      {% if nil_value %}
        Should not appear
      {% else %}
        Nil is falsy
      {% endif %}
      """

      context = %{"nil_value" => nil}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Nil is falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "false is falsy" do
      template = """
      {% if false_value %}
        Should not appear
      {% else %}
        False is falsy
      {% endif %}
      """

      context = %{"false_value" => false}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "False is falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "true is truthy" do
      template = """
      {% if true_value %}
        True is truthy
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{"true_value" => true}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "True is truthy")
      refute String.contains?(result, "Should not appear")
    end
  end

  describe "String Truthiness" do
    test "empty string is falsy" do
      template = """
      {% if empty_string %}
        Should not appear
      {% else %}
        Empty string is falsy
      {% endif %}
      """

      context = %{"empty_string" => ""}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Empty string is falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "non-empty string is truthy" do
      template = """
      {% if non_empty_string %}
        Non-empty string is truthy
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{"non_empty_string" => "hello"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Non-empty string is truthy")
      refute String.contains?(result, "Should not appear")
    end

    test "whitespace-only string is truthy" do
      template = """
      {% if whitespace_string %}
        Whitespace string is truthy
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{"whitespace_string" => "   \n\t  "}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Whitespace string is truthy")
      refute String.contains?(result, "Should not appear")
    end

    test "single character string is truthy" do
      template = """
      {% if single_char %}
        Single char is truthy
      {% endif %}
      """

      context = %{"single_char" => "a"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Single char is truthy")
    end

    test "zero string is truthy" do
      template = """
      {% if zero_string %}
        Zero string is truthy
      {% endif %}
      """

      context = %{"zero_string" => "0"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Zero string is truthy")
    end
  end

  describe "Numeric Truthiness" do
    test "zero integer is falsy" do
      template = """
      {% if zero_int %}
        Should not appear
      {% else %}
        Zero integer is falsy
      {% endif %}
      """

      context = %{"zero_int" => 0}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Zero integer is falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "zero float is falsy" do
      template = """
      {% if zero_float %}
        Should not appear
      {% else %}
        Zero float is falsy
      {% endif %}
      """

      context = %{"zero_float" => 0.0}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Zero float is falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "negative zero float is falsy" do
      template = """
      {% if neg_zero_float %}
        Should not appear
      {% else %}
        Negative zero is falsy
      {% endif %}
      """

      context = %{"neg_zero_float" => -0.0}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Negative zero is falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "positive integer is truthy" do
      template = """
      {% if positive_int %}
        Positive integer is truthy
      {% endif %}
      """

      context = %{"positive_int" => 42}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Positive integer is truthy")
    end

    test "negative integer is truthy" do
      template = """
      {% if negative_int %}
        Negative integer is truthy
      {% endif %}
      """

      context = %{"negative_int" => -42}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Negative integer is truthy")
    end

    test "positive float is truthy" do
      template = """
      {% if positive_float %}
        Positive float is truthy
      {% endif %}
      """

      context = %{"positive_float" => 3.14}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Positive float is truthy")
    end

    test "negative float is truthy" do
      template = """
      {% if negative_float %}
        Negative float is truthy
      {% endif %}
      """

      context = %{"negative_float" => -3.14}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Negative float is truthy")
    end

    test "very small positive float is truthy" do
      template = """
      {% if tiny_float %}
        Tiny float is truthy
      {% endif %}
      """

      context = %{"tiny_float" => 0.0001}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Tiny float is truthy")
    end

    test "very small negative float is truthy" do
      template = """
      {% if tiny_neg_float %}
        Tiny negative float is truthy
      {% endif %}
      """

      context = %{"tiny_neg_float" => -0.0001}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Tiny negative float is truthy")
    end
  end

  describe "Collection Truthiness" do
    test "empty list is falsy" do
      template = """
      {% if empty_list %}
        Should not appear
      {% else %}
        Empty list is falsy
      {% endif %}
      """

      context = %{"empty_list" => []}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Empty list is falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "non-empty list is truthy" do
      template = """
      {% if non_empty_list %}
        Non-empty list is truthy
      {% endif %}
      """

      context = %{"non_empty_list" => [1, 2, 3]}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Non-empty list is truthy")
    end

    test "list with nil elements is truthy" do
      template = """
      {% if list_with_nils %}
        List with nils is truthy
      {% endif %}
      """

      context = %{"list_with_nils" => [nil, nil, nil]}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "List with nils is truthy")
    end

    test "list with false elements is truthy" do
      template = """
      {% if list_with_falsy %}
        List with falsy elements is truthy
      {% endif %}
      """

      context = %{"list_with_falsy" => [false, 0, ""]}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "List with falsy elements is truthy")
    end

    test "empty map is falsy" do
      template = """
      {% if empty_map %}
        Should not appear
      {% else %}
        Empty map is falsy
      {% endif %}
      """

      context = %{"empty_map" => %{}}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Empty map is falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "non-empty map is truthy" do
      template = """
      {% if non_empty_map %}
        Non-empty map is truthy
      {% endif %}
      """

      context = %{"non_empty_map" => %{"key" => "value"}}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Non-empty map is truthy")
    end

    test "map with nil values is truthy" do
      template = """
      {% if map_with_nils %}
        Map with nil values is truthy
      {% endif %}
      """

      context = %{"map_with_nils" => %{"key1" => nil, "key2" => nil}}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Map with nil values is truthy")
    end
  end

  describe "Mixed Data Type Conditions" do
    test "comparing different falsy values" do
      template = """
      {% if nil_val or false_val or empty_string or zero_int or empty_list %}
        Should not appear
      {% else %}
        All falsy values
      {% endif %}
      """

      context = %{
        "nil_val" => nil,
        "false_val" => false,
        "empty_string" => "",
        "zero_int" => 0,
        "empty_list" => []
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "All falsy values")
      refute String.contains?(result, "Should not appear")
    end

    test "comparing different truthy values" do
      template = """
      {% if true_val and non_empty_string and positive_int and non_empty_list %}
        All truthy values
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{
        "true_val" => true,
        "non_empty_string" => "hello",
        "positive_int" => 42,
        "non_empty_list" => [1, 2, 3]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "All truthy values")
      refute String.contains?(result, "Should not appear")
    end

    test "mixed truthy and falsy in and operation" do
      template = """
      {% if truthy_val and falsy_val %}
        Should not appear
      {% else %}
        Mixed and is falsy
      {% endif %}
      """

      context = %{
        "truthy_val" => "hello",
        "falsy_val" => 0
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Mixed and is falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "mixed truthy and falsy in or operation" do
      template = """
      {% if truthy_val or falsy_val %}
        Mixed or is truthy
      {% else %}
        Should not appear
      {% endif %}
      """

      context = %{
        "truthy_val" => "hello",
        "falsy_val" => 0
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Mixed or is truthy")
      refute String.contains?(result, "Should not appear")
    end
  end

  describe "Complex Truthiness Scenarios" do
    test "nested property access with falsy values" do
      template = """
      {% if user.profile.settings.notifications %}
        Notifications enabled
      {% else %}
        Notifications disabled or path invalid
      {% endif %}
      """

      context = %{
        "user" => %{
          "profile" => %{
            "settings" => %{
              "notifications" => false
            }
          }
        }
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Notifications disabled or path invalid")
      refute String.contains?(result, "Notifications enabled")
    end

    test "array access with falsy elements" do
      template = """
      {% if items[0] %}
        First item is truthy
      {% else %}
        First item is falsy or missing
      {% endif %}
      """

      context = %{"items" => [0, 1, 2]}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "First item is falsy or missing")
      refute String.contains?(result, "First item is truthy")
    end

    test "complex expression with mixed types" do
      template = """
      {% if (user.active and score > 0) or (items and items[0]) %}
        Complex condition met
      {% else %}
        Complex condition failed
      {% endif %}
      """

      # Test case 1: first part true
      context1 = %{
        "user" => %{"active" => true},
        "score" => 85,
        "items" => []
      }

      assert {:ok, result1} = Mau.render(template, context1)
      assert String.contains?(result1, "Complex condition met")

      # Test case 2: second part true
      context2 = %{
        "user" => %{"active" => false},
        "score" => 0,
        "items" => [42]
      }

      assert {:ok, result2} = Mau.render(template, context2)
      assert String.contains?(result2, "Complex condition met")

      # Test case 3: both parts false
      context3 = %{
        "user" => %{"active" => false},
        "score" => 0,
        "items" => [0]  # items is truthy but items[0] is falsy
      }

      assert {:ok, result3} = Mau.render(template, context3)
      assert String.contains?(result3, "Complex condition failed")
    end

    test "not operator with various falsy values" do
      template = """
      {% if not nil_val %}NIL {% endif %}
      {% if not false_val %}FALSE {% endif %}
      {% if not empty_string %}EMPTY_STR {% endif %}
      {% if not zero_int %}ZERO_INT {% endif %}
      {% if not empty_list %}EMPTY_LIST {% endif %}
      {% if not empty_map %}EMPTY_MAP {% endif %}
      """

      context = %{
        "nil_val" => nil,
        "false_val" => false,
        "empty_string" => "",
        "zero_int" => 0,
        "empty_list" => [],
        "empty_map" => %{}
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "NIL")
      assert String.contains?(result, "FALSE")
      assert String.contains?(result, "EMPTY_STR")
      assert String.contains?(result, "ZERO_INT")
      assert String.contains?(result, "EMPTY_LIST")
      assert String.contains?(result, "EMPTY_MAP")
    end

    test "not operator with various truthy values" do
      template = """
      {% if not true_val %}Should not appear{% endif %}
      {% if not non_empty_string %}Should not appear{% endif %}
      {% if not positive_int %}Should not appear{% endif %}
      {% if not non_empty_list %}Should not appear{% endif %}
      All negations were false
      """

      context = %{
        "true_val" => true,
        "non_empty_string" => "hello",
        "positive_int" => 42,
        "non_empty_list" => [1]
      }

      assert {:ok, result} = Mau.render(template, context)
      refute String.contains?(result, "Should not appear")
      assert String.contains?(result, "All negations were false")
    end
  end

  describe "Truthiness in Loops" do
    test "loop with mixed truthy and falsy items" do
      template = """
      {% for item in items %}
        {% if item %}
          Truthy: {{ item }}
        {% else %}
          Falsy: {{ item }}
        {% endif %}
      {% endfor %}
      """

      context = %{
        "items" => [1, 0, "hello", "", true, false, nil, [1], []]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Truthy: 1")
      assert String.contains?(result, "Falsy: 0")
      assert String.contains?(result, "Truthy: hello")
      assert String.contains?(result, "Falsy: ")  # empty string
      assert String.contains?(result, "Truthy: true")
      assert String.contains?(result, "Falsy: false")
      # Note: nil might render as empty string
    end

    test "conditional loop based on collection truthiness" do
      template = """
      {% if items %}
        Items exist:
        {% for item in items %}
          - {{ item }}
        {% endfor %}
      {% else %}
        No items
      {% endif %}
      """

      # Test with empty array
      context_empty = %{"items" => []}
      assert {:ok, result_empty} = Mau.render(template, context_empty)
      assert String.contains?(result_empty, "No items")
      refute String.contains?(result_empty, "Items exist:")

      # Test with non-empty array
      context_full = %{"items" => ["a", "b", "c"]}
      assert {:ok, result_full} = Mau.render(template, context_full)
      assert String.contains?(result_full, "Items exist:")
      assert String.contains?(result_full, "- a")
      refute String.contains?(result_full, "No items")
    end
  end

  describe "Edge Cases and Special Values" do
    test "undefined variable is falsy" do
      template = """
      {% if undefined_variable %}
        Should not appear
      {% else %}
        Undefined is falsy
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Undefined is falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "deeply nested falsy access" do
      template = """
      {% if deeply.nested.path.that.does.not.exist %}
        Should not appear
      {% else %}
        Deep path is falsy
      {% endif %}
      """

      context = %{"deeply" => %{}}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Deep path is falsy")
      refute String.contains?(result, "Should not appear")
    end

    test "special float value handling" do
      # Test with a very small float value close to zero
      template = """
      {% if result %}
        Result exists
      {% else %}
        No valid result
      {% endif %}
      """

      # Use a very small positive float
      context = %{"result" => 1.0e-308}  # Very small but non-zero

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Result exists")
    end

    test "very large numbers" do
      template = """
      {% if big_number %}
        Big number is truthy
      {% endif %}
      """

      context = %{"big_number" => 999_999_999_999_999_999_999}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Big number is truthy")
    end

    test "atoms as values" do
      template = """
      {% if atom_value %}
        Atom is truthy
      {% endif %}
      """

      context = %{"atom_value" => :some_atom}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Atom is truthy")
    end

    test "performance with many truthiness evaluations" do
      template = """
      {% for i in range %}
        {% if items[i] %}T{% else %}F{% endif %}
      {% endfor %}
      """

      # Create mix of truthy and falsy values
      items = Enum.map(0..999, fn i -> 
        case rem(i, 4) do
          0 -> 0        # falsy
          1 -> ""       # falsy  
          2 -> nil      # falsy
          3 -> i        # truthy
        end
      end)

      context = %{
        "range" => 0..999,
        "items" => items
      }

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, result} = Mau.render(template, context)
      end_time = System.monotonic_time(:millisecond)

      # Should contain mix of T and F
      assert String.contains?(result, "T")
      assert String.contains?(result, "F")
      
      # Should complete within reasonable time
      assert (end_time - start_time) < 500
    end
  end
end