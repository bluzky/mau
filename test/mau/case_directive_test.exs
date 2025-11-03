defmodule Mau.CaseDirectiveTest do
  use ExUnit.Case
  doctest Mau

  describe "#case directive" do
    test "matches first pattern" do
      template = %{
        "#case" => [
          "{{ status }}",
          [
            ["pending", %{"message" => "Waiting"}],
            ["active", %{"message" => "Running"}],
            ["completed", %{"message" => "Done"}]
          ]
        ]
      }

      context = %{"status" => "pending"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"message" => "Waiting"}
    end

    test "matches middle pattern" do
      template = %{
        "#case" => [
          "{{ status }}",
          [
            ["pending", %{"message" => "Waiting"}],
            ["active", %{"message" => "Running"}],
            ["completed", %{"message" => "Done"}]
          ]
        ]
      }

      context = %{"status" => "active"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"message" => "Running"}
    end

    test "matches last pattern" do
      template = %{
        "#case" => [
          "{{ status }}",
          [
            ["pending", %{"message" => "Waiting"}],
            ["active", %{"message" => "Running"}],
            ["completed", %{"message" => "Done"}]
          ]
        ]
      }

      context = %{"status" => "completed"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"message" => "Done"}
    end

    test "returns nil when no pattern matches and no default" do
      template = %{
        "#case" => [
          "{{ status }}",
          [
            ["pending", %{"message" => "Waiting"}],
            ["active", %{"message" => "Running"}]
          ]
        ]
      }

      context = %{"status" => "unknown"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == nil
    end

    test "returns default when no pattern matches" do
      template = %{
        "#case" => [
          "{{ status }}",
          [
            ["pending", %{"message" => "Waiting"}],
            ["active", %{"message" => "Running"}]
          ],
          %{"message" => "Unknown status"}
        ]
      }

      context = %{"status" => "unknown"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"message" => "Unknown status"}
    end

    test "matches with template patterns" do
      template = %{
        "#case" => [
          "{{ count }}",
          [
            ["{{ zero }}", %{"result" => "Zero"}],
            ["{{ one }}", %{"result" => "One"}],
            ["{{ two }}", %{"result" => "Two"}]
          ]
        ]
      }

      context = %{"count" => 1, "zero" => 0, "one" => 1, "two" => 2}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"result" => "One"}
    end

    test "matches with numeric values" do
      template = %{
        "#case" => [
          "{{ code }}",
          [
            [200, %{"status" => "OK"}],
            [404, %{"status" => "Not Found"}],
            [500, %{"status" => "Server Error"}]
          ]
        ]
      }

      context = %{"code" => 404}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"status" => "Not Found"}
    end

    test "works with nested maps in result" do
      template = %{
        "#case" => [
          "{{ type }}",
          [
            ["user", %{"data" => %{"role" => "member", "access" => "limited"}}],
            ["admin", %{"data" => %{"role" => "admin", "access" => "full"}}]
          ]
        ]
      }

      context = %{"type" => "admin"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"data" => %{"role" => "admin", "access" => "full"}}
    end

    test "works with template expressions in result" do
      template = %{
        "#case" => [
          "{{ level }}",
          [
            ["low", %{"message" => "Priority: {{ level }}", "value" => "{{ priority }}"}],
            ["high", %{"message" => "Priority: {{ level }}", "value" => "{{ priority }}"}]
          ]
        ]
      }

      context = %{"level" => "high", "priority" => 10}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"message" => "Priority: high", "value" => 10}
    end

    test "first match wins when multiple patterns match" do
      template = %{
        "#case" => [
          "{{ value }}",
          [
            ["test", %{"result" => "First"}],
            ["test", %{"result" => "Second"}]
          ]
        ]
      }

      context = %{"value" => "test"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"result" => "First"}
    end

    test "can be nested within other directives" do
      template = %{
        "#map" => [
          "{{ items }}",
          %{
            "#case" => [
              "{{ $loop.item.type }}",
              [
                ["A", %{"category" => "Alpha", "value" => "{{ $loop.item.value }}"}],
                ["B", %{"category" => "Beta", "value" => "{{ $loop.item.value }}"}]
              ],
              %{"category" => "Unknown", "value" => "{{ $loop.item.value }}"}
            ]
          }
        ]
      }

      context = %{
        "items" => [
          %{"type" => "A", "value" => 1},
          %{"type" => "B", "value" => 2},
          %{"type" => "C", "value" => 3}
        ]
      }

      {:ok, result} = Mau.render_map(template, context)

      assert result == [
               %{"category" => "Alpha", "value" => 1},
               %{"category" => "Beta", "value" => 2},
               %{"category" => "Unknown", "value" => 3}
             ]
    end

    test "handles empty patterns list" do
      template = %{
        "#case" => [
          "{{ status }}",
          []
        ]
      }

      context = %{"status" => "test"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == nil
    end

    test "handles string matching case-sensitive" do
      template = %{
        "#case" => [
          "{{ name }}",
          [
            ["Alice", %{"greeting" => "Hello Alice"}],
            ["alice", %{"greeting" => "Hello alice"}]
          ]
        ]
      }

      context = %{"name" => "alice"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"greeting" => "Hello alice"}
    end

    test "handles boolean patterns" do
      template = %{
        "#case" => [
          "{{ active }}",
          [
            [true, %{"status" => "Active"}],
            [false, %{"status" => "Inactive"}]
          ]
        ]
      }

      context = %{"active" => true}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"status" => "Active"}
    end

    test "returns nil when pattern matches but template renders to nil" do
      template = %{
        "#case" => [
          "{{ status }}",
          [
            ["inactive", nil],
            ["active", %{"value" => "active"}]
          ],
          %{"value" => "default"}
        ]
      }

      context = %{"status" => "inactive"}
      {:ok, result} = Mau.render_map(template, context)
      # Should return nil from matched pattern, not fall through to default
      assert result == nil
    end

    test "returns nil result without falling to default" do
      template = %{
        "#case" => [
          "{{ type }}",
          [
            ["empty", %{"data" => nil}],
            ["full", %{"data" => "content"}]
          ],
          %{"data" => "default"}
        ]
      }

      context = %{"type" => "empty"}
      {:ok, result} = Mau.render_map(template, context)
      assert result == %{"data" => nil}
    end
  end
end
