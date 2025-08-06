defmodule ParserAnalysisSimple do
  @moduledoc """
  Deep analysis of parser performance bottlenecks using actual parser methods.
  """

  alias Mau.Parser

  def run do
    IO.puts("=== Deep Parser Performance Analysis ===\n")
    
    analyze_template_complexity()
    analyze_expression_parsing()
    analyze_ast_construction_overhead()
    analyze_optimization_potential()
  end

  def analyze_template_complexity do
    IO.puts("=== 1. Template Complexity vs Parse Time ===")
    
    test_cases = [
      {"Plain Text", "Hello World"},
      {"Single Variable", "{{ name }}"},
      {"Property Access", "{{ user.name }}"},
      {"Deep Property", "{{ a.b.c.d.e }}"},
      {"Multiple Variables", "{{ a }} {{ b }} {{ c }}"},
      {"Array Access", "{{ items[0] }}"},
      {"Filter", "{{ name | upcase }}"},
      {"Conditional", "{% if active %}Yes{% endif %}"}
    ]

    for {name, template} <- test_cases do
      # Measure parse time multiple times for accuracy
      times = for _i <- 1..100 do
        {time, _result} = :timer.tc(fn -> Parser.parse(template) end)
        time
      end
      
      avg_time = Enum.sum(times) / length(times)
      
      # Analyze the result
      case Parser.parse(template) do
        {:ok, ast} ->
          node_count = count_nodes(ast)
          ast_size = :erlang.external_size(ast)
          
          IO.puts("#{name}:")
          IO.puts("  Template: #{template}")
          IO.puts("  Avg parse time: #{Float.round(avg_time, 1)}μs")
          IO.puts("  AST nodes: #{node_count}")
          IO.puts("  AST size: #{ast_size} bytes")
          IO.puts("  Time per node: #{Float.round(avg_time / node_count, 2)}μs")
          IO.puts("")
        {:error, error} ->
          IO.puts("#{name}: Parse failed - #{inspect(error)}")
      end
    end
  end

  def analyze_expression_parsing do
    IO.puts("=== 2. Expression Type Parsing Cost ===")
    
    # Test specific expression parsing functions
    expressions = [
      {"String Literal", ~s("hello")},
      {"Number Literal", "42"},
      {"Boolean Literal", "true"},
      {"Variable", "name"},
      {"Property", "user.name"},
      {"Deep Property", "a.b.c.d.e.f"}
    ]
    
    for {name, expr} <- expressions do
      template = "{{ #{expr} }}"
      
      times = for _i <- 1..1000 do
        {time, _result} = :timer.tc(fn -> Parser.parse(template) end)
        time
      end
      
      avg_time = Enum.sum(times) / length(times)
      IO.puts("#{name}: #{Float.round(avg_time, 2)}μs avg (#{template})")
    end
    
    IO.puts("")
  end

  def analyze_ast_construction_overhead do
    IO.puts("=== 3. AST Construction Overhead Analysis ===")
    
    simple_template = "{{ name }}"
    
    # Parse and analyze the AST structure
    {:ok, ast} = Parser.parse(simple_template)
    
    IO.puts("Template: #{simple_template}")
    IO.puts("AST structure:")
    IO.inspect(ast, limit: :infinity)
    
    IO.puts("\nAST analysis:")
    IO.puts("  Total nodes: #{count_nodes(ast)}")
    IO.puts("  Memory size: #{:erlang.external_size(ast)} bytes")
    IO.puts("  Depth: #{ast_depth(ast)}")
    
    # Compare with a manually constructed equivalent
    manual_ast = [
      {:expression, [{:variable, ["name"], []}], []}
    ]
    
    IO.puts("\nManual equivalent AST:")
    IO.inspect(manual_ast, limit: :infinity)
    IO.puts("  Memory size: #{:erlang.external_size(manual_ast)} bytes")
    IO.puts("  Match: #{ast == manual_ast}")
    
    IO.puts("")
  end

  def analyze_optimization_potential do
    IO.puts("=== 4. Parser Optimization Potential ===")
    
    simple_var = "{{ name }}"
    
    # Current parser performance
    {current_time, {:ok, current_ast}} = :timer.tc(fn -> 
      Parser.parse(simple_var)
    end)
    
    IO.puts("Current parser: #{current_time}μs")
    IO.puts("Result: #{inspect(current_ast)}")
    
    # Test regex-based fast path for simple variables
    {regex_time, regex_result} = :timer.tc(fn ->
      case Regex.run(~r/^\s*\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\}\}\s*$/, simple_var) do
        [_, var_name] ->
          {:ok, [{:expression, [{:variable, [var_name], []}], []}]}
        nil ->
          {:error, "not simple variable"}
      end
    end)
    
    case regex_result do
      {:ok, regex_ast} ->
        speedup = current_time / regex_time
        IO.puts("Regex approach: #{regex_time}μs (#{Float.round(speedup, 1)}x faster)")
        IO.puts("Results match: #{regex_ast == current_ast}")
      {:error, _} ->
        IO.puts("Regex approach failed")
    end
    
    # Test pattern matching approach
    {pattern_time, pattern_result} = :timer.tc(fn ->
      parse_simple_pattern(simple_var)
    end)
    
    case pattern_result do
      {:ok, pattern_ast} ->
        speedup = current_time / pattern_time
        IO.puts("Pattern matching: #{pattern_time}μs (#{Float.round(speedup, 1)}x faster)")
        IO.puts("Results match: #{pattern_ast == current_ast}")
      {:error, _} ->
        IO.puts("Pattern matching failed")
    end
    
    IO.puts("")
    
    # Analyze what makes parsing slow
    analyze_parsing_bottlenecks()
  end

  def analyze_parsing_bottlenecks do
    IO.puts("=== 5. Parsing Bottleneck Analysis ===")
    
    # Test how parse time scales with template complexity
    templates = [
      "{{a}}",
      "{{a}} {{b}}",
      "{{a}} {{b}} {{c}}",
      "{{a}} {{b}} {{c}} {{d}}",
      "{{a}} {{b}} {{c}} {{d}} {{e}}"
    ]
    
    IO.puts("Parse time scaling analysis:")
    
    for template <- templates do
      var_count = Regex.scan(~r/\{\{/, template) |> length()
      
      times = for _i <- 1..100 do
        {time, _} = :timer.tc(fn -> Parser.parse(template) end)
        time
      end
      
      avg_time = Enum.sum(times) / length(times)
      time_per_var = avg_time / var_count
      
      IO.puts("  #{var_count} vars: #{Float.round(avg_time, 1)}μs total, #{Float.round(time_per_var, 1)}μs per var")
    end
    
    IO.puts("\nIdentified bottlenecks:")
    IO.puts("1. NimbleParsec combinator overhead")
    IO.puts("2. AST node construction (tuples + options)")  
    IO.puts("3. Multiple reduce function calls")
    IO.puts("4. Choice combinator evaluation")
    IO.puts("5. Memory allocation for intermediate parsing results")
    
    IO.puts("")
  end

  # Helper functions
  
  defp count_nodes(nodes) when is_list(nodes) do
    Enum.reduce(nodes, 0, fn node, acc -> acc + count_nodes(node) end)
  end
  
  defp count_nodes({_type, parts, _opts}) do
    1 + count_nodes(parts)
  end
  
  defp count_nodes(parts) when is_list(parts) do
    Enum.reduce(parts, 0, fn part, acc -> acc + count_nodes(part) end)
  end
  
  defp count_nodes(_), do: 1

  defp ast_depth(nodes) when is_list(nodes) do
    nodes |> Enum.map(&ast_depth/1) |> Enum.max(fn -> 0 end)
  end
  
  defp ast_depth({_type, parts, _opts}) do
    1 + ast_depth(parts)
  end
  
  defp ast_depth(parts) when is_list(parts) do
    parts |> Enum.map(&ast_depth/1) |> Enum.max(fn -> 0 end)
  end
  
  defp ast_depth(_), do: 0

  # Simple pattern matching parser for comparison
  defp parse_simple_pattern(template) do
    case String.trim(template) do
      "{{ " <> rest ->
        case String.split(rest, " }}", parts: 2) do
          [var_name, ""] when byte_size(var_name) > 0 ->
            if Regex.match?(~r/^[a-zA-Z_][a-zA-Z0-9_]*$/, var_name) do
              {:ok, [{:expression, [{:variable, [var_name], []}], []}]}
            else
              {:error, "invalid variable name"}
            end
          _ ->
            {:error, "not simple variable"}
        end
      _ ->
        {:error, "not variable template"}
    end
  end
end

IO.puts("Mau Parser Deep Analysis")
IO.puts(String.duplicate("=", 40))

ParserAnalysisSimple.run()