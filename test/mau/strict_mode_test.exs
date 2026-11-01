defmodule Mau.StrictModeTest do
  use ExUnit.Case, async: true

  alias Mau.Error

  @invalid_templates [
    "{{ a + }}",
    "{% bogus %}",
    "ok {{ 1 }} {{ a + }}",
    "{% if a %}x",
    "{% for x in l %}x",
    "{% endif %}",
    "{% else %}",
    "{% elsif a %}",
    "{% endfor %}",
    "{% if a %}x{% endfor %}",
    "{% for x in l %}{% if a %}{% endfor %}",
    "{% if a %}{% for x in l %}{% endif %}{% endfor %}",
    ~S({{ "\uD800" }}),
    "{{ 1e999 }}"
  ]

  describe "invalid templates" do
    test "render as the template string by default" do
      for template <- @invalid_templates do
        assert Mau.render(template, %{"a" => false, "l" => [1]}) == {:ok, template}
      end
    end

    test "return a syntax error in strict mode" do
      for template <- @invalid_templates do
        assert {:error, %Error{type: :syntax}} = Mau.render(template, %{}, strict_mode: true)
        assert {:error, %Error{type: :syntax}} = Mau.compile(template, strict_mode: true)
      end
    end

    test "compile to a text node by default" do
      assert Mau.compile("{{ a + }}") == {:ok, [{:text, ["{{ a + }}"], []}]}
    end

    test "strict errors report the location of bad syntax" do
      template = "line one\nabc {{ a + }}"

      assert {:error, %Error{line: 2, column: 5}} = Mau.compile(template, strict_mode: true)
    end

    test "size limit is enforced in both modes" do
      assert {:error, _} = Mau.render("{{ a + }}", %{}, max_template_size: 2)
      assert {:error, _} = Mau.render("{{ a + }}", %{}, max_template_size: 2, strict_mode: true)
    end
  end

  describe "valid templates" do
    test "behave the same in both modes" do
      template = "{% if a %}{{ a }}{% else %}none{% endif %}"

      assert Mau.render(template, %{"a" => 1}, strict_mode: true) == {:ok, "1"}
      assert {:ok, _ast, []} = Mau.compile(template, strict_mode: true)
    end
  end

  describe "render failures" do
    @failures [
      {"{{ 1e308 * 10 }}", %{}},
      {"{{ 'x' + m }}", %{"m" => %{"a" => 1}}},
      {"{{ m + 'x' }}", %{"m" => %{"a" => 1}}},
      {"{{ n + m }}", %{"n" => nil, "m" => %{"a" => 1}}},
      {"{{ 1 / 0 }}", %{}}
    ]

    test "return an error instead of raising in both modes" do
      for {template, context} <- @failures, opts <- [[], [strict_mode: true]] do
        assert {:error, %Error{type: :runtime}} = Mau.render(template, context, opts)
      end
    end

    test "return an error when rendering a compiled template" do
      {:ok, ast} = Mau.compile("{{ 1e308 * 10 }}")

      assert {:error, %Error{type: :runtime}} = Mau.render(ast, %{})
    end

    test "string concatenation still accepts scalars" do
      context = %{"n" => 1, "b" => true}

      assert Mau.render("{{ 'x' + n }}", context) == {:ok, "x1"}
      assert Mau.render("{{ 'x' + b }}", context) == {:ok, "xtrue"}
      assert Mau.render("{{ 'x' + missing }}", context) == {:ok, "x"}
    end
  end

  describe "undefined variables" do
    @context %{
      "user" => %{"name" => "Al", "nick" => nil},
      "n" => nil,
      "l" => [1],
      "s" => "text"
    }

    defp strict(template, context \\ @context) do
      Mau.render(template, context, strict_mode: true)
    end

    test "are errors when used as values in strict mode" do
      for {template, name} <- [
            {"{{ nmae }}", "nmae"},
            {"{{ user.missing }}", "user.missing"},
            {"{{ missing.deep.path }}", "missing"},
            {"{{ user.name.first }}", "user.name.first"},
            {"{{ l[missing] }}", "missing"},
            {"{{ missing + 1 }}", "missing"},
            {"{{ 'x' + missing }}", "missing"},
            {"{{ missing > 1 }}", "missing"},
            {"{{ missing == 1 }}", "missing"},
            {"{{ missing | upper_case }}", "missing"},
            {"{{ missing | length }}", "missing"},
            {"{{ missing | upper_case | default('d') }}", "missing"},
            {"{% if missing == 1 %}y{% endif %}", "missing"},
            {"{% for x in missing %}a{% endfor %}", "missing"},
            {"{% assign x = missing %}", "missing"}
          ] do
        message = "Undefined variable: #{name}"

        assert {:error, %Error{type: :undefined_variable, message: ^message}} = strict(template)
      end
    end

    test "keep rendering as nil by default" do
      assert Mau.render("{{ nmae }}", @context) == {:ok, ""}
      assert Mau.render("{{ user.missing }}", @context) == {:ok, ""}
      assert Mau.render("{{ missing.deep.path }}", @context) == {:ok, ""}
      assert Mau.render("{{ missing + 1 }}", @context) == {:ok, "1"}
    end

    test "existing nil values are not errors" do
      assert strict("{{ n }}") == {:ok, ""}
      assert strict("{{ user.nick }}") == {:ok, ""}
      assert strict("{{ n.anything }}") == {:ok, ""}
      assert strict("{{ user.nick.first }}") == {:ok, ""}
    end

    test "out of range indexes are not errors" do
      assert strict("{{ l[5] }}") == {:ok, ""}
      assert strict("{{ l[5].name }}") == {:ok, ""}
    end

    test "atom keys count as defined when accessing a path" do
      assert strict("{{ user.name }}", %{user: %{name: "Al"}}) == {:ok, "Al"}
    end

    test "are allowed in conditions" do
      assert strict("{% if missing %}y{% else %}n{% endif %}") == {:ok, "n"}
      assert strict("{% if user.missing %}y{% else %}n{% endif %}") == {:ok, "n"}
      assert strict("{% if n %}y{% elsif missing %}e{% else %}n{% endif %}") == {:ok, "n"}
      assert strict("{% if missing and s %}y{% else %}n{% endif %}") == {:ok, "n"}
      assert strict("{% if not missing %}y{% endif %}") == {:ok, "y"}
      assert strict("{{ missing or s }}") == {:ok, "text"}
      assert strict("{{ missing and s }}") == {:ok, "false"}
      assert strict("{{ missing || s }}") == {:ok, "text"}
      assert strict("{{ missing && s }}") == {:ok, ""}
    end

    test "are allowed as the input to default" do
      assert strict("{{ missing | default('d') }}") == {:ok, "d"}
      assert strict("{{ user.missing | default('d') }}") == {:ok, "d"}
      assert strict("{{ default(missing, 'd') }}") == {:ok, "d"}
      assert {:error, %Error{type: :undefined_variable}} = strict("{{ s | default(missing) }}")
    end

    test "are errors inside loops and branches that run" do
      assert {:error, %Error{type: :undefined_variable}} =
               strict("{% for x in l %}{{ x.missing }}{% endfor %}")

      assert strict("{% if n %}{{ missing }}{% endif %}") == {:ok, ""}
    end

    test "loop and assigned variables are defined" do
      assert strict("{% for x in l %}{{ x }}{{ forloop.index }}{% endfor %}") == {:ok, "10"}
      assert strict("{% assign a = 1 %}{{ a }}") == {:ok, "1"}
    end

    test "are errors with preserve_types and compiled templates" do
      assert {:error, %Error{type: :undefined_variable}} =
               Mau.render("{{ nmae }}", @context, strict_mode: true, preserve_types: true)

      {:ok, ast} = Mau.compile("{{ nmae }}")

      assert {:error, %Error{type: :undefined_variable}} =
               Mau.render(ast, @context, strict_mode: true)
    end

    test "fail the whole map in render_map" do
      assert {:error, %Error{type: :undefined_variable}} =
               Mau.render_map(%{a: "{{ nmae }}", b: "{{ s }}"}, @context, strict_mode: true)

      assert Mau.render_map(%{a: "{{ nmae }}"}, @context) == {:ok, %{a: nil}}
    end
  end

  describe "render_map" do
    test "keeps the template string for a failed field by default" do
      input = %{bad: "{{ 1 / 0 }}", good: "{{ 1 + 1 }}"}

      assert Mau.render_map(input, %{}) == {:ok, %{bad: "{{ 1 / 0 }}", good: 2}}
    end

    test "fails the whole map in strict mode" do
      input = %{bad: "{{ 1 / 0 }}", good: "{{ 1 + 1 }}"}

      assert {:error, %Error{type: :runtime, message: "Division by zero"}} =
               Mau.render_map(input, %{}, strict_mode: true)
    end

    test "fails on syntax errors nested in directives in strict mode" do
      input = %{result: %{"#map" => ["{{ l }}", "{{ a + }}"]}}

      assert {:error, %Error{type: :syntax}} =
               Mau.render_map(input, %{"l" => [1]}, strict_mode: true)
    end
  end
end
