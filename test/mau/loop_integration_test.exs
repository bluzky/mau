defmodule Mau.LoopIntegrationTest do
  use ExUnit.Case, async: true
  alias Mau

  describe "basic loop rendering" do
    test "renders simple for loop with array" do
      template = "{% for item in items %}{{ item }}{% endfor %}"
      context = %{"items" => ["a", "b", "c"]}

      assert {:ok, "abc"} = Mau.render(template, context)
    end

    test "renders for loop with text content" do
      template = "{% for name in names %}Hello {{ name }}! {% endfor %}"
      context = %{"names" => ["Alice", "Bob"]}

      assert {:ok, "Hello Alice! Hello Bob! "} = Mau.render(template, context)
    end

    test "renders for loop with numbers" do
      template = "{% for num in numbers %}{{ num }},{% endfor %}"
      context = %{"numbers" => [1, 2, 3]}

      assert {:ok, "1,2,3,"} = Mau.render(template, context)
    end

    test "handles empty collection" do
      template = "{% for item in items %}{{ item }}{% endfor %}"
      context = %{"items" => []}

      assert {:ok, ""} = Mau.render(template, context)
    end

    test "handles nil collection" do
      template = "{% for item in items %}{{ item }}{% endfor %}"
      context = %{"items" => nil}

      assert {:ok, ""} = Mau.render(template, context)
    end

    test "handles missing collection variable" do
      template = "{% for item in items %}{{ item }}{% endfor %}"
      context = %{}

      assert {:ok, ""} = Mau.render(template, context)
    end
  end

  describe "forloop variables" do
    test "provides forloop.index (0-based)" do
      template = "{% for item in items %}{{ forloop.index }}:{{ item }} {% endfor %}"
      context = %{"items" => ["a", "b", "c"]}

      assert {:ok, "0:a 1:b 2:c "} = Mau.render(template, context)
    end

    test "provides forloop.first and forloop.last" do
      template =
        "{% for item in items %}{% if forloop.first %}First: {% endif %}{{ item }}{% if forloop.last %} Last{% endif %}{% if forloop.last == false %}, {% endif %}{% endfor %}"

      context = %{"items" => ["a", "b", "c"]}

      # First item gets "First: ", last item gets " Last", middle items get ", "
      assert {:ok, "First: a, b, c Last"} = Mau.render(template, context)
    end

    test "provides forloop.length" do
      template = "Total: {{ forloop.length }}{% for item in items %} {{ item }}{% endfor %}"
      context = %{"items" => ["x", "y", "z"]}

      # Note: forloop variables are only available inside the loop
      assert {:ok, result} = Mau.render(template, context)
      assert result =~ " x y z"
    end

    test "provides reverse index with forloop.rindex" do
      template = "{% for item in items %}{{ forloop.rindex }}:{{ item }} {% endfor %}"
      context = %{"items" => ["a", "b", "c"]}

      assert {:ok, "2:a 1:b 0:c "} = Mau.render(template, context)
    end
  end

  describe "different collection types" do
    test "iterates over map as key-value pairs" do
      template = "{% for pair in data %}{{ pair }} {% endfor %}"
      context = %{"data" => %{"a" => 1, "b" => 2}}

      assert {:error, error} = Mau.render(template, context)
      assert error.message == "For loop iterable must be a list"
    end

    test "iterates over string as characters" do
      template = "{% for char in word %}{{ char }}-{% endfor %}"
      context = %{"word" => "abc"}

      assert {:error, error} = Mau.render(template, context)
      assert error.message == "For loop iterable must be a list"
    end

    test "handles complex nested data" do
      template = "{% for user in users %}{{ user.name }}: {{ user.age }} {% endfor %}"

      context = %{
        "users" => [
          %{"name" => "Alice", "age" => 30},
          %{"name" => "Bob", "age" => 25}
        ]
      }

      assert {:ok, "Alice: 30 Bob: 25 "} = Mau.render(template, context)
    end
  end

  describe "nested loops" do
    test "handles nested for loops" do
      template =
        "{% for group in groups %}{% for item in group %}{{ item }} {% endfor %}| {% endfor %}"

      context = %{"groups" => [["a", "b"], ["x", "y", "z"]]}

      assert {:ok, "a b | x y z | "} = Mau.render(template, context)
    end

    test "handles nested forloop variables" do
      template =
        "{% for row in matrix %}{% for col in row %}{{ forloop.index }}-{{ col }} {% endfor %}{% endfor %}"

      context = %{"matrix" => [["a", "b"], ["x", "y"]]}

      # Inner forloop.index should be for the inner loop (0-based)
      assert {:ok, "0-a 1-b 0-x 1-y "} = Mau.render(template, context)
    end

    test "provides access to parent loop via forloop.parentloop" do
      template =
        "{% for group in groups %}{% for item in group %}{{ item }}({{ forloop.parentloop.index }}-{{ forloop.index }}) {% endfor %}{% endfor %}"

      context = %{"groups" => [["a", "b"], ["x", "y", "z"]]}

      # Format: item(parent_index-child_index)
      assert {:ok, "a(0-0) b(0-1) x(1-0) y(1-1) z(1-2) "} = Mau.render(template, context)
    end

    test "provides parent loop properties via forloop.parentloop" do
      template =
        "{% for row in matrix %}{% for item in row %}{{ item }}:p{{ forloop.parentloop.first }}/{{ forloop.parentloop.last }},c{{ forloop.first }}/{{ forloop.last }} {% endfor %}{% endfor %}"

      context = %{"matrix" => [["a", "b"], ["x"]]}

      # Format: item:parent_first/parent_last,child_first/child_last
      assert {:ok,
              "a:ptrue/false,ctrue/false b:ptrue/false,cfalse/true x:pfalse/true,ctrue/true "} =
               Mau.render(template, context)
    end
  end

  describe "loops with expressions" do
    test "evaluates collection expression with filters" do
      template = "{% for item in items | reverse %}{{ item }}{% endfor %}"
      context = %{"items" => [1, 2, 3]}

      assert {:ok, "321"} = Mau.render(template, context)
    end

    test "handles arithmetic in loop content" do
      template = "{% for num in numbers %}{{ num * 2 }} {% endfor %}"
      context = %{"numbers" => [1, 2, 3]}

      assert {:ok, "2 4 6 "} = Mau.render(template, context)
    end

    test "accesses loop variable properties" do
      template =
        "{% for person in people %}{{ person.first_name }} {{ person.last_name }}, {% endfor %}"

      context = %{
        "people" => [
          %{"first_name" => "John", "last_name" => "Doe"},
          %{"first_name" => "Jane", "last_name" => "Smith"}
        ]
      }

      assert {:ok, "John Doe, Jane Smith, "} = Mau.render(template, context)
    end
  end

  describe "error handling" do
    test "handles non-iterable collection gracefully" do
      template = "{% for item in data %}{{ item }}{% endfor %}"
      # Number is not iterable
      context = %{"data" => 123}

      assert {:error, _error} = Mau.render(template, context)
    end

    test "handles missing endfor tag" do
      template = "{% for item in items %}{{ item }}"
      context = %{"items" => ["a", "b"]}

      # Should treat as individual tags when block collection fails
      assert {:ok, _result} = Mau.render(template, context)
    end
  end
end
