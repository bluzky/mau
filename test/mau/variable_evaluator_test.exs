defmodule Mau.VariableEvaluatorTest do
  use ExUnit.Case
  alias Mau.Renderer

  describe "variable evaluation" do
    test "evaluates simple variable" do
      context = %{"user" => "Alice"}
      variable_ast = {:variable, ["user"], []}
      assert {:ok, "Alice"} = Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "evaluates undefined variable as empty string" do
      context = %{}
      variable_ast = {:variable, ["undefined"], []}
      assert {:ok, ""} = Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "evaluates property access" do
      context = %{"user" => %{"name" => "Bob"}}
      variable_ast = {:variable, ["user", {:property, "name"}], []}
      assert {:ok, "Bob"} = Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "evaluates nested property access" do
      context = %{"user" => %{"profile" => %{"email" => "bob@example.com"}}}
      variable_ast = {:variable, ["user", {:property, "profile"}, {:property, "email"}], []}

      assert {:ok, "bob@example.com"} =
               Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "evaluates array index access" do
      context = %{"users" => ["Alice", "Bob", "Charlie"]}
      variable_ast = {:variable, ["users", {:index, 1}], []}
      assert {:ok, "Bob"} = Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "evaluates array index with property access" do
      context = %{
        "users" => [
          %{"name" => "Alice", "age" => 30},
          %{"name" => "Bob", "age" => 25}
        ]
      }

      variable_ast = {:variable, ["users", {:index, 0}, {:property, "name"}], []}
      assert {:ok, "Alice"} = Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "evaluates workflow variable" do
      context = %{"$input" => %{"data" => "workflow data"}}
      variable_ast = {:variable, ["$input", {:property, "data"}], []}

      assert {:ok, "workflow data"} =
               Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "evaluates complex workflow variable path" do
      context = %{
        "$variables" => %{
          "user_data" => %{
            "settings" => %{
              "theme" => "dark"
            }
          }
        }
      }

      variable_ast =
        {:variable,
         ["$variables", {:property, "user_data"}, {:property, "settings"}, {:property, "theme"}],
         []}

      assert {:ok, "dark"} = Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "handles out of bounds array access" do
      context = %{"users" => ["Alice", "Bob"]}
      variable_ast = {:variable, ["users", {:index, 5}], []}
      assert {:ok, ""} = Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "handles property access on non-map" do
      context = %{"value" => "string"}
      variable_ast = {:variable, ["value", {:property, "length"}], []}
      assert {:ok, ""} = Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "handles array access on non-list" do
      context = %{"value" => "string"}
      variable_ast = {:variable, ["value", {:index, 0}], []}
      assert {:ok, ""} = Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "evaluates number variable" do
      context = %{"count" => 42}
      variable_ast = {:variable, ["count"], []}
      assert {:ok, "42"} = Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "evaluates boolean variable" do
      context = %{"active" => true}
      variable_ast = {:variable, ["active"], []}
      assert {:ok, "true"} = Renderer.render_node({:expression, [variable_ast], []}, context)
    end

    test "evaluates nested array access" do
      context = %{"matrix" => [[1, 2, 3], [4, 5, 6], [7, 8, 9]]}
      variable_ast = {:variable, ["matrix", {:index, 1}, {:index, 2}], []}
      assert {:ok, "6"} = Renderer.render_node({:expression, [variable_ast], []}, context)
    end
  end
end
