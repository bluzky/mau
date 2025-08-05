defmodule Mau.DataTypePreservationTest do
  @moduledoc """
  Tests for data type preservation feature.

  When preserve_types: true is used, single-value templates should preserve
  their original data types instead of converting to strings.
  """

  use ExUnit.Case
  doctest Mau

  describe "Data Type Preservation - Basic Types" do
    test "preserves integer values" do
      assert {:ok, 42} = Mau.render("{{ 42 }}", %{}, preserve_types: true)
      assert {:ok, -17} = Mau.render("{{ -17 }}", %{}, preserve_types: true)
      assert {:ok, 0} = Mau.render("{{ 0 }}", %{}, preserve_types: true)
    end

    test "preserves float values" do
      assert {:ok, 3.14} = Mau.render("{{ 3.14 }}", %{}, preserve_types: true)
      assert {:ok, -2.5} = Mau.render("{{ -2.5 }}", %{}, preserve_types: true)
      assert {:ok, 0.0} = Mau.render("{{ 0.0 }}", %{}, preserve_types: true)
    end

    test "preserves boolean values" do
      assert {:ok, true} = Mau.render("{{ true }}", %{}, preserve_types: true)
      assert {:ok, false} = Mau.render("{{ false }}", %{}, preserve_types: true)
    end

    test "preserves nil values" do
      assert {:ok, nil} = Mau.render("{{ nil }}", %{}, preserve_types: true)
    end

    test "preserves string values" do
      assert {:ok, "hello"} = Mau.render("{{ \"hello\" }}", %{}, preserve_types: true)
      assert {:ok, "world"} = Mau.render("{{ 'world' }}", %{}, preserve_types: true)
      assert {:ok, ""} = Mau.render("{{ \"\" }}", %{}, preserve_types: true)
    end
  end

  describe "Data Type Preservation - Collections" do
    test "preserves list values" do
      context = %{"items" => [1, 2, 3]}
      assert {:ok, [1, 2, 3]} = Mau.render("{{ items }}", context, preserve_types: true)

      context = %{"empty" => []}
      assert {:ok, []} = Mau.render("{{ empty }}", context, preserve_types: true)

      context = %{"mixed" => ["a", 1, true, nil]}
      assert {:ok, ["a", 1, true, nil]} = Mau.render("{{ mixed }}", context, preserve_types: true)
    end

    test "preserves map values" do
      context = %{"data" => %{"key" => "value", "num" => 42}}

      assert {:ok, %{"key" => "value", "num" => 42}} =
               Mau.render("{{ data }}", context, preserve_types: true)

      context = %{"empty_map" => %{}}
      assert {:ok, %{}} = Mau.render("{{ empty_map }}", context, preserve_types: true)
    end
  end

  describe "Data Type Preservation - Variables" do
    test "preserves variable types" do
      context = %{
        "age" => 25,
        "active" => true,
        "score" => 98.5,
        "name" => "Alice",
        "items" => [1, 2, 3],
        "config" => %{"enabled" => true}
      }

      assert {:ok, 25} = Mau.render("{{ age }}", context, preserve_types: true)
      assert {:ok, true} = Mau.render("{{ active }}", context, preserve_types: true)
      assert {:ok, 98.5} = Mau.render("{{ score }}", context, preserve_types: true)
      assert {:ok, "Alice"} = Mau.render("{{ name }}", context, preserve_types: true)
      assert {:ok, [1, 2, 3]} = Mau.render("{{ items }}", context, preserve_types: true)

      assert {:ok, %{"enabled" => true}} =
               Mau.render("{{ config }}", context, preserve_types: true)
    end

    test "preserves nested property access types" do
      context = %{
        "user" => %{
          "profile" => %{
            "age" => 30,
            "verified" => true,
            "score" => 87.2
          }
        }
      }

      assert {:ok, 30} = Mau.render("{{ user.profile.age }}", context, preserve_types: true)

      assert {:ok, true} =
               Mau.render("{{ user.profile.verified }}", context, preserve_types: true)

      assert {:ok, 87.2} = Mau.render("{{ user.profile.score }}", context, preserve_types: true)
    end

    test "preserves array indexing types" do
      context = %{
        "numbers" => [10, 20, 30],
        "flags" => [true, false, true],
        "data" => [%{"id" => 1}, %{"id" => 2}]
      }

      assert {:ok, 10} = Mau.render("{{ numbers[0] }}", context, preserve_types: true)
      # assert {:ok, 30} = Mau.render("{{ numbers[-1] }}", context, preserve_types: true)
      assert {:ok, true} = Mau.render("{{ flags[0] }}", context, preserve_types: true)
      assert {:ok, %{"id" => 1}} = Mau.render("{{ data[0] }}", context, preserve_types: true)
    end
  end

  describe "Data Type Preservation - Expressions" do
    test "preserves arithmetic expression results" do
      assert {:ok, 8} = Mau.render("{{ 5 + 3 }}", %{}, preserve_types: true)
      assert {:ok, 2} = Mau.render("{{ 5 - 3 }}", %{}, preserve_types: true)
      assert {:ok, 15} = Mau.render("{{ 5 * 3 }}", %{}, preserve_types: true)
      assert {:ok, 2.5} = Mau.render("{{ 5 / 2 }}", %{}, preserve_types: true)
      assert {:ok, 1} = Mau.render("{{ 5 % 2 }}", %{}, preserve_types: true)
    end

    test "preserves comparison expression results" do
      assert {:ok, true} = Mau.render("{{ 5 > 3 }}", %{}, preserve_types: true)
      assert {:ok, false} = Mau.render("{{ 5 < 3 }}", %{}, preserve_types: true)
      assert {:ok, true} = Mau.render("{{ 5 >= 5 }}", %{}, preserve_types: true)
      assert {:ok, true} = Mau.render("{{ 3 <= 5 }}", %{}, preserve_types: true)
      assert {:ok, true} = Mau.render("{{ 5 == 5 }}", %{}, preserve_types: true)
      assert {:ok, true} = Mau.render("{{ 5 != 3 }}", %{}, preserve_types: true)
    end

    test "preserves logical expression results" do
      assert {:ok, true} = Mau.render("{{ true and true }}", %{}, preserve_types: true)
      assert {:ok, false} = Mau.render("{{ true and false }}", %{}, preserve_types: true)
      assert {:ok, true} = Mau.render("{{ true or false }}", %{}, preserve_types: true)
      assert {:ok, false} = Mau.render("{{ false or false }}", %{}, preserve_types: true)
      assert {:ok, false} = Mau.render("{{ not true }}", %{}, preserve_types: true)
      assert {:ok, true} = Mau.render("{{ not false }}", %{}, preserve_types: true)
    end

    test "preserves string concatenation results" do
      assert {:ok, "hello world"} =
               Mau.render("{{ \"hello\" + \" world\" }}", %{}, preserve_types: true)

      context = %{"first" => "John", "last" => "Doe"}

      assert {:ok, "John Doe"} =
               Mau.render("{{ first + \" \" + last }}", context, preserve_types: true)
    end
  end

  describe "Data Type Preservation - Filters" do
    test "preserves filter result types" do
      context = %{"items" => [1, 2, 3, 4, 5]}

      # Numeric results
      assert {:ok, 5} = Mau.render("{{ items | length }}", context, preserve_types: true)
      assert {:ok, 1} = Mau.render("{{ items | first }}", context, preserve_types: true)
      assert {:ok, 5} = Mau.render("{{ items | last }}", context, preserve_types: true)
      assert {:ok, 15} = Mau.render("{{ items | sum }}", context, preserve_types: true)

      # List results
      assert {:ok, [5, 4, 3, 2, 1]} =
               Mau.render("{{ items | reverse }}", context, preserve_types: true)

      assert {:ok, [1, 2]} =
               Mau.render("{{ items | slice(0, 2) }}", context, preserve_types: true)

      # String results
      assert {:ok, "1,2,3,4,5"} =
               Mau.render("{{ items | join(\",\") }}", context, preserve_types: true)
    end

    test "preserves chained filter result types" do
      context = %{"numbers" => [3, 1, 4, 1, 5, 9]}

      # Chain that results in a number
      assert {:ok, 5} = Mau.render("{{ numbers | uniq | length }}", context, preserve_types: true)

      # Chain that results in a list
      assert {:ok, [9, 5, 4, 3, 1]} =
               Mau.render("{{ numbers | uniq | sort | reverse }}", context, preserve_types: true)

      # Chain that results in a string
      assert {:ok, "9-5-4-3-1"} =
               Mau.render("{{ numbers | uniq | sort | reverse | join(\"-\") }}", context,
                 preserve_types: true
               )
    end

    test "preserves boolean filter results" do
      context = %{
        "items" => [1, 2, 3],
        "empty" => [],
        "text" => "hello",
        "map" => %{"key" => "value"}
      }

      assert {:ok, true} = Mau.render("{{ items | contains(2) }}", context, preserve_types: true)
      assert {:ok, false} = Mau.render("{{ items | contains(5) }}", context, preserve_types: true)

      assert {:ok, true} =
               Mau.render("{{ text | contains(\"ell\") }}", context, preserve_types: true)

      assert {:ok, true} =
               Mau.render("{{ map | contains(\"key\") }}", context, preserve_types: true)
    end

    test "preserves math filter results" do
      context = %{"value" => -42, "num" => 3.7}

      assert {:ok, 42} = Mau.render("{{ value | abs }}", context, preserve_types: true)
      assert {:ok, 4} = Mau.render("{{ num | ceil }}", context, preserve_types: true)
      assert {:ok, 3} = Mau.render("{{ num | floor }}", context, preserve_types: true)
      assert {:ok, 4} = Mau.render("{{ num | round }}", context, preserve_types: true)
      assert {:ok, 6.25} = Mau.render("{{ 2.5 | power(2) }}", %{}, preserve_types: true)
    end
  end

  describe "Data Type Preservation - Mixed Content" do
    test "returns string for mixed text and expressions" do
      context = %{"count" => 42, "active" => true}

      # Mixed content should always return strings
      assert {:ok, "Count: 42"} = Mau.render("Count: {{ count }}", context, preserve_types: true)

      assert {:ok, "Status: true"} =
               Mau.render("Status: {{ active }}", context, preserve_types: true)

      assert {:ok, "Value is 42 items"} =
               Mau.render("Value is {{ count }} items", context, preserve_types: true)

      # Multiple expressions with text
      assert {:ok, "42 + 8 = 50"} =
               Mau.render("{{ count }} + 8 = {{ count + 8 }}", context, preserve_types: true)
    end

    test "returns string for plain text" do
      assert {:ok, "Hello World"} = Mau.render("Hello World", %{}, preserve_types: true)
      assert {:ok, ""} = Mau.render("", %{}, preserve_types: true)
      assert {:ok, "Just text"} = Mau.render("Just text", %{}, preserve_types: true)
    end

    test "returns string for multiple expressions without text" do
      # Multiple expressions should be treated as mixed content
      template = "{{ 42 }}{{ true }}"
      assert {:ok, "42true"} = Mau.render(template, %{}, preserve_types: true)
    end
  end

  describe "Data Type Preservation - Backwards Compatibility" do
    test "default behavior unchanged when preserve_types not specified" do
      context = %{"count" => 42, "active" => true, "items" => [1, 2, 3]}

      # All should return strings by default
      assert {:ok, "42"} = Mau.render("{{ count }}", context)
      assert {:ok, "true"} = Mau.render("{{ active }}", context)
      assert {:ok, "[1, 2, 3]"} = Mau.render("{{ items }}", context)
      assert {:ok, "8"} = Mau.render("{{ 5 + 3 }}", %{})
      assert {:ok, "true"} = Mau.render("{{ 5 > 3 }}", %{})
    end

    test "preserve_types: false behaves same as default" do
      context = %{"count" => 42, "active" => true}

      assert {:ok, "42"} = Mau.render("{{ count }}", context, preserve_types: false)
      assert {:ok, "true"} = Mau.render("{{ active }}", context, preserve_types: false)
      assert {:ok, "8"} = Mau.render("{{ 5 + 3 }}", %{}, preserve_types: false)
    end
  end

  describe "Data Type Preservation - Edge Cases" do
    test "handles undefined variables with preserve_types" do
      # Undefined variables should return nil (not empty string) when preserving types
      assert {:ok, nil} = Mau.render("{{ undefined_var }}", %{}, preserve_types: true)
    end

    test "handles complex nested data structures" do
      context = %{
        "data" => %{
          "users" => [
            %{"id" => 1, "active" => true, "score" => 95.5},
            %{"id" => 2, "active" => false, "score" => 78.2}
          ],
          "meta" => %{"count" => 2, "enabled" => true}
        }
      }

      assert {:ok, 1} = Mau.render("{{ data.users[0].id }}", context, preserve_types: true)
      assert {:ok, true} = Mau.render("{{ data.users[0].active }}", context, preserve_types: true)
      assert {:ok, 95.5} = Mau.render("{{ data.users[0].score }}", context, preserve_types: true)
      assert {:ok, 2} = Mau.render("{{ data.meta.count }}", context, preserve_types: true)
    end

    test "handles workflow variables with preserve_types" do
      context = %{
        "$input" => %{"user_id" => 123, "enabled" => true},
        "$variables" => %{"timeout" => 30, "debug" => false},
        "$nodes" => %{"api_call" => %{"response" => %{"status" => 200, "success" => true}}}
      }

      assert {:ok, 123} = Mau.render("{{ $input.user_id }}", context, preserve_types: true)
      assert {:ok, true} = Mau.render("{{ $input.enabled }}", context, preserve_types: true)
      assert {:ok, 30} = Mau.render("{{ $variables.timeout }}", context, preserve_types: true)

      assert {:ok, 200} =
               Mau.render("{{ $nodes.api_call.response.status }}", context, preserve_types: true)
    end
  end
end
