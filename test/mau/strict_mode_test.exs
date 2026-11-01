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
      {"{{ n + m }}", %{"m" => %{"a" => 1}}},
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
