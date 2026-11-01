defmodule Mau.FunctionArgumentTest do
  use ExUnit.Case, async: true

  describe "expressions as arguments" do
    test "accepts arithmetic" do
      assert {:ok, "XY"} = Mau.render(~s/{{ upper_case(a + "y") }}/, %{"a" => "x"})
      assert {:ok, "2.4"} = Mau.render("{{ round(price * 1.2, 1) }}", %{"price" => 2})
    end

    test "accepts nested calls" do
      assert {:ok, "X"} = Mau.render("{{ upper_case(lower_case(a)) }}", %{"a" => "X"})
      assert {:ok, "X"} = Mau.render("{{ upper_case(strip(lower_case(a))) }}", %{"a" => " X "})
    end

    test "accepts comparison and logical expressions" do
      assert {:ok, "TRUE"} = Mau.render("{{ upper_case(1 < 2) }}", %{})
      assert {:ok, "GUEST"} = Mau.render(~s/{{ upper_case(a or "guest") }}/, %{})
      assert {:ok, "FALSE"} = Mau.render("{{ upper_case(not true) }}", %{})
    end

    test "accepts pipes and parentheses" do
      assert {:ok, "X"} = Mau.render("{{ upper_case(a | strip) }}", %{"a" => " x "})
      assert {:ok, "9"} = Mau.render("{{ abs((1 + 2) * 3) }}", %{})
    end

    test "accepts an expression in any position" do
      assert {:ok, "2"} = Mau.render("{{ default(missing, 1 + 1) }}", %{})
      assert {:ok, "a-b"} = Mau.render(~s/{{ join(l, "-" + "") }}/, %{"l" => ["a", "b"]})
    end

    test "accepts expressions in filter arguments" do
      assert {:ok, "2"} = Mau.render("{{ missing | default(1 + 1) }}", %{})
      assert {:ok, "none"} = Mau.render(~s/{{ missing | default(b or "none") }}/, %{})
      assert {:ok, "X"} = Mau.render("{{ missing | default(upper_case(a)) }}", %{"a" => "x"})
    end

    test "works in tags and map templates" do
      assert {:ok, "Y"} =
               Mau.render("{% if length(l | compact) > 0 %}Y{% endif %}", %{"l" => [1, nil]})

      assert {:ok, "xx"} = Mau.render("{% assign b = lower_case(a + a) %}{{ b }}", %{"a" => "X"})
      assert {:ok, %{"r" => "XY"}} = Mau.render_map(%{"r" => ~s/{{ upper_case(a + "y") }}/}, %{"a" => "x"})
    end

    test "keeps other template content working" do
      assert {:ok, "Hi x XY"} = Mau.render(~s/Hi {{ a }} {{ upper_case(a + "y") }}/, %{"a" => "x"})
    end
  end

  describe "simple arguments" do
    test "keeps literals, variables and arrays working" do
      assert {:ok, "X"} = Mau.render(~s/{{ upper_case("x") }}/, %{})
      assert {:ok, "X"} = Mau.render("{{ upper_case(a.b) }}", %{"a" => %{"b" => "x"}})
      assert {:ok, "1,2"} = Mau.render(~s/{{ join([1, 2], ",") }}/, %{})
    end

    test "keeps commas in strings and arrays inside one argument" do
      assert {:ok, "a, b"} = Mau.render(~s/{{ strip("a, b") }}/, %{})
      assert {:ok, "2"} = Mau.render("{{ length([1, 2]) }}", %{})
    end

    test "keeps whitespace around arguments optional" do
      assert {:ok, "a-b"} = Mau.render(~s/{{ join( l , "-" ) }}/, %{"l" => ["a", "b"]})
      assert {:ok, "a-b"} = Mau.render(~s/{{ join(l,"-") }}/, %{"l" => ["a", "b"]})
    end
  end

  describe "invalid arguments" do
    test "are still syntax errors" do
      for template <- ["{{ upper_case(a +) }}", "{{ upper_case(a,) }}", "{{ upper_case(,a) }}", "{{ upper_case(a b) }}", "{{ upper_case(a }}"] do
        assert {:error, %Mau.Error{type: :syntax}} = Mau.render(template, %{}, strict_mode: true)
        assert {:ok, ^template} = Mau.render(template, %{})
      end
    end
  end

  describe "strict mode" do
    test "exempts only a direct operand of default" do
      assert {:ok, "0"} = Mau.render("{{ default(a, 0) }}", %{}, strict_mode: true)

      assert {:error, %Mau.Error{type: :undefined_variable}} =
               Mau.render("{{ default(a + 1, 0) }}", %{}, strict_mode: true)
    end

    test "reports undefined variables inside nested calls" do
      assert {:error, %Mau.Error{type: :undefined_variable}} =
               Mau.render("{{ upper_case(lower_case(a)) }}", %{}, strict_mode: true)
    end
  end

  describe "deep nesting" do
    test "parses nested calls in linear time" do
      nested = fn depth -> String.duplicate("strip(", depth) <> "a" <> String.duplicate(")", depth) end

      {micros, result} = :timer.tc(fn -> Mau.render("{{ #{nested.(300)} }}", %{"a" => "x"}) end)

      assert {:ok, "x"} = result
      assert micros < 2_000_000
    end

    test "fails quickly on unclosed nested calls" do
      template = "{{ " <> String.duplicate("strip(", 300) <> "a }}"

      {micros, result} = :timer.tc(fn -> Mau.render(template, %{"a" => "x"}, strict_mode: true) end)

      assert {:error, %Mau.Error{type: :syntax}} = result
      assert micros < 2_000_000
    end
  end
end
