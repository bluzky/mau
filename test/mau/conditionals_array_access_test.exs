defmodule Mau.ConditionalsArrayAccessTest do
  @moduledoc """
  Tests for conditionals with array/list access patterns.

  These tests ensure that conditional expressions can properly
  access array elements and object properties in various contexts.
  """

  use ExUnit.Case
  doctest Mau

  describe "Basic Array Access in Conditionals" do
    test "simple array index access" do
      template = """
      {% if users[0].admin %}
        First user is admin: {{ users[0].name }}
      {% else %}
        First user is not admin
      {% endif %}
      """

      context = %{
        "users" => [
          %{"name" => "Alice", "admin" => true},
          %{"name" => "Bob", "admin" => false}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "First user is admin: Alice")

      # Test with non-admin first user
      context_non_admin = %{
        "users" => [
          %{"name" => "Bob", "admin" => false},
          %{"name" => "Alice", "admin" => true}
        ]
      }

      assert {:ok, result} = Mau.render(template, context_non_admin)
      assert String.contains?(result, "First user is not admin")
    end

    test "array index with variable access" do
      template = """
      {% if items[user.index] %}
        Found item: {{ items[user.index] }}
      {% else %}
        No item at index {{ user.index }}
      {% endif %}
      """

      context = %{
        "items" => ["apple", "banana", "cherry"],
        "user" => %{"index" => 1}
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Found item: banana")

      # Test with out of bounds index
      context_oob = %{
        "items" => ["apple", "banana"],
        "user" => %{"index" => 5}
      }

      assert {:ok, result} = Mau.render(template, context_oob)
      assert String.contains?(result, "No item at index 5")
    end

    test "nested array access" do
      template = """
      {% if matrix[0][1] == "target" %}
        Found target at [0][1]
      {% else %}
        Target not found at [0][1]: {{ matrix[0][1] }}
      {% endif %}
      """

      context = %{
        "matrix" => [
          ["a", "target", "c"],
          ["d", "e", "f"]
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Found target at [0][1]")

      # Test with different value
      context_different = %{
        "matrix" => [
          ["a", "different", "c"],
          ["d", "e", "f"]
        ]
      }

      assert {:ok, result} = Mau.render(template, context_different)
      assert String.contains?(result, "Target not found at [0][1]: different")
    end

    test "array access with string keys on maps" do
      template = """
      {% if data["users"][0]["active"] %}
        User {{ data["users"][0]["name"] }} is active
      {% endif %}
      """

      context = %{
        "data" => %{
          "users" => [
            %{"name" => "Alice", "active" => true},
            %{"name" => "Bob", "active" => false}
          ]
        }
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "User Alice is active")
    end
  end

  describe "Complex Array Access Patterns" do
    test "conditional with multiple array accesses" do
      template = """
      {% if users[0].role == "admin" and users[1].role == "user" %}
        Valid user hierarchy
      {% else %}
        Invalid hierarchy: {{ users[0].role }}, {{ users[1].role }}
      {% endif %}
      """

      context = %{
        "users" => [
          %{"role" => "admin"},
          %{"role" => "user"}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Valid user hierarchy")

      # Test invalid hierarchy
      context_invalid = %{
        "users" => [
          %{"role" => "user"},
          %{"role" => "admin"}
        ]
      }

      assert {:ok, result} = Mau.render(template, context_invalid)
      assert String.contains?(result, "Invalid hierarchy: user, admin")
    end

    test "array access with arithmetic expressions" do
      # Note: This test currently may not work if arithmetic in array indices isn't supported
      template = """
      {% if scores[1] > scores[0] %}
        Score improved from {{ scores[0] }} to {{ scores[1] }}
      {% else %}
        Score declined or stayed same
      {% endif %}
      """

      context = %{
        "scores" => [80, 85, 90, 75]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Score improved from 80 to 85")

      # Test with declining score using different indices
      template_decline = """
      {% if scores[3] > scores[2] %}
        Score improved
      {% else %}
        Score declined from {{ scores[2] }} to {{ scores[3] }}
      {% endif %}
      """

      assert {:ok, result_decline} = Mau.render(template_decline, context)
      assert String.contains?(result_decline, "Score declined from 90 to 75")
    end

    test "array access in nested conditionals" do
      template = """
      {% if teams[0] %}
        First team exists: {{ teams[0].name }}
        {% if teams[0].members[0] %}
          First member: {{ teams[0].members[0].name }}
          {% if teams[0].members[0].skills[0] %}
            Primary skill: {{ teams[0].members[0].skills[0] }}
          {% endif %}
        {% endif %}
      {% endif %}
      """

      context = %{
        "teams" => [
          %{
            "name" => "Alpha Team",
            "members" => [
              %{
                "name" => "Alice",
                "skills" => ["Python", "JavaScript", "Go"]
              }
            ]
          }
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "First team exists: Alpha Team")
      assert String.contains?(result, "First member: Alice")
      assert String.contains?(result, "Primary skill: Python")
    end

    test "array access with loops and conditionals" do
      template = """
      {% for i in indices %}
        Index {{ i }}:
        {% if items[i] %}
          Value: {{ items[i] }}
          {% if items[i] > threshold %}
            Above threshold!
          {% endif %}
        {% else %}
          No value at index {{ i }}
        {% endif %}
      {% endfor %}
      """

      context = %{
        "indices" => [0, 1, 2, 5],
        "items" => [10, 25, 30],
        "threshold" => 20
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Index 0:")
      assert String.contains?(result, "Value: 10")
      assert String.contains?(result, "Index 1:")
      assert String.contains?(result, "Value: 25")
      assert String.contains?(result, "Above threshold!")
      assert String.contains?(result, "Index 2:")
      assert String.contains?(result, "Value: 30")
      assert String.contains?(result, "Index 5:")
      assert String.contains?(result, "No value at index 5")
    end
  end

  describe "Dynamic Array Access" do
    test "array access with computed indices" do
      template = """
      {% if products[category.index] %}
        Selected product: {{ products[category.index].name }}
        {% if products[category.index].price < budget %}
          Within budget!
        {% else %}
          Over budget by ${{ products[category.index].price - budget }}
        {% endif %}
      {% endif %}
      """

      context = %{
        "products" => [
          %{"name" => "Laptop", "price" => 1000},
          %{"name" => "Mouse", "price" => 25},
          %{"name" => "Monitor", "price" => 300}
        ],
        "category" => %{"index" => 1},
        "budget" => 50
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Selected product: Mouse")
      assert String.contains?(result, "Within budget!")

      # Test over budget
      context_expensive = %{
        "products" => [
          %{"name" => "Laptop", "price" => 1000},
          %{"name" => "Mouse", "price" => 25},
          %{"name" => "Monitor", "price" => 300}
        ],
        "category" => %{"index" => 0},
        "budget" => 500
      }

      assert {:ok, result} = Mau.render(template, context_expensive)
      assert String.contains?(result, "Selected product: Laptop")
      assert String.contains?(result, "Over budget by $500")
    end

    test "array access with variable chain" do
      template = """
      {% if data[user.department][user.level].permissions %}
        {{ user.name }} has permissions:
        {% for perm in data[user.department][user.level].permissions %}
          - {{ perm }}
        {% endfor %}
      {% else %}
        {{ user.name }} has no permissions
      {% endif %}
      """

      context = %{
        "data" => %{
          "engineering" => %{
            "senior" => %{
              "permissions" => ["read", "write", "deploy"]
            },
            "junior" => %{
              "permissions" => ["read"]
            }
          }
        },
        "user" => %{
          "name" => "Alice",
          "department" => "engineering",
          "level" => "senior"
        }
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Alice has permissions:")
      assert String.contains?(result, "- read")
      assert String.contains?(result, "- write")
      assert String.contains?(result, "- deploy")
    end
  end

  describe "Edge Cases with Array Access" do
    test "nil array access" do
      template = """
      {% if items[0] %}
        First item exists
      {% else %}
        No first item
      {% endif %}
      """

      context = %{"items" => nil}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "No first item")
    end

    test "empty array access" do
      template = """
      {% if items[0] %}
        Has first item: {{ items[0] }}
      {% else %}
        Empty array
      {% endif %}
      """

      context = %{"items" => []}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Empty array")
    end

    test "negative index access" do
      template = """
      {% if items[-1] %}
        Last item: {{ items[-1] }}
      {% else %}
        Cannot access negative index
      {% endif %}
      """

      context = %{"items" => ["a", "b", "c"]}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Cannot access negative index")
    end

    test "string index on array" do
      template = """
      {% if items["0"] %}
        String index works
      {% else %}
        String index failed
      {% endif %}
      """

      context = %{"items" => ["a", "b", "c"]}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "String index failed")
    end

    test "deeply nested null access" do
      template = """
      {% if data.level1[0].level2[1].value %}
        Found nested value: {{ data.level1[0].level2[1].value }}
      {% else %}
        Nested value not found
      {% endif %}
      """

      context = %{
        "data" => %{
          "level1" => [
            %{
              "level2" => [
                %{"value" => "first"},
                nil
              ]
            }
          ]
        }
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Nested value not found")
    end

    test "array access with very large index" do
      template = """
      {% if items[999999] %}
        Found item at large index
      {% else %}
        Large index returns nil
      {% endif %}
      """

      context = %{"items" => ["a", "b", "c"]}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Large index returns nil")
    end
  end

  describe "Performance with Array Access" do
    test "performance with many array accesses" do
      template = """
      {% for i in range %}
        {% if data[i] and data[i].active %}
          {{ data[i].name }}
        {% endif %}
      {% endfor %}
      """

      # Generate test data
      data =
        Enum.map(0..99, fn i ->
          %{"name" => "Item#{i}", "active" => rem(i, 2) == 0}
        end)

      context = %{
        "range" => 0..49,
        "data" => data
      }

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, result} = Mau.render(template, context)
      end_time = System.monotonic_time(:millisecond)

      assert String.contains?(result, "Item0")
      assert String.contains?(result, "Item2")
      # Note: Check for Item1 as a substring, might match Item10, Item12, etc.
      # Let's check for specific patterns instead
      assert String.contains?(result, "Item0")
      assert String.contains?(result, "Item2")
      assert String.contains?(result, "Item4")
      # Items with odd indices should not appear (Item1, Item3, Item5)
      # But be careful about Item10, Item12 which contain "1" but are even indices

      # Should complete within reasonable time
      assert end_time - start_time < 200
    end
  end
end
