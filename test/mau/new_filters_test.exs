defmodule Mau.NewFiltersTest do
  use ExUnit.Case, async: true
  alias Mau

  describe "new collection filters" do
    test "slice filter with lists" do
      template = "{{ slice(items, 1, 3) }}"
      context = %{"items" => [1, 2, 3, 4, 5]}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "[2, 3, 4]"
    end

    test "slice filter with strings" do
      template = "{{ slice(text, 1, 3) }}"
      context = %{"text" => "hello"}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "ell"
    end

    test "contains filter with lists" do
      template = "{{ contains(items, 3) }}"
      context = %{"items" => [1, 2, 3, 4]}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "true"
    end

    test "contains filter with strings" do
      template = "{{ contains(text, \"ell\") }}"
      context = %{"text" => "hello"}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "true"
    end

    test "contains filter with maps" do
      template = "{{ contains(data, \"name\") }}"
      context = %{"data" => %{"name" => "Alice", "age" => 30}}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "true"
    end

    test "compact filter removes nil values" do
      template = "{{ items | compact }}"
      context = %{"items" => [1, nil, 2, nil, 3]}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "[1, 2, 3]"
    end

    test "flatten filter flattens nested lists" do
      template = "{{ items | flatten }}"
      context = %{"items" => [[1, 2], [3, 4], [5]]}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "[1, 2, 3, 4, 5]"
    end

    test "sum filter sums numeric values" do
      template = "{{ numbers | sum }}"
      context = %{"numbers" => [1, 2, 3, 4]}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "10"
    end

    test "sum filter rejects non-numeric values" do
      template = "{{ mixed | sum }}"
      context = %{"mixed" => [1, "hello", 2, nil, 3]}

      assert {:error, error} = Mau.render(template, context)
      assert error.message =~ "sum filter requires all elements to be numeric"
    end

    test "keys filter gets map keys" do
      template = "{{ data | keys }}"
      context = %{"data" => %{"name" => "Alice", "age" => 30}}

      assert {:ok, result} = Mau.render(template, context)
      # Keys can be in any order
      assert result in ["[\"name\", \"age\"]", "[\"age\", \"name\"]"]
    end

    test "values filter gets map values" do
      template = "{{ data | values }}"
      context = %{"data" => %{"name" => "Alice", "age" => 30}}

      assert {:ok, result} = Mau.render(template, context)
      # Values can be in any order
      assert result in ["[\"Alice\", 30]", "[30, \"Alice\"]"]
    end

    test "group_by filter groups by field" do
      template = "{% assign grouped = group_by(users, \"role\") %}{{ keys(grouped) }}"

      context = %{
        "users" => [
          %{"name" => "Alice", "role" => "admin"},
          %{"name" => "Bob", "role" => "user"},
          %{"name" => "Carol", "role" => "admin"}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      # Keys can be in any order
      assert result in ["[\"admin\", \"user\"]", "[\"user\", \"admin\"]"]
    end

    test "map filter extracts field values" do
      template = "{{ map(users, \"name\") }}"

      context = %{
        "users" => [
          %{"name" => "Alice", "age" => 30},
          %{"name" => "Bob", "age" => 25}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert result == "[\"Alice\", \"Bob\"]"
    end

    test "map filter filters out nil values and missing fields" do
      template = "{{ map(users, \"email\") }}"

      context = %{
        "users" => [
          %{"name" => "Alice", "email" => "alice@example.com"},
          # Missing email field
          %{"name" => "Bob"},
          %{"name" => "Carol", "email" => "carol@example.com"},
          # Explicit nil email
          %{"name" => "Dave", "email" => nil}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      # Should only include non-nil email values
      assert result == "[\"alice@example.com\", \"carol@example.com\"]"
    end

    test "filter filter filters by field value" do
      template = "{% assign filtered = filter(users, \"active\", true) %}{{ length(filtered) }}"

      context = %{
        "users" => [
          %{"name" => "Alice", "active" => true},
          %{"name" => "Bob", "active" => false},
          %{"name" => "Carol", "active" => true}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert result == "2"
    end

    test "reject filter rejects by field value" do
      template = "{% assign filtered = reject(users, \"active\", false) %}{{ length(filtered) }}"

      context = %{
        "users" => [
          %{"name" => "Alice", "active" => true},
          %{"name" => "Bob", "active" => false},
          %{"name" => "Carol", "active" => true}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert result == "2"
    end

    test "dump filter formats data for display" do
      template = "{{ data | dump }}"
      context = %{"data" => %{"name" => "Alice"}}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "name")
      assert String.contains?(result, "Alice")
    end
  end

  describe "new string filters" do
    test "strip filter removes whitespace" do
      template = "{{ text | strip }}"
      context = %{"text" => "  hello world  "}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "hello world"
    end

    test "strip filter handles newlines and tabs" do
      template = "{{ text | strip }}"
      context = %{"text" => "\n\t  hello  \t\n"}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "hello"
    end

    test "strip filter works with non-strings" do
      template = "{{ number | strip }}"
      context = %{"number" => 123}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "123"
    end
  end

  describe "filter chaining with new filters" do
    test "complex filter chain" do
      template = """
      {% assign cleaned = compact(items) %}
      {% assign flattened = flatten(cleaned) %}
      {{ sum(flattened) }}
      """

      context = %{"items" => [1, nil, [2, 3], nil, [4]]}

      assert {:ok, result} = Mau.render(template, context)
      assert String.trim(result) == "10"
    end

    test "string processing chain" do
      template = """
      {% assign stripped = strip(text) %}
      {% assign upper = upper_case(stripped) %}
      {{ truncate(upper, 5) }}
      """

      context = %{"text" => "  hello world  "}

      assert {:ok, result} = Mau.render(template, context)
      assert String.trim(result) == "HE..."
    end

    test "data transformation chain" do
      template = """
      {% assign filtered = filter(users, \"active\", true) %}
      {% assign names = map(filtered, \"name\") %}
      {{ join(names, \", \") }}
      """

      context = %{
        "users" => [
          %{"name" => "Alice", "active" => true},
          %{"name" => "Bob", "active" => false},
          %{"name" => "Carol", "active" => true}
        ]
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.trim(result) == "Alice, Carol"
    end
  end
end
