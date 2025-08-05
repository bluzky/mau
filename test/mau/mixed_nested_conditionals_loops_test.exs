defmodule Mau.MixedNestedConditionalsLoopsTest do
  @moduledoc """
  Tests for mixed nested conditionals with loops.

  These tests ensure proper interaction between conditional blocks
  and loop blocks in various nested configurations.
  """

  use ExUnit.Case
  doctest Mau

  describe "Conditionals Inside Loops" do
    test "simple conditional inside loop" do
      template = """
      {% for item in items %}
        {% if item.active %}
          {{ item.name }}: Active
        {% endif %}
      {% endfor %}
      """

      context = %{
        "items" => [
          %{"name" => "Item1", "active" => true},
          %{"name" => "Item2", "active" => false},
          %{"name" => "Item3", "active" => true}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Item1: Active")
      refute String.contains?(result, "Item2: Active")
      assert String.contains?(result, "Item3: Active")
    end

    test "complex conditional with elsif inside loop" do
      template = """
      {% for user in users %}
        {% if user.role == "admin" %}
          [ADMIN] {{ user.name }}
        {% elsif user.role == "moderator" %}
          [MOD] {{ user.name }}
        {% else %}
          [USER] {{ user.name }}
        {% endif %}
      {% endfor %}
      """

      context = %{
        "users" => [
          %{"name" => "Alice", "role" => "admin"},
          %{"name" => "Bob", "role" => "moderator"},
          %{"name" => "Charlie", "role" => "user"}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "[ADMIN] Alice")
      assert String.contains?(result, "[MOD] Bob")
      assert String.contains?(result, "[USER] Charlie")
    end

    test "nested conditionals inside loop" do
      template = """
      {% for product in products %}
        {% if product.available %}
          {{ product.name }}
          {% if product.sale %}
            - ON SALE: ${{ product.price }}
            {% if product.discount > 20 %}
              - HUGE DISCOUNT!
            {% endif %}
          {% else %}
            - Regular: ${{ product.price }}
          {% endif %}
        {% endif %}
      {% endfor %}
      """

      context = %{
        "products" => [
          %{
            "name" => "Laptop",
            "available" => true,
            "sale" => true,
            "price" => 999,
            "discount" => 25
          },
          %{
            "name" => "Mouse",
            "available" => true,
            "sale" => false,
            "price" => 25,
            "discount" => 0
          },
          %{
            "name" => "Monitor",
            "available" => false,
            "sale" => true,
            "price" => 300,
            "discount" => 15
          }
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Laptop")
      assert String.contains?(result, "ON SALE: $999")
      assert String.contains?(result, "HUGE DISCOUNT!")
      assert String.contains?(result, "Mouse")
      assert String.contains?(result, "Regular: $25")
      refute String.contains?(result, "Monitor")
    end

    test "conditional with forloop variables" do
      template = """
      {% for item in items %}
        {% if forloop.first %}
          <ul>
        {% endif %}
          <li>{{ item }} ({{ forloop.index }})</li>
        {% if forloop.last %}
          </ul>
        {% endif %}
      {% endfor %}
      """

      context = %{"items" => ["apple", "banana", "cherry"]}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "<ul>")
      assert String.contains?(result, "apple (0)")
      assert String.contains?(result, "banana (1)")
      assert String.contains?(result, "cherry (2)")
      assert String.contains?(result, "</ul>")
    end
  end

  describe "Loops Inside Conditionals" do
    test "simple loop inside conditional" do
      template = """
      {% if show_items %}
        Items:
        {% for item in items %}
          - {{ item }}
        {% endfor %}
      {% endif %}
      """

      context = %{
        "show_items" => true,
        "items" => ["apple", "banana", "cherry"]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Items:")
      assert String.contains?(result, "- apple")
      assert String.contains?(result, "- banana")
      assert String.contains?(result, "- cherry")

      # Test with show_items false
      context_false = Map.put(context, "show_items", false)
      assert {:ok, result_false} = Mau.render(template, context_false)
      refute String.contains?(result_false, "Items:")
      refute String.contains?(result_false, "- apple")
    end

    test "multiple loops inside conditional branches" do
      template = """
      {% if mode == "fruits" %}
        Fruits:
        {% for fruit in fruits %}
          * {{ fruit }}
        {% endfor %}
      {% elsif mode == "colors" %}
        Colors:
        {% for color in colors %}
          * {{ color }}
        {% endfor %}
      {% else %}
        Both:
        {% for fruit in fruits %}
          Fruit: {{ fruit }}
        {% endfor %}
        {% for color in colors %}
          Color: {{ color }}
        {% endfor %}
      {% endif %}
      """

      context = %{
        "mode" => "fruits",
        "fruits" => ["apple", "orange"],
        "colors" => ["red", "blue"]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Fruits:")
      assert String.contains?(result, "* apple")
      assert String.contains?(result, "* orange")
      refute String.contains?(result, "* red")

      # Test colors mode
      context_colors = Map.put(context, "mode", "colors")
      assert {:ok, result_colors} = Mau.render(template, context_colors)
      assert String.contains?(result_colors, "Colors:")
      assert String.contains?(result_colors, "* red")
      assert String.contains?(result_colors, "* blue")
      refute String.contains?(result_colors, "* apple")

      # Test both mode
      context_both = Map.put(context, "mode", "both")
      assert {:ok, result_both} = Mau.render(template, context_both)
      assert String.contains?(result_both, "Both:")
      assert String.contains?(result_both, "Fruit: apple")
      assert String.contains?(result_both, "Color: red")
    end

    test "nested loops inside nested conditionals" do
      template = """
      {% if user.admin %}
        Admin Dashboard
        {% if departments %}
          {% for dept in departments %}
            Department: {{ dept.name }}
            {% if dept.employees %}
              Employees:
              {% for emp in dept.employees %}
                - {{ emp.name }} ({{ emp.role }})
              {% endfor %}
            {% endif %}
          {% endfor %}
        {% endif %}
      {% endif %}
      """

      context = %{
        "user" => %{"admin" => true},
        "departments" => [
          %{
            "name" => "Engineering",
            "employees" => [
              %{"name" => "Alice", "role" => "Developer"},
              %{"name" => "Bob", "role" => "Lead"}
            ]
          },
          %{
            "name" => "Marketing",
            "employees" => [
              %{"name" => "Carol", "role" => "Manager"}
            ]
          }
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Admin Dashboard")
      assert String.contains?(result, "Department: Engineering")
      assert String.contains?(result, "- Alice (Developer)")
      assert String.contains?(result, "- Bob (Lead)")
      assert String.contains?(result, "Department: Marketing")
      assert String.contains?(result, "- Carol (Manager)")
    end
  end

  describe "Complex Mixed Nesting" do
    test "alternating conditionals and loops (3 levels)" do
      template = """
      {% if show_categories %}
        {% for category in categories %}
          <h2>{{ category.name }}</h2>
          {% if category.items %}
            {% for item in category.items %}
              {% if item.featured %}
                <strong>{{ item.name }}</strong> - Featured!
              {% else %}
                {{ item.name }}
              {% endif %}
            {% endfor %}
          {% endif %}
        {% endfor %}
      {% endif %}
      """

      context = %{
        "show_categories" => true,
        "categories" => [
          %{
            "name" => "Electronics",
            "items" => [
              %{"name" => "Laptop", "featured" => true},
              %{"name" => "Mouse", "featured" => false}
            ]
          },
          %{
            "name" => "Books",
            "items" => [
              %{"name" => "Fiction Book", "featured" => false},
              %{"name" => "Tech Book", "featured" => true}
            ]
          }
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "<h2>Electronics</h2>")
      assert String.contains?(result, "<strong>Laptop</strong> - Featured!")
      assert String.contains?(result, "Mouse")
      refute String.contains?(result, "<strong>Mouse</strong>")
      assert String.contains?(result, "<h2>Books</h2>")
      assert String.contains?(result, "Fiction Book")
      assert String.contains?(result, "<strong>Tech Book</strong> - Featured!")
    end

    test "loops with nested conditionals and inner loops" do
      template = """
      {% for team in teams %}
        Team: {{ team.name }}
        {% if team.active %}
          Status: Active
          {% for member in team.members %}
            {% if member.lead %}
              >> Lead: {{ member.name }}
              {% for skill in member.skills %}
                - {{ skill }}
              {% endfor %}
            {% else %}
              > Member: {{ member.name }}
            {% endif %}
          {% endfor %}
        {% else %}
          Status: Inactive
        {% endif %}
        ---
      {% endfor %}
      """

      context = %{
        "teams" => [
          %{
            "name" => "Alpha",
            "active" => true,
            "members" => [
              %{
                "name" => "Alice",
                "lead" => true,
                "skills" => ["Python", "JavaScript"]
              },
              %{
                "name" => "Bob",
                "lead" => false,
                "skills" => []
              }
            ]
          },
          %{
            "name" => "Beta",
            "active" => false,
            "members" => []
          }
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Team: Alpha")
      assert String.contains?(result, "Status: Active")
      assert String.contains?(result, ">> Lead: Alice")
      assert String.contains?(result, "- Python")
      assert String.contains?(result, "- JavaScript")
      assert String.contains?(result, "> Member: Bob")
      assert String.contains?(result, "Team: Beta")
      assert String.contains?(result, "Status: Inactive")
    end

    test "performance test with deep mixed nesting" do
      template = """
      {% for i in range %}
        Level {{ i }}:
        {% if i > 2 %}
          {% for j in subrange %}
            {% if j == 1 %}
              Inner: {{ i }}.{{ j }}
            {% endif %}
          {% endfor %}
        {% endif %}
      {% endfor %}
      """

      context = %{
        "range" => [1, 2, 3, 4, 5],
        "subrange" => [1, 2, 3]
      }

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, result} = Mau.render(template, context)
      end_time = System.monotonic_time(:millisecond)

      assert String.contains?(result, "Level 1:")
      assert String.contains?(result, "Level 5:")
      assert String.contains?(result, "Inner: 3.1")
      assert String.contains?(result, "Inner: 4.1")
      assert String.contains?(result, "Inner: 5.1")

      # Should complete within reasonable time
      assert end_time - start_time < 100
    end
  end

  describe "Edge Cases in Mixed Nesting" do
    test "empty collections in nested structures" do
      template = """
      {% for group in groups %}
        Group: {{ group.name }}
        {% if group.items %}
          {% for item in group.items %}
            - {{ item }}
          {% endfor %}
        {% else %}
          (No items)
        {% endif %}
      {% endfor %}
      """

      context = %{
        "groups" => [
          %{"name" => "Full", "items" => ["A", "B"]},
          %{"name" => "Empty", "items" => []},
          %{"name" => "Nil", "items" => nil}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Group: Full")
      assert String.contains?(result, "- A")
      assert String.contains?(result, "- B")
      assert String.contains?(result, "Group: Empty")
      assert String.contains?(result, "(No items)")
      assert String.contains?(result, "Group: Nil")
    end

    test "deeply nested with variable resolution" do
      template = """
      {% for user in users %}
        {% if user.preferences.notifications %}
          {{ user.name }} notifications:
          {% for notification in user.notifications %}
            {% if notification.type == user.preferences.priority_type %}
              PRIORITY: {{ notification.message }}
            {% else %}
              {{ notification.message }}
            {% endif %}
          {% endfor %}
        {% endif %}
      {% endfor %}
      """

      context = %{
        "users" => [
          %{
            "name" => "Alice",
            "preferences" => %{"notifications" => true, "priority_type" => "urgent"},
            "notifications" => [
              %{"type" => "info", "message" => "Welcome"},
              %{"type" => "urgent", "message" => "Action required"}
            ]
          }
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Alice notifications:")
      assert String.contains?(result, "Welcome")
      assert String.contains?(result, "PRIORITY: Action required")
    end
  end
end
