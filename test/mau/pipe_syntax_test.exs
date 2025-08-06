defmodule Mau.PipeSyntaxTest do
  use ExUnit.Case, async: true
  alias Mau

  describe "pipe syntax with arguments" do
    test "simple filter without arguments" do
      template = "{{ items | length }}"
      context = %{"items" => [1, 2, 3]}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "3"
    end

    test "filter with single argument" do
      template = "{{ text | truncate(3) }}"
      context = %{"text" => "hello world"}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "..."
    end

    test "filter with multiple arguments" do
      template = "{{ items | slice(1, 3) }}"
      context = %{"items" => [1, 2, 3, 4, 5]}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "[2, 3, 4]"
    end

    test "string filter with argument" do
      template = "{{ text | contains(\"ell\") }}"
      context = %{"text" => "hello"}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "true"
    end

    test "chained filters with arguments" do
      template = "{{ items | compact | slice(1, 2) | length }}"
      context = %{"items" => [1, nil, 2, 3, nil, 4]}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "2"
    end

    test "mixed simple and argument filters" do
      template = "{{ text | strip | truncate(5) | upper_case }}"
      context = %{"text" => "  hello world  "}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "HE..."
    end

    test "data processing chain with pipes" do
      template = "{{ users | filter(\"active\", true) | map(\"name\") | join(\", \") }}"

      context = %{
        "users" => [
          %{"name" => "Alice", "active" => true},
          %{"name" => "Bob", "active" => false},
          %{"name" => "Carol", "active" => true}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert result == "Alice, Carol"
    end

    test "number filters with arguments" do
      template = "{{ price | round(2) }}"
      context = %{"price" => 123.456}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "123.46"
    end

    test "collection manipulation with pipes" do
      template = "{{ items | compact | flatten | sum }}"
      context = %{"items" => [1, nil, [2, 3], nil, [4]]}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "10"
    end

    test "complex nested data processing" do
      template = "{{ data | group_by(\"category\") | keys | sort | join(\"-\") }}"

      context = %{
        "data" => [
          %{"name" => "Item1", "category" => "B"},
          %{"name" => "Item2", "category" => "A"},
          %{"name" => "Item3", "category" => "C"},
          %{"name" => "Item4", "category" => "A"}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      # Should be sorted alphabetically
      assert result == "A-B-C"
    end
  end
end
