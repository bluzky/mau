defmodule Mau.CondDirectiveTest do
  use ExUnit.Case
  doctest Mau

  describe "#cond directive" do
    test "returns first truthy condition" do
      template = %{
        "#cond" => [
          [
            ["{{ score > 90 }}", %{"grade" => "A"}],
            ["{{ score > 80 }}", %{"grade" => "B"}],
            ["{{ score > 70 }}", %{"grade" => "C"}]
          ]
        ]
      }

      context = %{"score" => 95}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"grade" => "A"}
    end

    test "returns second condition when first is false" do
      template = %{
        "#cond" => [
          [
            ["{{ score > 90 }}", %{"grade" => "A"}],
            ["{{ score > 80 }}", %{"grade" => "B"}],
            ["{{ score > 70 }}", %{"grade" => "C"}]
          ]
        ]
      }

      context = %{"score" => 85}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"grade" => "B"}
    end

    test "returns last condition" do
      template = %{
        "#cond" => [
          [
            ["{{ score > 90 }}", %{"grade" => "A"}],
            ["{{ score > 80 }}", %{"grade" => "B"}],
            ["{{ score > 70 }}", %{"grade" => "C"}]
          ]
        ]
      }

      context = %{"score" => 72}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"grade" => "C"}
    end

    test "returns nil when no condition matches" do
      template = %{
        "#cond" => [
          [
            ["{{ score > 90 }}", %{"grade" => "A"}],
            ["{{ score > 80 }}", %{"grade" => "B"}],
            ["{{ score > 70 }}", %{"grade" => "C"}]
          ]
        ]
      }

      context = %{"score" => 60}
      {:ok, result} = Mau.render_map(template, context)
      assert result == nil
    end

    test "uses true as default condition" do
      template = %{
        "#cond" => [
          [
            ["{{ score > 90 }}", %{"grade" => "A"}],
            ["{{ score > 80 }}", %{"grade" => "B"}],
            ["{{ score > 70 }}", %{"grade" => "C"}],
            ["{{ true }}", %{"grade" => "F"}]
          ]
        ]
      }

      context = %{"score" => 60}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"grade" => "F"}
    end

    test "works with boolean variables" do
      template = %{
        "#cond" => [
          [
            ["{{ is_admin }}", %{"role" => "Administrator"}],
            ["{{ is_moderator }}", %{"role" => "Moderator"}],
            ["{{ true }}", %{"role" => "User"}]
          ]
        ]
      }

      context = %{"is_admin" => false, "is_moderator" => true}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"role" => "Moderator"}
    end

    test "works with complex conditions" do
      template = %{
        "#cond" => [
          [
            ["{{ age >= 18 and has_license }}", %{"status" => "Can drive"}],
            ["{{ age >= 18 }}", %{"status" => "Adult, needs license"}],
            ["{{ age >= 16 }}", %{"status" => "Can get learner permit"}],
            ["{{ true }}", %{"status" => "Too young"}]
          ]
        ]
      }

      context = %{"age" => 17, "has_license" => false}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"status" => "Can get learner permit"}
    end

    test "works with string comparisons" do
      template = %{
        "#cond" => [
          [
            ["{{ name == \"Alice\" }}", %{"greeting" => "Hi Alice!"}],
            ["{{ name == \"Bob\" }}", %{"greeting" => "Hi Bob!"}],
            ["{{ true }}", %{"greeting" => "Hi stranger!"}]
          ]
        ]
      }

      context = %{"name" => "Charlie"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"greeting" => "Hi stranger!"}
    end

    test "first truthy condition wins" do
      template = %{
        "#cond" => [
          [
            ["{{ value > 5 }}", %{"result" => "Greater than 5"}],
            ["{{ value > 3 }}", %{"result" => "Greater than 3"}],
            ["{{ value > 1 }}", %{"result" => "Greater than 1"}]
          ]
        ]
      }

      context = %{"value" => 10}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"result" => "Greater than 5"}
    end

    test "works with template expressions in result" do
      template = %{
        "#cond" => [
          [
            ["{{ temp > 30 }}", %{"status" => "Hot", "value" => "{{ temp }}C"}],
            ["{{ temp > 20 }}", %{"status" => "Warm", "value" => "{{ temp }}C"}],
            ["{{ temp > 10 }}", %{"status" => "Cool", "value" => "{{ temp }}C"}],
            ["{{ true }}", %{"status" => "Cold", "value" => "{{ temp }}C"}]
          ]
        ]
      }

      context = %{"temp" => 25}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"status" => "Warm", "value" => "25C"}
    end

    test "works with nested maps in result" do
      template = %{
        "#cond" => [
          [
            ["{{ level == \"premium\" }}", %{"access" => %{"features" => "all", "support" => "priority"}}],
            ["{{ level == \"basic\" }}", %{"access" => %{"features" => "limited", "support" => "standard"}}],
            ["{{ true }}", %{"access" => %{"features" => "none", "support" => "none"}}]
          ]
        ]
      }

      context = %{"level" => "basic"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"access" => %{"features" => "limited", "support" => "standard"}}
    end

    test "can be nested within merge directive" do
      template = %{
        "#map" => [
          "{{ users }}",
          %{
            "#merge" => [
              %{"name" => "{{ $loop.item.name }}"},
              %{
                "#cond" => [
                  [
                    ["{{ $loop.item.age >= 18 }}", %{"status" => "Adult"}],
                    ["{{ $loop.item.age >= 13 }}", %{"status" => "Teen"}],
                    ["{{ true }}", %{"status" => "Child"}]
                  ]
                ]
              }
            ]
          }
        ]
      }

      context = %{
        "users" => [
          %{"name" => "Alice", "age" => 25},
          %{"name" => "Bob", "age" => 16},
          %{"name" => "Charlie", "age" => 10}
        ]
      }

      {:ok, result} = Mau.render_map(template, context)

      assert result == [
               %{"name" => "Alice", "status" => "Adult"},
               %{"name" => "Bob", "status" => "Teen"},
               %{"name" => "Charlie", "status" => "Child"}
             ]
    end

    test "handles empty conditions list" do
      template = %{
        "#cond" => [
          []
        ]
      }

      context = %{}
      {:ok, result} = Mau.render_map(template, context)
      assert result == nil
    end

    test "works with arithmetic expressions" do
      template = %{
        "#cond" => [
          [
            ["{{ (price * quantity) > 100 }}", %{"discount" => "10%"}],
            ["{{ (price * quantity) > 50 }}", %{"discount" => "5%"}],
            ["{{ true }}", %{"discount" => "0%"}]
          ]
        ]
      }

      context = %{"price" => 15, "quantity" => 5}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"discount" => "5%"}
    end

    test "works with logical or conditions" do
      template = %{
        "#cond" => [
          [
            ["{{ is_vip or is_member }}", %{"access" => "Premium"}],
            ["{{ true }}", %{"access" => "Basic"}]
          ]
        ]
      }

      context = %{"is_vip" => false, "is_member" => true}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"access" => "Premium"}
    end

    test "evaluates conditions with falsy values correctly" do
      template = %{
        "#cond" => [
          [
            ["{{ count > 0 }}", %{"status" => "Has items"}],
            ["{{ count == 0 }}", %{"status" => "Empty"}],
            ["{{ true }}", %{"status" => "Unknown"}]
          ]
        ]
      }

      context = %{"count" => 0}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"status" => "Empty"}
    end

    test "can use cond with case for complex logic" do
      template = %{
        "#cond" => [
          [
            ["{{ type == \"A\" }}", %{
              "#case" => [
                "{{ priority }}",
                [
                  ["high", %{"action" => "Process immediately"}],
                  ["low", %{"action" => "Queue for later"}]
                ]
              ]
            }],
            ["{{ true }}", %{"action" => "No action needed"}]
          ]
        ]
      }

      context = %{"type" => "A", "priority" => "high"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"action" => "Process immediately"}
    end
  end
end
