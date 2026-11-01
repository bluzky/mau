defmodule Mau.ResourceLimitsTest do
  use ExUnit.Case, async: true

  alias Mau.Error

  @nested "{% for a in l %}{% for b in l %}{% for c in l %}x{% endfor %}{% endfor %}{% endfor %}"

  defp doubling(times, tail) do
    "{% assign s = 'xx' %}" <> String.duplicate("{% assign s = s + s %}", times) <> tail
  end

  describe "max_total_iterations" do
    test "counts nested loops together" do
      context = %{"l" => Enum.to_list(1..10)}

      assert {:error, %Error{type: :limit} = error} =
               Mau.render(@nested, context, max_total_iterations: 500)

      assert error.message =~ "exceeds maximum 500"
    end

    test "allows renders within the limit" do
      context = %{"l" => [1, 2]}

      # 2 + 4 + 8 iterations
      assert {:ok, "xxxxxxxx"} = Mau.render(@nested, context, max_total_iterations: 14)
      assert {:error, %Error{type: :limit}} = Mau.render(@nested, context, max_total_iterations: 13)
    end

    test "defaults to 1,000,000 across the whole render" do
      context = %{"l" => Enum.to_list(1..101)}

      assert {:error, %Error{type: :limit} = error} = Mau.render(@nested, context)
      assert error.message =~ "exceeds maximum 1000000"
    end

    test "starts fresh for each render" do
      context = %{"l" => [1, 2, 3]}
      template = "{% for a in l %}x{% endfor %}"

      for _ <- 1..3 do
        assert {:ok, "xxx"} = Mau.render(template, context, max_total_iterations: 3)
      end
    end

    test "counts a compiled template" do
      {:ok, ast} = Mau.compile(@nested)

      assert {:error, %Error{type: :limit}} =
               Mau.render(ast, %{"l" => [1, 2]}, max_total_iterations: 5)
    end
  end

  describe "max_loop_iterations" do
    test "still applies to each loop" do
      assert {:error, %Error{type: :limit} = error} =
               Mau.render("{% for a in l %}x{% endfor %}", %{"l" => [1, 2, 3]},
                 max_loop_iterations: 2
               )

      assert error.message =~ "Loop iteration count 3 exceeds maximum 2"
    end
  end

  describe "map directives" do
    @items %{"items" => Enum.to_list(1..50)}

    @directives [
      %{r: %{"#map" => ["{{ items }}", "{{ $loop.item }}"]}},
      %{r: %{"#flat_map" => ["{{ items }}", ["{{ $loop.item }}"]]}},
      %{r: %{"#filter" => ["{{ items }}", "{{ $loop.item }}"]}},
      %{r: %{"#pipe" => ["{{ items }}", [%{"#map" => "{{ $loop.item }}"}]]}}
    ]

    test "respect max_loop_iterations" do
      for input <- @directives do
        assert {:error, %Error{type: :limit}} =
                 Mau.render_map(input, @items, max_loop_iterations: 5)
      end
    end

    test "respect max_total_iterations" do
      for input <- @directives do
        assert {:error, %Error{type: :limit}} =
                 Mau.render_map(input, @items, max_total_iterations: 5)

        assert {:ok, _} = Mau.render_map(input, @items, max_total_iterations: 50)
      end
    end

    test "share one budget across nested directives" do
      input = %{
        r: %{"#map" => ["{{ l }}", %{"#map" => ["{{ l }}", "{{ $loop.item }}"]}]}
      }

      assert {:ok, _} = Mau.render_map(input, %{"l" => [1, 2, 3]}, max_total_iterations: 12)

      assert {:error, %Error{type: :limit}} =
               Mau.render_map(input, %{"l" => [1, 2, 3]}, max_total_iterations: 11)
    end

    test "share one budget across fields" do
      loop = "{% for a in l %}x{% endfor %}"
      input = %{a: loop, b: loop, c: loop}

      assert {:ok, _} = Mau.render_map(input, %{"l" => [1, 2]}, max_total_iterations: 6)

      assert {:error, %Error{type: :limit}} =
               Mau.render_map(input, %{"l" => [1, 2]}, max_total_iterations: 5)
    end
  end

  describe "max_output_size" do
    test "limits total output including text" do
      template = "{% for a in l %}xxxx{{ a }}{% endfor %}"

      assert {:ok, "xxxx1xxxx2"} = Mau.render(template, %{"l" => [1, 2]}, max_output_size: 10)

      assert {:error, %Error{type: :limit} = error} =
               Mau.render(template, %{"l" => [1, 2]}, max_output_size: 9)

      assert error.message =~ "exceeds maximum 9 bytes"
    end

    test "defaults to 10,000,000 bytes" do
      assert {:error, %Error{type: :limit} = error} = Mau.render(doubling(24, "{{ s }}"), %{})

      assert error.message =~ "exceeds maximum 10000000 bytes"
    end

    test "stops strings growing in memory without being output" do
      assert {:error, %Error{type: :limit}} = Mau.render(doubling(60, ""), %{}, max_output_size: 1000)
    end

    test "limits strings built by filters" do
      context = %{"l" => List.duplicate("xxxx", 10)}

      assert {:error, %Error{type: :limit}} =
               Mau.render("{% assign s = l | join('') %}", context, max_output_size: 10)
    end

    test "is shared across render_map fields" do
      input = %{a: "{{ s }}", b: "{{ s }}"}

      assert {:ok, _} = Mau.render_map(input, %{"s" => "xxxx"}, max_output_size: 8)

      assert {:error, %Error{type: :limit}} =
               Mau.render_map(input, %{"s" => "xxxx"}, max_output_size: 7)
    end
  end

  describe "array literals" do
    defp nesting(times, tail) do
      "{% assign a = [1] %}" <> String.duplicate("{% assign a = [a, a] %}", times) <> tail
    end

    test "can't grow past max_total_iterations by nesting" do
      assert {:error, %Error{type: :limit} = error} =
               Mau.render(nesting(10, ""), %{}, max_total_iterations: 500)

      assert error.message =~ "Collection size exceeds maximum 500"
    end

    test "stop exponential growth quickly by default" do
      {time, result} = :timer.tc(fn -> Mau.render(nesting(60, "{{ a | flatten }}"), %{}) end)

      assert {:error, %Error{type: :limit}} = result
      assert time < 5_000_000
    end

    test "allow normal arrays" do
      assert {:ok, "3"} = Mau.render("{{ [1, 2, 3] | length }}", %{})
      assert {:ok, "2"} = Mau.render("{{ [l, l] | length }}", %{"l" => [1]})
    end
  end

  describe "limit errors in render_map" do
    test "fail the whole map without strict mode" do
      input = %{bad: "{% for a in l %}x{% endfor %}", good: "ok"}

      assert {:error, %Error{type: :limit}} =
               Mau.render_map(input, %{"l" => [1, 2]}, max_loop_iterations: 1)
    end
  end
end
