defmodule ParserAnalysisBenchee do
  @moduledoc """
  Deep analysis of parser performance bottlenecks.
  
  This benchmark isolates different parts of the parsing pipeline:
  1. Raw NimbleParsec combinator performance
  2. AST node construction overhead
  3. Different expression types parsing cost
  4. Memory allocation patterns
  5. Combinator vs manual parsing comparison
  """

  alias Mau.Parser

  def run do
    IO.puts("=== Deep Parser Performance Analysis ===\n")
    
    analyze_combinator_overhead()
    analyze_ast_construction()
    analyze_expression_types()
    analyze_memory_patterns()
    analyze_optimization_opportunities()
  end

  def analyze_combinator_overhead do
    IO.puts("=== 1. NimbleParsec Combinator Overhead Analysis ===")
    
    # Test different parsing complexity levels
    test_cases = [
      {"Simple Text", "Hello World", "Just plain text"},
      {"Single Variable", "{{ name }}", "Simplest expression"},
      {"Property Access", "{{ user.name }}", "Single property"},
      {"Deep Property", "{{ a.b.c.d.e }}", "Deep property chain"},
      {"Mixed Content", "Hello {{ name }}!", "Text + expression"},
      {"Multiple Variables", "{{ a }} {{ b }} {{ c }}", "Multiple expressions"},
      {"Complex Expression", "{{ user.items | length }}", "Expression with filter"},
      {"Conditional", "{% if active %}Yes{% endif %}", "Simple conditional block"}
    ]

    for {name, template, description} <- test_cases do
      IO.puts("#{name} (#{description}): #{template}")
      benchmark_single_parse(template)
      analyze_parse_result(template)
      IO.puts("")
    end
  end

  def analyze_ast_construction do
    IO.puts("=== 2. AST Node Construction Overhead ===")
    
    # Compare parsing with and without full AST construction
    simple_template = "{{ name }}"
    
    IO.puts("Analyzing AST construction overhead for: #{simple_template}")
    
    Benchee.run(
      %{
        "Full Parse (AST + all processing)" => fn ->
          case Parser.parse(simple_template) do
            {:ok, _ast} -> :ok
            {:error, _} -> :error
          end
        end,
        "Raw NimbleParsec Parse" => fn ->
          # This will show what the raw combinator performance looks like
          case Parser.parse_template(simple_template) do
            {:ok, _nodes, "", _, _, _} -> :ok
            _ -> :error
          end
        end
      },
      time: 1,
      memory_time: 0.5,
      warmup: 0.3,
      print: [benchmarking: false, fast_warning: false],
      formatters: [
        {Benchee.Formatters.Console, 
         comparison: true,
         extended_statistics: false
        }
      ]
    )
    
    IO.puts("")
  end

  def analyze_expression_types do
    IO.puts("=== 3. Expression Type Parsing Cost Analysis ===")
    
    expression_types = [
      {"Literal String", ~s({{ "hello" }})},
      {"Literal Number", "{{ 42 }}"},
      {"Literal Boolean", "{{ true }}"},
      {"Simple Variable", "{{ name }}"},
      {"Property Access", "{{ user.name }}"},
      {"Deep Property", "{{ a.b.c.d.e.f }}"},
      {"Array Index", "{{ items[0] }}"},
      {"Binary Operation", "{{ a + b }}"},
      {"Comparison", "{{ x == y }}"},
      {"Logical Operation", "{{ a and b }}"},
      {"Function Call", "{{ length(items) }}"},
      {"Pipe Filter", "{{ name | upcase }}"},
      {"Complex Expression", "{{ users[0].profile.name | upcase }}"}
    ]

    for {name, template} <- expression_types do
      IO.puts("#{name}: #{template}")
      benchmark_expression_parsing(template)
    end
    
    IO.puts("")
  end

  def analyze_memory_patterns do
    IO.puts("=== 4. Memory Allocation Pattern Analysis ===")
    
    large_template = Enum.map(1..20, fn i -> "{{ var#{i} }}" end) |> Enum.join(" ")
    
    templates = [
      {"Minimal", "{{ x }}"},
      {"Medium", "{{ user.name }} is {{ user.age }} years old"},
      {"Large", large_template}
    ]
    
    for {name, template} <- templates do
      IO.puts("#{name} template: #{String.slice(template, 0, 50)}...")
      
      # Measure memory allocations during parsing
      {parse_time, {:ok, ast}} = :timer.tc(fn -> Parser.parse(template) end)
      
      # Count AST nodes
      node_count = count_ast_nodes(ast)
      ast_size = :erlang.external_size(ast)
      
      IO.puts("  Parse time: #{parse_time}μs")
      IO.puts("  AST nodes: #{node_count}")
      IO.puts("  AST size: #{ast_size} bytes")
      IO.puts("  Time per node: #{Float.round(parse_time / node_count, 2)}μs")
      IO.puts("  Bytes per node: #{Float.round(ast_size / node_count, 2)}")
      IO.puts("")
    end
  end

  def analyze_optimization_opportunities do
    IO.puts("=== 5. Parser Optimization Opportunities ===")
    
    # Test potential optimization strategies
    simple_var = "{{ name }}"
    
    IO.puts("Testing optimization strategies for: #{simple_var}")
    
    # Current approach
    {current_time, current_result} = :timer.tc(fn -> 
      Parser.parse(simple_var)
    end)
    
    IO.puts("Current parser: #{current_time}μs")
    
    # Test regex-based fast path (just for analysis)
    {regex_time, regex_result} = :timer.tc(fn ->
      if Regex.match?(~r/^\s*\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\}\}\s*$/, simple_var) do
        [_, var_name] = Regex.run(~r/^\s*\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\}\}\s*$/, simple_var)
        {:ok, [{:expression, [{:variable, [var_name], []}], []}]}
      else
        {:error, "not simple"}
      end
    end)
    
    case regex_result do
      {:ok, ast} -> 
        IO.puts("Regex fast path: #{regex_time}μs (#{Float.round(current_time / regex_time, 1)}x faster)")
        IO.puts("  Results match: #{ast == elem(current_result, 1)}")
      _ -> 
        IO.puts("Regex fast path failed")
    end
    
    # Test manual parsing approach
    {manual_time, manual_result} = :timer.tc(fn ->
      parse_simple_variable_manual(simple_var)
    end)
    
    case manual_result do
      {:ok, ast} ->
        IO.puts("Manual parsing: #{manual_time}μs (#{Float.round(current_time / manual_time, 1)}x faster)")
        IO.puts("  Results match: #{ast == elem(current_result, 1)}")
      _ ->
        IO.puts("Manual parsing failed")
    end
    
    IO.puts("")
  end

  # Helper functions
  
  defp benchmark_single_parse(template) do
    {time, result} = :timer.tc(fn -> Parser.parse(template) end)
    
    case result do
      {:ok, ast} -> 
        nodes = count_ast_nodes(ast)
        IO.puts("  Parse time: #{time}μs, AST nodes: #{nodes}, Time/node: #{Float.round(time/nodes, 2)}μs")
      {:error, error} ->
        IO.puts("  Parse failed: #{inspect(error)}")
    end
  end

  defp analyze_parse_result(template) do
    case Parser.parse(template) do
      {:ok, ast} ->
        IO.puts("  AST structure: #{inspect(ast, limit: :infinity)}")
        IO.puts("  Memory size: #{:erlang.external_size(ast)} bytes")
      {:error, error} ->
        IO.puts("  Parse error: #{inspect(error)}")
    end
  end

  defp benchmark_expression_parsing(template) do
    iterations = 1000
    
    {total_time, _results} = :timer.tc(fn ->
      for _i <- 1..iterations do
        Parser.parse(template)
      end
    end)
    
    avg_time = total_time / iterations
    IO.puts("  Average parse time: #{Float.round(avg_time, 2)}μs")
  end

  defp count_ast_nodes(nodes) when is_list(nodes) do
    Enum.reduce(nodes, 0, fn node, acc -> acc + count_ast_nodes(node) end)
  end

  defp count_ast_nodes({_type, parts, _opts}) do
    1 + count_ast_nodes(parts)
  end

  defp count_ast_nodes(parts) when is_list(parts) do
    Enum.reduce(parts, 0, fn part, acc -> acc + count_ast_nodes(part) end)
  end

  defp count_ast_nodes(_), do: 1

  # Manual parsing for comparison - very basic implementation
  defp parse_simple_variable_manual(template) do
    template = String.trim(template)
    
    case Regex.run(~r/^\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\}\}$/, template) do
      [_full, var_name] ->
        {:ok, [{:expression, [{:variable, [var_name], []}], []}]}
      nil ->
        {:error, "not a simple variable"}
    end
  end

  # Detailed combinator analysis
  def analyze_combinator_patterns do
    IO.puts("=== 6. NimbleParsec Combinator Pattern Analysis ===")
    
    # Test individual combinator performance
    test_combinator_performance()
  end

  defp test_combinator_performance do
    # This would require access to individual combinators
    # For now, we'll analyze the patterns we see in the actual parser
    
    IO.puts("Combinator pattern analysis:")
    IO.puts("1. Choice combinators (performance decreases with more options)")
    IO.puts("2. Repeat combinators (memory allocation per iteration)")
    IO.puts("3. Reduce functions (AST construction overhead)")
    IO.puts("4. Lookahead operations (backtracking cost)")
    IO.puts("")
  end
end

IO.puts("Mau Parser Deep Performance Analysis")
IO.puts(String.duplicate("=", 50))

ParserAnalysisBenchee.run()
ParserAnalysisBenchee.analyze_combinator_patterns()