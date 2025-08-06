defmodule PipelineBreakdownBenchee do
  @moduledoc """
  Benchmark to isolate performance bottlenecks in the Mau template processing pipeline.
  
  Measures each step independently:
  1. Parsing (template string → AST)
  2. Whitespace processing (AST → trimmed AST)
  3. Block processing (AST → processed AST with blocks)
  4. Rendering (AST → output string)
  5. Full pipeline (template → output)
  """

  alias Mau.Parser
  alias Mau.Renderer
  alias Mau.BlockProcessor
  alias Mau.WhitespaceProcessor

  def run do
    IO.puts("=== Pipeline Performance Breakdown ===\n")
    
    # Test scenarios that showed different performance characteristics
    scenarios = [
      {
        "Simple Variables",
        "{{ name }} {{ age }} {{ active }}",
        %{"name" => "Alice", "age" => 30, "active" => true}
      },
      {
        "Deep Property Chain",
        "{{ company.departments.engineering.teams.backend.lead.name }}",
        %{
          "company" => %{
            "departments" => %{
              "engineering" => %{
                "teams" => %{
                  "backend" => %{
                    "lead" => %{
                      "name" => "Sarah Connor"
                    }
                  }
                }
              }
            }
          }
        }
      },
      {
        "Complex Template",
        """
        {% if user %}
          <h1>Welcome, {{ user.name }}!</h1>
          {% for item in user.items %}
            <div>{{ item.title }}: {{ item.value }}</div>
          {% endfor %}
        {% else %}
          <h1>Please log in</h1>
        {% endif %}
        """,
        %{
          "user" => %{
            "name" => "Bob",
            "items" => [
              %{"title" => "First", "value" => "Value1"},
              %{"title" => "Second", "value" => "Value2"}
            ]
          }
        }
      }
    ]

    for {name, template, context} <- scenarios do
      IO.puts("=== #{name} ===")
      IO.puts("Template size: #{byte_size(template)} bytes")
      benchmark_pipeline_steps(template, context)
      IO.puts("")
    end
  end

  defp benchmark_pipeline_steps(template, context) do
    # Pre-compute intermediate results for isolated step testing
    {:ok, parsed_ast} = Parser.parse(template)
    trimmed_ast = WhitespaceProcessor.apply_whitespace_control(parsed_ast)
    processed_ast = BlockProcessor.process_blocks(trimmed_ast)

    Benchee.run(
      %{
        "1. Parse Only" => fn -> 
          case Parser.parse(template) do
            {:ok, _ast} -> :ok
            {:error, _} -> :error
          end
        end,
        "2. Whitespace Process Only" => fn -> 
          WhitespaceProcessor.apply_whitespace_control(parsed_ast)
          :ok
        end,
        "3. Block Process Only" => fn -> 
          BlockProcessor.process_blocks(trimmed_ast)
          :ok
        end,
        "4. Render Only" => fn -> 
          case Renderer.render(processed_ast, context) do
            {:ok, _result} -> :ok
            {:error, _} -> :error
          end
        end,
        "5. Full Pipeline" => fn -> 
          case Mau.render(template, context) do
            {:ok, _result} -> :ok
            {:error, _} -> :error
          end
        end
      },
      time: 2,
      memory_time: 1,
      warmup: 0.5,
      print: [benchmarking: false, fast_warning: false],
      formatters: [
        {Benchee.Formatters.Console, 
         comparison: true,
         extended_statistics: true
        }
      ]
    )

    # Show step-by-step timing breakdown
    show_step_breakdown(template, context)
  end

  defp show_step_breakdown(template, context) do
    IO.puts("Step-by-step timing breakdown:")

    # Measure parsing
    {parse_time, parse_result} = :timer.tc(fn -> Parser.parse(template) end)
    case parse_result do
      {:ok, parsed_ast} ->
        IO.puts("  1. Parsing: #{format_time(parse_time)}")

        # Measure whitespace processing
        {ws_time, trimmed_ast} = :timer.tc(fn -> 
          WhitespaceProcessor.apply_whitespace_control(parsed_ast) 
        end)
        IO.puts("  2. Whitespace processing: #{format_time(ws_time)}")

        # Measure block processing
        {block_time, processed_ast} = :timer.tc(fn -> 
          BlockProcessor.process_blocks(trimmed_ast)
        end)
        IO.puts("  3. Block processing: #{format_time(block_time)}")

        # Measure rendering
        {render_time, render_result} = :timer.tc(fn -> 
          Renderer.render(processed_ast, context)
        end)
        case render_result do
          {:ok, _output} ->
            IO.puts("  4. Rendering: #{format_time(render_time)}")
            
            total_measured = parse_time + ws_time + block_time + render_time
            IO.puts("  Total measured: #{format_time(total_measured)}")

            # Measure full pipeline for comparison
            {full_time, full_result} = :timer.tc(fn -> 
              Mau.render(template, context)
            end)
            case full_result do
              {:ok, _output} ->
                IO.puts("  Full pipeline: #{format_time(full_time)}")
                overhead = full_time - total_measured
                IO.puts("  Pipeline overhead: #{format_time(overhead)}")
              {:error, error} ->
                IO.puts("  Full pipeline failed: #{inspect(error)}")
            end
          {:error, error} ->
            IO.puts("  Rendering failed: #{inspect(error)}")
        end
      {:error, error} ->
        IO.puts("  Parsing failed: #{inspect(error)}")
    end

    IO.puts("")
  end

  defp format_time(microseconds) do
    cond do
      microseconds < 1_000 -> "#{microseconds}μs"
      microseconds < 1_000_000 -> "#{Float.round(microseconds / 1_000, 2)}ms" 
      true -> "#{Float.round(microseconds / 1_000_000, 2)}s"
    end
  end

  # Compare with Solid's pipeline breakdown
  def compare_with_solid do
    IO.puts("\n=== Comparison with Solid Pipeline ===\n")
    
    test_cases = [
      {"Simple", "{{ name }}", %{"name" => "Alice"}},
      {"Property", "{{ user.name }}", %{"user" => %{"name" => "Bob"}}},
      {"Complex", "{% if active %}{{ message }}{% endif %}", %{"active" => true, "message" => "Hello"}}
    ]

    for {name, template, context} <- test_cases do
      IO.puts("=== #{name} Template ===")
      compare_engines_pipeline(template, context)
      IO.puts("")
    end
  end

  defp compare_engines_pipeline(template, context) do
    # Mau pipeline breakdown
    IO.puts("Mau pipeline:")
    {mau_parse_time, mau_parse_result} = :timer.tc(fn -> Parser.parse(template) end)
    
    case mau_parse_result do
      {:ok, parsed_ast} ->
        IO.puts("  Parse: #{format_time(mau_parse_time)}")
        
        {mau_render_time, mau_render_result} = :timer.tc(fn ->
          trimmed_ast = WhitespaceProcessor.apply_whitespace_control(parsed_ast)
          processed_ast = BlockProcessor.process_blocks(trimmed_ast)
          Renderer.render(processed_ast, context)
        end)
        
        case mau_render_result do
          {:ok, _} -> 
            IO.puts("  Process + Render: #{format_time(mau_render_time)}")
            IO.puts("  Total: #{format_time(mau_parse_time + mau_render_time)}")
          {:error, error} ->
            IO.puts("  Process + Render failed: #{inspect(error)}")
        end
      {:error, error} ->
        IO.puts("  Parse failed: #{inspect(error)}")
    end

    # Solid pipeline breakdown
    IO.puts("Solid pipeline:")
    {solid_parse_time, solid_parse_result} = :timer.tc(fn -> Solid.parse(template) end)
    
    case solid_parse_result do
      {:ok, parsed} ->
        IO.puts("  Parse: #{format_time(solid_parse_time)}")
        
        {solid_render_time, solid_render_result} = :timer.tc(fn ->
          Solid.render(parsed, context)
        end)
        
        case solid_render_result do
          {:ok, _, _} -> 
            IO.puts("  Render: #{format_time(solid_render_time)}")
            IO.puts("  Total: #{format_time(solid_parse_time + solid_render_time)}")
          {:error, error} ->
            IO.puts("  Render failed: #{inspect(error)}")
        end
      {:error, error} ->
        IO.puts("  Parse failed: #{inspect(error)}")
    end
  end
end

IO.puts("Mau Template Pipeline Performance Analysis")
IO.puts(String.duplicate("=", 50))

PipelineBreakdownBenchee.run()
PipelineBreakdownBenchee.compare_with_solid()