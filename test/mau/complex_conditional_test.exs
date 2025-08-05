defmodule Mau.ComplexConditionalTest do
  use ExUnit.Case, async: true

  describe "complex conditional scenarios" do
    test "handles if/elsif/else with complex boolean conditions" do
      template = "{% if user.active and user.verified %}Welcome {{ user.name }}!{% elsif user.active %}Please verify your account.{% else %}Account inactive.{% endif %}"
      
      # Test if branch (both conditions true)
      context1 = %{
        "user" => %{
          "active" => true,
          "verified" => true,
          "name" => "Charlie"
        }
      }
      assert {:ok, "Welcome Charlie!"} = Mau.render(template, context1)

      # Test elsif branch (active but not verified)
      context2 = %{
        "user" => %{
          "active" => true,
          "verified" => false,
          "name" => "Bob"
        }
      }
      assert {:ok, "Please verify your account."} = Mau.render(template, context2)

      # Test else branch (not active)
      context3 = %{
        "user" => %{
          "active" => false,
          "verified" => false,
          "name" => "Alice"
        }
      }
      assert {:ok, "Account inactive."} = Mau.render(template, context3)
    end

    test "handles multiple elsif branches" do
      template = """
      {% if score >= 90 %}A{% elsif score >= 80 %}B{% elsif score >= 70 %}C{% elsif score >= 60 %}D{% else %}F{% endif %}
      """

      # Test first elsif (80-89)
      assert {:ok, "B\n"} = Mau.render(template, %{"score" => 85})
      
      # Test second elsif (70-79)
      assert {:ok, "C\n"} = Mau.render(template, %{"score" => 75})
      
      # Test third elsif (60-69)
      assert {:ok, "D\n"} = Mau.render(template, %{"score" => 65})
      
      # Test else (below 60)
      assert {:ok, "F\n"} = Mau.render(template, %{"score" => 55})
      
      # Test if (90+)
      assert {:ok, "A\n"} = Mau.render(template, %{"score" => 95})
    end

    test "handles nested conditionals" do
      template = """
      {% if user %}
        {% if user.active %}
          {% if user.role == "admin" %}
            Admin Dashboard
          {% else %}
            User Dashboard
          {% endif %}
        {% else %}
          Account Suspended
        {% endif %}
      {% else %}
        Please Login
      {% endif %}
      """

      # Test admin user
      context1 = %{
        "user" => %{
          "active" => true,
          "role" => "admin"
        }
      }
      assert {:ok, result1} = Mau.render(template, context1)
      assert String.contains?(result1, "Admin Dashboard")

      # Test regular user
      context2 = %{
        "user" => %{
          "active" => true,
          "role" => "user"
        }
      }
      assert {:ok, result2} = Mau.render(template, context2)
      assert String.contains?(result2, "User Dashboard")

      # Test suspended user
      context3 = %{
        "user" => %{
          "active" => false,
          "role" => "user"
        }
      }
      assert {:ok, result3} = Mau.render(template, context3)
      assert String.contains?(result3, "Account Suspended")

      # Test no user
      context4 = %{}
      assert {:ok, result4} = Mau.render(template, context4)
      assert String.contains?(result4, "Please Login")
    end

    test "handles conditionals with complex variable access" do
      template = "{% if product.inventory.stock > 0 and product.status == \"available\" %}In Stock{% else %}Out of Stock{% endif %}"
      
      # Test in stock
      context1 = %{
        "product" => %{
          "inventory" => %{"stock" => 5},
          "status" => "available"
        }
      }
      assert {:ok, "In Stock"} = Mau.render(template, context1)

      # Test out of stock (no inventory)
      context2 = %{
        "product" => %{
          "inventory" => %{"stock" => 0},
          "status" => "available"
        }
      }
      assert {:ok, "Out of Stock"} = Mau.render(template, context2)

      # Test out of stock (unavailable)
      context3 = %{
        "product" => %{
          "inventory" => %{"stock" => 5},
          "status" => "discontinued"
        }
      }
      assert {:ok, "Out of Stock"} = Mau.render(template, context3)
    end

    test "handles conditionals with OR logic" do
      template = "{% if user.role == \"admin\" or user.role == \"moderator\" %}Staff Access{% else %}Regular User{% endif %}"
      
      # Test admin
      assert {:ok, "Staff Access"} = Mau.render(template, %{"user" => %{"role" => "admin"}})
      
      # Test moderator
      assert {:ok, "Staff Access"} = Mau.render(template, %{"user" => %{"role" => "moderator"}})
      
      # Test regular user
      assert {:ok, "Regular User"} = Mau.render(template, %{"user" => %{"role" => "user"}})
    end

    test "handles conditionals with NOT logic" do
      template = "{% if not user.banned %}Welcome!{% else %}Access Denied{% endif %}"
      
      # Test not banned
      assert {:ok, "Welcome!"} = Mau.render(template, %{"user" => %{"banned" => false}})
      
      # Test banned
      assert {:ok, "Access Denied"} = Mau.render(template, %{"user" => %{"banned" => true}})
      
      # Test missing banned field (should be falsy)
      assert {:ok, "Welcome!"} = Mau.render(template, %{"user" => %{}})
    end

    test "handles empty if branches correctly" do
      # This was the original bug - empty if branch should render nothing
      template = "{% if true %}{% else %}Hidden{% endif %}"
      assert {:ok, ""} = Mau.render(template, %{})
      
      template2 = "{% if false %}{% else %}Visible{% endif %}"
      assert {:ok, "Visible"} = Mau.render(template2, %{})
    end

    test "handles complex expressions in conditions" do
      template = "{% if (user.age >= 18) and (user.country == \"US\" or user.country == \"CA\") %}Eligible{% else %}Not Eligible{% endif %}"
      
      # Test eligible US user
      context1 = %{"user" => %{"age" => 25, "country" => "US"}}
      assert {:ok, "Eligible"} = Mau.render(template, context1)
      
      # Test eligible CA user
      context2 = %{"user" => %{"age" => 20, "country" => "CA"}}
      assert {:ok, "Eligible"} = Mau.render(template, context2)
      
      # Test ineligible (too young)
      context3 = %{"user" => %{"age" => 16, "country" => "US"}}
      assert {:ok, "Not Eligible"} = Mau.render(template, context3)
      
      # Test ineligible (wrong country)
      context4 = %{"user" => %{"age" => 25, "country" => "FR"}}
      assert {:ok, "Not Eligible"} = Mau.render(template, context4)
    end

    test "handles conditionals with variable interpolation in branches" do
      template = "{% if user.premium %}Hello {{ user.title }} {{ user.name }}!{% else %}Hello {{ user.name }}!{% endif %}"
      
      # Test premium user
      context1 = %{
        "user" => %{
          "premium" => true,
          "title" => "Dr.",
          "name" => "Smith"
        }
      }
      assert {:ok, "Hello Dr. Smith!"} = Mau.render(template, context1)
      
      # Test regular user
      context2 = %{
        "user" => %{
          "premium" => false,
          "name" => "John"
        }
      }
      assert {:ok, "Hello John!"} = Mau.render(template, context2)
    end
  end
end