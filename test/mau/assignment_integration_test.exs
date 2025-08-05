defmodule Mau.AssignmentIntegrationTest do
  use ExUnit.Case, async: true
  alias Mau

  describe "assignment tag integration tests" do
    test "renders simple assignment with expression" do
      template = "{% assign name = \"John\" %} Hello {{ name }}!"
      context = %{}

      assert {:ok, " Hello John!"} = Mau.render(template, context)
    end

    test "renders assignment with arithmetic" do
      template = "{% assign total = 10 + 5 %} Total: {{ total }}"
      context = %{}

      assert {:ok, " Total: 15"} = Mau.render(template, context)
    end

    test "renders assignment with existing variable" do
      template = "{% assign greeting = \"Hello \" + name %} {{ greeting }}"
      context = %{"name" => "World"}

      assert {:ok, " Hello World"} = Mau.render(template, context)
    end

    test "renders assignment with filter" do
      template = "{% assign upper_name = name | upper_case %} {{ upper_name }}"
      context = %{"name" => "john"}

      assert {:ok, " JOHN"} = Mau.render(template, context)
    end

    test "renders multiple assignments" do
      template = "{% assign first = \"John\" %}{% assign last = \"Doe\" %} {{ first }} {{ last }}"
      context = %{}

      assert {:ok, " John Doe"} = Mau.render(template, context)
    end

    test "assignment overwrites existing variable" do
      template = "Before: {{ name }} {% assign name = \"Jane\" %} After: {{ name }}"
      context = %{"name" => "John"}

      assert {:ok, "Before: John  After: Jane"} = Mau.render(template, context)
    end

    test "assignment with complex expression" do
      template = "{% assign result = (price + tax) * quantity %} Total: {{ result }}"
      context = %{"price" => 10, "tax" => 2, "quantity" => 3}

      assert {:ok, " Total: 36"} = Mau.render(template, context)
    end

    test "assignment with nested property access" do
      template = "{% assign email = user.profile.contact.email %} Email: {{ email }}"
      context = %{"user" => %{"profile" => %{"contact" => %{"email" => "john@example.com"}}}}

      assert {:ok, " Email: john@example.com"} = Mau.render(template, context)
    end

    test "assignment with array access" do
      template = "{% assign first_item = items[0] %} First: {{ first_item }}"
      context = %{"items" => ["apple", "banana", "cherry"]}

      assert {:ok, " First: apple"} = Mau.render(template, context)
    end

    test "assignment with workflow variable" do
      template = "{% assign data = $input.payload %} Data: {{ data }}"
      context = %{"$input" => %{"payload" => "test_data"}}

      assert {:ok, " Data: test_data"} = Mau.render(template, context)
    end

    test "chained assignments using previous assignment" do
      template =
        "{% assign name = \"John\" %}{% assign greeting = \"Hello \" + name %}{{ greeting }}"

      context = %{}

      assert {:ok, "Hello John"} = Mau.render(template, context)
    end

    test "assignment with comparison and logical expressions" do
      template = "{% assign is_adult = age >= 18 and age <= 65 %} Adult: {{ is_adult }}"
      context = %{"age" => 25}

      assert {:ok, " Adult: true"} = Mau.render(template, context)
    end

    test "assignment with function call" do
      template = "{% assign rounded = round(price, 2) %} Price: {{ rounded }}"
      context = %{"price" => 19.999}

      assert {:ok, " Price: 20.0"} = Mau.render(template, context)
    end

    test "assignment with chained filters" do
      template = "{% assign processed = text | upper_case | reverse %} Result: {{ processed }}"
      context = %{"text" => "hello"}

      assert {:ok, " Result: OLLEH"} = Mau.render(template, context)
    end

    test "multiple assignments with mixed content" do
      template = """
        Welcome!
        {% assign user_name = user.name | capitalize %}
        {% assign user_age = user.age %}
        {% assign greeting = "Hello " + user_name %}
        
        {{ greeting }}! You are {{ user_age }} years old.
      """

      context = %{"user" => %{"name" => "john", "age" => 30}}

      result = Mau.render(template, context)
      assert {:ok, rendered} = result
      assert String.contains?(rendered, "Hello John!")
      assert String.contains?(rendered, "You are 30 years old")
    end
  end

  describe "assignment error handling" do
    test "returns error for assignment with division by zero" do
      template = "{% assign result = 10 / 0 %} Result: {{ result }}"
      context = %{}

      assert {:error, error} = Mau.render(template, context)
      assert error.type == :runtime
      assert String.contains?(error.message, "Division by zero")
    end

    test "returns error for assignment with unknown filter" do
      template = "{% assign result = name | unknown_filter %} Result: {{ result }}"
      context = %{"name" => "test"}

      assert {:error, error} = Mau.render(template, context)
      assert error.type == :runtime
      assert String.contains?(error.message, "Unknown filter")
    end

    test "handles assignment with undefined variable gracefully" do
      template = "{% assign result = undefined_var %} Result: {{ result }}"
      context = %{}

      # Should not error - undefined variables become nil, then empty string
      assert {:ok, " Result: "} = Mau.render(template, context)
    end
  end
end
