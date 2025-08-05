defmodule Mau.AST.NodesTest do
  use ExUnit.Case
  doctest Mau.AST.Nodes

  alias Mau.AST.Nodes

  describe "Node Creation" do
    test "text_node/2 creates correct AST" do
      assert {:text, ["Hello"], []} = Nodes.text_node("Hello")
      assert {:text, ["Hello"], [trim_left: true]} = Nodes.text_node("Hello", trim_left: true)
    end

    test "literal_node/2 creates correct AST" do
      assert {:literal, [42], []} = Nodes.literal_node(42)
      assert {:literal, ["hello"], []} = Nodes.literal_node("hello")
      assert {:literal, [true], []} = Nodes.literal_node(true)
      assert {:literal, [nil], []} = Nodes.literal_node(nil)
      assert {:literal, [3.14], []} = Nodes.literal_node(3.14)
    end

    test "expression_node/2 creates correct AST" do
      expr = {:variable, ["name"], []}
      assert {:expression, [^expr], []} = Nodes.expression_node(expr)

      assert {:expression, [^expr], [trim_right: true]} =
               Nodes.expression_node(expr, trim_right: true)
    end

    test "tag_node/3 creates correct AST" do
      assert {:tag, [:assign, "name", {:literal, ["value"], []}], []} =
               Nodes.tag_node(:assign, ["name", {:literal, ["value"], []}])
    end

    test "variable_node/2 creates correct AST" do
      assert {:variable, ["name"], []} = Nodes.variable_node(["name"])
      assert {:variable, ["user", "name"], []} = Nodes.variable_node(["user", "name"])
      assert {:variable, ["$input"], []} = Nodes.variable_node(["$input"])
    end
  end

  describe "Options Handling" do
    test "all node types accept options" do
      opts = [trim_left: true, trim_right: false, line: 5]

      assert {:text, ["hello"], ^opts} = Nodes.text_node("hello", opts)
      assert {:literal, [42], ^opts} = Nodes.literal_node(42, opts)
      assert {:variable, ["name"], ^opts} = Nodes.variable_node(["name"], opts)
    end
  end
end
