defmodule Mau.RendererTest do
  use ExUnit.Case
  doctest Mau.Renderer

  alias Mau.Renderer
  alias Mau.AST.Nodes

  describe "Group 1: Text Node Rendering" do
    test "renders text node" do
      node = Nodes.text_node("Hello world")
      assert {:ok, "Hello world"} = Renderer.render_node(node, %{})
    end

    test "renders empty text node" do
      node = Nodes.text_node("")
      assert {:ok, ""} = Renderer.render_node(node, %{})
    end

    test "renders multiline text node" do
      text = "Line 1\nLine 2\nLine 3"
      node = Nodes.text_node(text)
      assert {:ok, ^text} = Renderer.render_node(node, %{})
    end

    test "renders text with special characters" do
      text = "Special chars: !@#$%^&*()_+-=[]{}|;:,.<>?"
      node = Nodes.text_node(text)
      assert {:ok, ^text} = Renderer.render_node(node, %{})
    end

    test "handles unknown node types with error" do
      invalid_node = {:unknown, ["data"], []}
      assert {:error, %Mau.Error{type: :runtime}} = Renderer.render_node(invalid_node, %{})
    end
  end

  describe "Template Rendering" do
    test "renders AST directly" do
      ast = Nodes.text_node("Hello world")
      assert {:ok, "Hello world"} = Renderer.render(ast, %{})
    end
  end
end