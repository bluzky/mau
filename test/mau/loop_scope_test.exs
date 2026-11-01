defmodule Mau.LoopScopeTest do
  use ExUnit.Case, async: true

  describe "after a loop" do
    test "restores an outer variable with the loop variable's name" do
      template = "{% for x in l %}{{ x }}{% endfor %}[{{ x }}]"

      assert {:ok, "1[keep]"} = Mau.render(template, %{"x" => "keep", "l" => [1]})
      assert {:ok, "1[keep]"} = Mau.render(template, %{"x" => "keep", "l" => [1]}, strict_mode: true)
    end

    test "restores it when the list is empty or nil" do
      template = "{% for x in l %}{% endfor %}[{{ x }}]"

      assert {:ok, "[keep]"} = Mau.render(template, %{"x" => "keep", "l" => []})
      assert {:ok, "[keep]"} = Mau.render(template, %{"x" => "keep", "l" => nil})
    end

    test "restores an outer nil and keeps it defined" do
      template = "{% for x in l %}{% endfor %}[{{ x }}]"

      assert {:ok, "[]"} = Mau.render(template, %{"x" => nil, "l" => [1]}, strict_mode: true)
    end

    test "restores a forloop key from the context" do
      template = "{% for x in l %}{% endfor %}[{{ forloop }}]"

      assert {:ok, "[keep]"} = Mau.render(template, %{"forloop" => "keep", "l" => [1]})
    end

    test "removes names the loop created" do
      assert {:ok, "[]"} = Mau.render("{% for x in l %}{% endfor %}[{{ x }}]", %{"l" => [1]})

      assert {:error, %Mau.Error{type: :undefined_variable}} =
               Mau.render("{% for x in l %}{% endfor %}{{ x }}", %{"l" => [1]}, strict_mode: true)

      assert {:error, %Mau.Error{type: :undefined_variable}} =
               Mau.render("{% for x in l %}{% endfor %}{{ forloop }}", %{"l" => [1]}, strict_mode: true)
    end

    test "leaves an atom key in place" do
      assert {:ok, "[1]"} = Mau.render("{% for x in l %}{% endfor %}[{{ x }}]", %{x: 1, l: [2]})
    end

    test "discards an assign to the loop variable" do
      template = "{% for x in l %}{% assign x = 9 %}{% endfor %}[{{ x }}]"

      assert {:ok, "[keep]"} = Mau.render(template, %{"x" => "keep", "l" => [1]})
    end
  end

  describe "nested loops" do
    @context %{"o" => [1, 2], "i" => [9]}

    test "keeps the outer forloop after an inner loop" do
      template = "{% for a in o %}{% for b in i %}{% endfor %}{{ forloop.index }}|{% endfor %}"

      assert {:ok, "0|1|"} = Mau.render(template, @context)
      assert {:ok, "0|1|"} = Mau.render(template, @context, strict_mode: true)
    end

    test "keeps all outer forloop fields correct across iterations" do
      template =
        "{% for a in o %}{% for b in i %}{% endfor %}{{ forloop.first }}{{ forloop.last }}{{ forloop.length }}|{% endfor %}"

      assert {:ok, "truefalse2|falsetrue2|"} = Mau.render(template, @context)
    end

    test "keeps the outer variable when loops share a name" do
      template = "{% for x in o %}{% for x in i %}{{ x }}{% endfor %}[{{ x }}]{% endfor %}"

      assert {:ok, "9[1]9[2]"} = Mau.render(template, @context)
    end

    test "keeps parentloop working" do
      template = "{% for a in o %}{% for b in i %}{{ forloop.parentloop.index }}{% endfor %}|{% endfor %}"

      assert {:ok, "0|1|"} = Mau.render(template, @context)
    end

    test "unwinds three levels" do
      template =
        "{% for a in o %}{% for b in i %}{% for c in i %}{% endfor %}{{ forloop.parentloop.index }}{% endfor %}{{ forloop.index }}|{% endfor %}"

      assert {:ok, "00|11|"} = Mau.render(template, @context)
    end
  end

  describe "assign inside a loop" do
    test "stays visible after the loop" do
      assert {:ok, "[1]"} = Mau.render("{% for x in l %}{% assign y = x %}{% endfor %}[{{ y }}]", %{"l" => [1]})
    end

    test "updates an outer variable" do
      template = "{% assign t = 0 %}{% for i in l %}{% assign t = t + i %}{% endfor %}{{ t }}"

      assert {:ok, "6"} = Mau.render(template, %{"l" => [1, 2, 3]})
    end

    test "stays visible after an inner loop" do
      template = "{% for a in o %}{% for b in i %}{% assign t = b %}{% endfor %}[{{ t }}{{ a }}]{% endfor %}"

      assert {:ok, "[91][92]"} = Mau.render(template, %{"o" => [1, 2], "i" => [9]})
    end
  end
end
