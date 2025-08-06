defmodule VariableAccessBenchee do
  @moduledoc """
  Focused benchmark for variable access patterns.
  
  Tests different types of variable resolution performance:
  - Simple variables
  - Property access
  - Deep property chains
  - Array/list indexing
  - Mixed access patterns
  """

  def run do
    IO.puts("=== Variable Access Performance Benchmark ===\n")
    
    # Test scenarios focusing on variable access patterns
    scenarios = [
      {
        "Simple Variables",
        "{{ name }} {{ age }} {{ active }}",
        %{"name" => "Alice", "age" => 30, "active" => true}
      },
      {
        "Single Property Access",
        "{{ user.name }} {{ user.email }}",
        %{
          "user" => %{
            "name" => "Bob",
            "email" => "bob@example.com"
          }
        }
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
        "Array Index Access",
        "{{ items[0] }} {{ items[1] }} {{ items[2] }}",
        %{"items" => ["apple", "banana", "cherry"]}
      },
      {
        "Mixed Access Pattern",
        "{{ users[0].profile.settings.theme }} {{ users[1].profile.settings.language }}",
        %{
          "users" => [
            %{
              "profile" => %{
                "settings" => %{
                  "theme" => "dark",
                  "language" => "en"
                }
              }
            },
            %{
              "profile" => %{
                "settings" => %{
                  "theme" => "light", 
                  "language" => "es"
                }
              }
            }
          ]
        }
      },
      {
        "Multiple Simple Variables",
        "{{ a }} {{ b }} {{ c }} {{ d }} {{ e }} {{ f }} {{ g }} {{ h }}",
        %{
          "a" => "value_a", "b" => "value_b", "c" => "value_c", "d" => "value_d",
          "e" => "value_e", "f" => "value_f", "g" => "value_g", "h" => "value_h"
        }
      },
      {
        "Multiple Property Access",
        "{{ user.name }} {{ user.email }} {{ user.age }} {{ user.active }} {{ user.role }}",
        %{
          "user" => %{
            "name" => "Charlie",
            "email" => "charlie@example.com", 
            "age" => 25,
            "active" => true,
            "role" => "developer"
          }
        }
      },
      {
        "Nested Map Access",
        "{{ config.database.host }} {{ config.database.port }} {{ config.cache.redis.url }}",
        %{
          "config" => %{
            "database" => %{
              "host" => "localhost",
              "port" => 5432
            },
            "cache" => %{
              "redis" => %{
                "url" => "redis://localhost:6379"
              }
            }
          }
        }
      }
    ]

    for {name, template, context} <- scenarios do
      IO.puts("=== #{name} ===")
      IO.puts("Template: #{template}")
      IO.puts("Variables: #{map_size(flatten_context(context))} total")
      benchmark_variable_access(template, context)
      IO.puts("")
    end
  end

  defp benchmark_variable_access(template, context) do
    Benchee.run(
      %{
        "Mau" => fn -> 
          case Mau.render(template, context) do
            {:ok, _result} -> :ok
            {:error, _} -> :error
          end
        end,
        "Solid" => fn -> 
          case Solid.parse(template) do
            {:ok, parsed} ->
              case Solid.render(parsed, context) do
                {:ok, _result, _errors} -> :ok
                {:error, _} -> :error
              end
            {:error, _} -> :error
          end
        end,
        "Liquex" => fn -> 
          case Liquex.parse(template) do
            {:ok, parsed} ->
              try do
                {_result, _context} = Liquex.render!(parsed, context)
                :ok
              rescue
                _ -> :error
              end
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

    # Verify outputs match
    verify_variable_access(template, context)
  end

  defp verify_variable_access(template, context) do
    # Test Mau
    mau_result = case Mau.render(template, context) do
      {:ok, output} -> 
        {:success, String.trim(output)}
      {:error, error} -> 
        {:error, error}
    end

    # Test Solid
    solid_result = case Solid.parse(template) do
      {:ok, parsed} ->
        case Solid.render(parsed, context) do
          {:ok, output, _errors} -> 
            {:success, String.trim(IO.iodata_to_binary(output))}
          {:error, error} -> 
            {:error, error}
        end
      {:error, error} -> 
        {:error, error}
    end

    # Test Liquex
    liquex_result = case Liquex.parse(template) do
      {:ok, parsed} ->
        try do
          {output, _context} = Liquex.render!(parsed, context)
          {:success, String.trim(to_string(output))}
        rescue
          error -> {:error, error}
        end
      {:error, error} -> 
        {:error, error}
    end

    results = [
      {"Mau", mau_result},
      {"Solid", solid_result}, 
      {"Liquex", liquex_result}
    ]

    # Check results
    successes = Enum.filter(results, fn {_, {status, _}} -> status == :success end)
    
    case length(successes) do
      3 ->
        outputs = Enum.map(successes, fn {_, {:success, output}} -> output end)
        if Enum.uniq(outputs) |> length() == 1 do
          IO.puts("✅ All engines match: #{inspect(List.first(outputs))}")
        else
          IO.puts("⚠️  Outputs differ:")
          for {name, {:success, output}} <- successes do
            IO.puts("   #{name}: #{inspect(output)}")
          end
        end
      _ ->
        IO.puts("❌ Some engines failed:")
        for {name, result} <- results do
          case result do
            {:success, output} -> IO.puts("   ✅ #{name}: #{inspect(output)}")
            {:error, error} -> IO.puts("   ❌ #{name}: #{inspect(error)}")
          end
        end
    end
  end

  # Helper to count total variables in nested context
  defp flatten_context(context) when is_map(context) do
    Enum.reduce(context, %{}, fn {key, value}, acc ->
      case value do
        val when is_map(val) ->
          nested = flatten_context(val)
          nested_with_prefix = 
            for {nested_key, nested_val} <- nested, into: %{} do
              {"#{key}.#{nested_key}", nested_val}
            end
          Map.merge(acc, Map.put(nested_with_prefix, key, value))
        _ ->
          Map.put(acc, key, value)
      end
    end)
  end
  
  defp flatten_context(value), do: %{"_" => value}
end

# Show available engines
IO.puts("Variable Access Performance Comparison:")
engines = [
  {"Mau", Mau},
  {"Solid", Solid}, 
  {"Liquex", Liquex}
]

for {name, module} <- engines do
  case Code.ensure_loaded(module) do
    {:module, ^module} -> 
      IO.puts("✅ #{name} available")
    _ -> 
      IO.puts("❌ #{name} not available")
  end
end

IO.puts("\n🎯 Testing variable resolution performance across different access patterns\n")

VariableAccessBenchee.run()