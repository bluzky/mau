defmodule MauTest do
  use ExUnit.Case
  doctest Mau

  describe "Integration Tests - Group 1: Plain Text Templates" do
    test "compile and render plain text" do
      assert {:ok, [{:text, ["Hello world"], []}]} = Mau.compile("Hello world")
      assert {:ok, "Hello world"} = Mau.render("Hello world", %{})
    end

    test "compile with strict mode returns warnings tuple" do
      assert {:ok, [{:text, ["Hello"], []}], []} = Mau.compile("Hello", strict_mode: true)
    end

    test "compile with ease mode returns simple tuple" do
      assert {:ok, [{:text, ["Hello"], []}]} = Mau.compile("Hello", strict_mode: false)
    end

    test "render_map with plain text values" do
      input = %{
        message: "Hello world",
        title: "Welcome",
        nested: %{
          content: "Nested content"
        }
      }

      expected = %{
        message: "Hello world",
        title: "Welcome",
        nested: %{
          content: "Nested content"
        }
      }

      assert {:ok, ^expected} = Mau.render_map(input, %{})
    end

    test "render_map preserves non-string values" do
      input = %{
        text: "Hello",
        number: 42,
        boolean: true,
        list: [1, 2, 3],
        nil_value: nil
      }

      assert {:ok, ^input} = Mau.render_map(input, %{})
    end
  end
end
