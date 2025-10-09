defmodule Mau.ElixirStyleOperatorsTest do
  @moduledoc """
  Tests for Elixir-style && and || operators.

  These operators behave like Elixir's native operators:
  - They return actual values (not just true/false booleans)
  - Only false and nil are falsy (0, "", [], {} are all truthy)
  - Short-circuit evaluation

  For comparison, `and` and `or` operators maintain their original behavior
  where 0, "", [], {} are considered falsy.
  """

  use ExUnit.Case
  doctest Mau

  describe "&& operator - returns actual values" do
    test "true && false returns false" do
      assert {:ok, "false"} = Mau.render("{{ true && false }}", %{})
    end

    test "true && truthy returns the right value" do
      assert {:ok, "hello"} = Mau.render("{{ true && \"hello\" }}", %{})
      assert {:ok, "42"} = Mau.render("{{ true && 42 }}", %{})
    end

    test "truthy && truthy returns the right value" do
      assert {:ok, "world"} = Mau.render("{{ \"hello\" && \"world\" }}", %{})
      assert {:ok, "10"} = Mau.render("{{ 5 && 10 }}", %{})
    end

    test "false && anything returns false" do
      assert {:ok, "false"} = Mau.render("{{ false && \"hello\" }}", %{})
      assert {:ok, "false"} = Mau.render("{{ false && 42 }}", %{})
    end

    test "nil && anything returns empty string (nil rendered)" do
      assert {:ok, ""} = Mau.render("{{ nil && \"hello\" }}", %{})
    end

    test "0 is truthy in Elixir-style (returns right value)" do
      assert {:ok, "hello"} = Mau.render("{{ 0 && \"hello\" }}", %{})
    end

    test "empty string is truthy in Elixir-style (returns right value)" do
      assert {:ok, "hello"} = Mau.render("{{ \"\" && \"hello\" }}", %{})
    end

    test "short-circuits on falsy left operand" do
      # If left is false, right should not be evaluated
      template = """
      {% if false && undefined_var %}
        Should not appear
      {% else %}
        False short-circuited
      {% endif %}
      """

      assert {:ok, result} = Mau.render(template, %{})
      assert String.contains?(result, "False short-circuited")
    end
  end

  describe "|| operator - returns actual values" do
    test "true || false returns true" do
      assert {:ok, "true"} = Mau.render("{{ true || false }}", %{})
    end

    test "false || truthy returns the right value" do
      assert {:ok, "hello"} = Mau.render("{{ false || \"hello\" }}", %{})
      assert {:ok, "42"} = Mau.render("{{ false || 42 }}", %{})
    end

    test "nil || truthy returns the right value" do
      assert {:ok, "hello"} = Mau.render("{{ nil || \"hello\" }}", %{})
    end

    test "truthy || anything returns the left value" do
      assert {:ok, "hello"} = Mau.render("{{ \"hello\" || \"world\" }}", %{})
      assert {:ok, "5"} = Mau.render("{{ 5 || 10 }}", %{})
    end

    test "0 is truthy in Elixir-style (returns left value)" do
      assert {:ok, "0"} = Mau.render("{{ 0 || \"hello\" }}", %{})
    end

    test "empty string is truthy in Elixir-style (returns left value)" do
      assert {:ok, ""} = Mau.render("{{ \"\" || \"hello\" }}", %{})
    end

    test "short-circuits on truthy left operand" do
      # If left is truthy, right should not be evaluated
      template = """
      {% if true || undefined_var %}
        True short-circuited
      {% else %}
        Should not appear
      {% endif %}
      """

      assert {:ok, result} = Mau.render(template, %{})
      assert String.contains?(result, "True short-circuited")
    end
  end

  describe "&& and || with preserve_types option" do
    test "&& returns raw values with preserve_types" do
      assert {:ok, false} = Mau.render("{{ true && false }}", %{}, preserve_types: true)
      assert {:ok, 42} = Mau.render("{{ true && 42 }}", %{}, preserve_types: true)
      assert {:ok, "world"} = Mau.render("{{ \"hello\" && \"world\" }}", %{}, preserve_types: true)
      assert {:ok, false} = Mau.render("{{ false && 42 }}", %{}, preserve_types: true)
      assert {:ok, nil} = Mau.render("{{ nil && 42 }}", %{}, preserve_types: true)
    end

    test "|| returns raw values with preserve_types" do
      assert {:ok, true} = Mau.render("{{ true || false }}", %{}, preserve_types: true)
      assert {:ok, 42} = Mau.render("{{ false || 42 }}", %{}, preserve_types: true)
      assert {:ok, "hello"} = Mau.render("{{ \"hello\" || \"world\" }}", %{}, preserve_types: true)
      assert {:ok, 0} = Mau.render("{{ 0 || 42 }}", %{}, preserve_types: true)
      assert {:ok, ""} = Mau.render("{{ \"\" || \"hello\" }}", %{}, preserve_types: true)
    end
  end

  describe "&& and || with variables" do
    test "&& with variables returns actual values" do
      context = %{
        "zero" => 0,
        "empty" => "",
        "items" => [1, 2, 3],
        "name" => "Alice",
        "active" => true
      }

      # 0 is truthy in Elixir-style
      assert {:ok, "hello"} = Mau.render("{{ zero && \"hello\" }}", context)

      # Empty string is truthy in Elixir-style
      assert {:ok, "world"} = Mau.render("{{ empty && \"world\" }}", context)

      # Non-empty list is truthy
      assert {:ok, "yes"} = Mau.render("{{ items && \"yes\" }}", context)

      # String is truthy
      assert {:ok, "Bob"} = Mau.render("{{ name && \"Bob\" }}", context)
    end

    test "|| with variables returns actual values" do
      context = %{
        "zero" => 0,
        "empty" => "",
        "items" => [],
        "name" => nil,
        "active" => false
      }

      # 0 is truthy, returns 0
      assert {:ok, "0"} = Mau.render("{{ zero || \"default\" }}", context)

      # Empty string is truthy, returns empty string
      assert {:ok, ""} = Mau.render("{{ empty || \"default\" }}", context)

      # Empty list is truthy, returns [1, 2, 3]
      assert {:ok, result} = Mau.render("{{ items || \"default\" }}", context)
      assert String.contains?(result, "[]")

      # nil is falsy, returns default
      assert {:ok, "default"} = Mau.render("{{ name || \"default\" }}", context)

      # false is falsy, returns default
      assert {:ok, "default"} = Mau.render("{{ active || \"default\" }}", context)
    end

    test "&& and || with variables and preserve_types" do
      context = %{
        "zero" => 0,
        "empty_list" => [],
        "items" => [1, 2, 3],
        "name" => nil
      }

      assert {:ok, "hello"} =
        Mau.render("{{ zero && \"hello\" }}", context, preserve_types: true)

      assert {:ok, []} =
        Mau.render("{{ empty_list || \"default\" }}", context, preserve_types: true)

      assert {:ok, [1, 2, 3]} =
        Mau.render("{{ items || \"default\" }}", context, preserve_types: true)

      assert {:ok, "default"} =
        Mau.render("{{ name || \"default\" }}", context, preserve_types: true)
    end
  end

  describe "Comparison: && vs and, || vs or" do
    test "&& uses Elixir truthiness (0, empty string are truthy)" do
      assert {:ok, "hello"} = Mau.render("{{ 0 && \"hello\" }}", %{})
      assert {:ok, "world"} = Mau.render("{{ \"\" && \"world\" }}", %{})
    end

    test "and uses original truthiness (0, empty string are falsy)" do
      assert {:ok, "false"} = Mau.render("{{ 0 and \"hello\" }}", %{})
      assert {:ok, "false"} = Mau.render("{{ \"\" and \"world\" }}", %{})
    end

    test "|| uses Elixir truthiness (0, empty string are truthy)" do
      assert {:ok, "0"} = Mau.render("{{ 0 || \"hello\" }}", %{})
      assert {:ok, ""} = Mau.render("{{ \"\" || \"world\" }}", %{})
    end

    test "or uses original truthiness (0, empty string are falsy)" do
      assert {:ok, "true"} = Mau.render("{{ 0 or \"hello\" }}", %{})
      assert {:ok, "true"} = Mau.render("{{ \"\" or \"world\" }}", %{})
    end

    test "&& returns actual values, and also returns actual values when truthy" do
      assert {:ok, "world"} = Mau.render("{{ \"hello\" && \"world\" }}", %{})
      # Note: `and` also returns right value when left is truthy
      assert {:ok, "world"} = Mau.render("{{ \"hello\" and \"world\" }}", %{})
      # But `and` returns false (not left value) when left is falsy
      assert {:ok, "false"} = Mau.render("{{ false and \"world\" }}", %{})
    end

    test "|| returns actual values, or returns booleans" do
      assert {:ok, "hello"} = Mau.render("{{ \"hello\" || \"world\" }}", %{})
      assert {:ok, "true"} = Mau.render("{{ \"hello\" or \"world\" }}", %{})
    end
  end

  describe "Complex expressions with && and ||" do
    test "chained && operators" do
      assert {:ok, "3"} = Mau.render("{{ 1 && 2 && 3 }}", %{})
      assert {:ok, "false"} = Mau.render("{{ 1 && false && 3 }}", %{})
    end

    test "chained || operators" do
      assert {:ok, "1"} = Mau.render("{{ 1 || 2 || 3 }}", %{})
      assert {:ok, "2"} = Mau.render("{{ false || 2 || 3 }}", %{})
      assert {:ok, "3"} = Mau.render("{{ false || nil || 3 }}", %{})
    end

    test "mixed && and || operators" do
      # In Elixir: false && true || 42 => false || 42 => 42
      assert {:ok, "42"} = Mau.render("{{ false && true || 42 }}", %{})

      # In Elixir: true || false && 42 => true (|| short-circuits)
      assert {:ok, "true"} = Mau.render("{{ true || false && 42 }}", %{})
    end

    test "&& and || with comparison operators" do
      assert {:ok, "yes"} = Mau.render("{{ 5 > 3 && \"yes\" }}", %{})
      assert {:ok, "false"} = Mau.render("{{ 5 < 3 && \"yes\" }}", %{})
      # 5 > 3 evaluates to true (boolean), so || returns true
      assert {:ok, "true"} = Mau.render("{{ 5 > 3 || \"no\" }}", %{})
      assert {:ok, "no"} = Mau.render("{{ 5 < 3 || \"no\" }}", %{})
    end

    test "&& and || in conditional blocks" do
      template = """
      {% if 0 && \"hello\" %}
        0 is truthy in Elixir-style
      {% else %}
        Should not appear
      {% endif %}
      """

      assert {:ok, result} = Mau.render(template, %{})
      assert String.contains?(result, "0 is truthy in Elixir-style")
    end
  end

  describe "Default value pattern (common Elixir idiom)" do
    test "use || for default values" do
      context = %{"name" => nil}
      assert {:ok, "Guest"} = Mau.render("{{ name || \"Guest\" }}", context)
    end

    test "use || with potentially undefined variables" do
      context = %{}
      assert {:ok, "Default"} = Mau.render("{{ missing_var || \"Default\" }}", context)
    end

    test "chained || for cascading defaults" do
      context = %{"first" => nil, "second" => nil, "third" => "value"}

      template = "{{ first || second || third || \"fallback\" }}"
      assert {:ok, "value"} = Mau.render(template, context)
    end
  end

  describe "Guard pattern (common Elixir idiom)" do
    test "use && for conditional execution pattern" do
      context = %{"user" => %{"admin" => true}}

      template = """
      {% assign can_delete = user && user.admin %}
      {% if can_delete %}
        Delete button
      {% endif %}
      """

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Delete button")
    end

    test "&& returns falsy when guard fails" do
      context = %{"user" => nil}

      template = """
      {% assign can_delete = user && user.admin %}
      {% if can_delete %}
        Should not appear
      {% else %}
        No permission
      {% endif %}
      """

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "No permission")
    end
  end
end
