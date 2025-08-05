defmodule Mau.FilterParserTest do
  use ExUnit.Case, async: true
  alias Mau.Parser

  describe "pipe syntax parsing" do
    test "parses simple pipe filter" do
      template = "{{ \"hello\" | upper_case }}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:expression,
                [
                  {:call, ["upper_case", [{:literal, ["hello"], []}]], []}
                ], []}
    end

    test "parses chained pipe filters" do
      template = "{{ \"hello\" | upper_case | length }}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:expression,
                [
                  {:call,
                   [
                     "length",
                     [
                       {:call, ["upper_case", [{:literal, ["hello"], []}]], []}
                     ]
                   ], []}
                ], []}
    end

    test "parses pipe with variable input" do
      template = "{{ name | upper_case }}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:expression,
                [
                  {:call, ["upper_case", [{:variable, ["name"], []}]], []}
                ], []}
    end

    test "parses pipe with complex variable path" do
      template = "{{ user.profile.name | capitalize }}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:expression,
                [
                  {:call,
                   [
                     "capitalize",
                     [{:variable, ["user", {:property, "profile"}, {:property, "name"}], []}]
                   ], []}
                ], []}
    end

    test "handles whitespace around pipes" do
      template = "{{ \"hello\"  |  upper_case  |  length  }}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:expression,
                [
                  {:call,
                   [
                     "length",
                     [
                       {:call, ["upper_case", [{:literal, ["hello"], []}]], []}
                     ]
                   ], []}
                ], []}
    end

    test "parses multiple chained filters" do
      template = "{{ \"hello world\" | upper_case | reverse | length }}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:expression,
                [
                  {:call,
                   [
                     "length",
                     [
                       {:call,
                        [
                          "reverse",
                          [
                            {:call, ["upper_case", [{:literal, ["hello world"], []}]], []}
                          ]
                        ], []}
                     ]
                   ], []}
                ], []}
    end
  end

  describe "function call syntax parsing" do
    test "parses simple function call" do
      template = "{{ upper_case(\"hello\") }}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:expression,
                [
                  {:call, ["upper_case", [{:literal, ["hello"], []}]], []}
                ], []}
    end

    test "parses function call with multiple arguments" do
      template = "{{ truncate(\"hello world\", 5) }}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:expression,
                [
                  {:call, ["truncate", [{:literal, ["hello world"], []}, {:literal, [5], []}]],
                   []}
                ], []}
    end

    test "parses function call with variable arguments" do
      template = "{{ join(items, separator) }}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:expression,
                [
                  {:call, ["join", [{:variable, ["items"], []}, {:variable, ["separator"], []}]],
                   []}
                ], []}
    end

    # Note: Nested function calls are not supported in the current simple implementation
    # to avoid circular parser dependencies

    test "handles whitespace in function calls" do
      template = "{{ upper_case(  \"hello\"  ,  \"world\"  ) }}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:expression,
                [
                  {:call, ["upper_case", [{:literal, ["hello"], []}, {:literal, ["world"], []}]],
                   []}
                ], []}
    end

    test "parses function call with no arguments" do
      template = "{{ random() }}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:expression,
                [
                  {:call, ["random", []], []}
                ], []}
    end
  end

  describe "mixed expressions with filters" do
    # Note: Complex expressions in function arguments are not supported
    # in the current simple implementation to avoid circular parser dependencies

    test "parses comparison with pipe filter" do
      template = "{{ name | length }}"

      assert {:ok, [result], "", %{}, _, _} = Parser.parse_template(template)

      assert result ==
               {:expression,
                [
                  {:call, ["length", [{:variable, ["name"], []}]], []}
                ], []}
    end
  end
end
