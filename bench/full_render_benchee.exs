defmodule FullRenderBenchee do
  @moduledoc """
  Benchmark focusing on full parse + render performance.
  
  Tests complete template processing: template string → AST → rendered output.
  """

  def run do
    IO.puts("=== Template Engine FULL RENDER Performance Benchmark ===\n")
    
    # Test scenarios with templates and their contexts
    scenarios = [
      {
        "Simple Text",
        "Hello World!",
        %{}
      },
      {
        "Variable Interpolation", 
        "Hello {{ name }}! Welcome to {{ site }}!",
        %{"name" => "Alice", "site" => "Mau Template Engine"}
      },
      {
        "Property Access",
        "Hello {{ user.name }}! Your email is {{ user.profile.email }}.",
        %{
          "user" => %{
            "name" => "Bob",
            "profile" => %{"email" => "bob@example.com"}
          }
        }
      },
      {
        "Simple Conditionals",
        "{% if active %}Active{% else %}Inactive{% endif %}",
        %{"active" => true}
      },
      {
        "Complex Conditionals",
        "{% if user.active and user.verified %}Welcome {{ user.name }}!{% elsif user.active %}Please verify your account.{% else %}Account inactive.{% endif %}",
        %{
          "user" => %{
            "active" => true,
            "verified" => true,
            "name" => "Charlie"
          }
        }
      },
      {
        "Simple Loop",
        "{% for item in items %}{{ item }}{% endfor %}",
        %{"items" => ["apple", "banana", "cherry"]}
      },
      {
        "Nested Loop",
        "{% for category in categories %}{{ category.name }}: {% for item in category.items %}{{ item }}{% if forloop.last %}{% else %}, {% endif %}{% endfor %}{% endfor %}",
        %{
          "categories" => [
            %{"name" => "Fruits", "items" => ["apple", "banana"]},
            %{"name" => "Colors", "items" => ["red", "blue"]}
          ]
        }
      },
      {
        "Assignment and Logic",
        "{% assign total = 0 %}{% for item in items %}{% assign item_price = item.price %}{% assign total = total %}{% endfor %}Total: {{ total }}",
        %{
          "items" => [
            %{"price" => 10},
            %{"price" => 20},
            %{"price" => 30}
          ]
        }
      },
      {
        "Complex Template",
        """
        <!DOCTYPE html>
        <html>
        <head><title>{{ page.title }}</title></head>
        <body>
          {% if user %}
            <h1>Welcome, {{ user.name }}!</h1>
            {% if user.notifications %}
              <div class="notifications">
                {% for notification in user.notifications %}
                  <div class="alert alert-info">
                    {{ notification.message }}
                    <small>{{ notification.created_at }}</small>
                  </div>
                {% endfor %}
              </div>
            {% endif %}
          {% else %}
            <h1>Please log in</h1>
          {% endif %}
          
          <main>
            {% for section in page.sections %}
              <section id="{{ section.id }}">
                <h2>{{ section.title }}</h2>
                {% if section.items %}
                  <ul>
                    {% for item in section.items %}
                      <li>
                        <a href="{{ item.url }}">{{ item.title }}</a>
                        {% if item.description %}
                          <p>{{ item.description }}</p>
                        {% endif %}
                      </li>
                    {% endfor %}
                  </ul>
                {% endif %}
              </section>
            {% endfor %}
          </main>
        </body>
        </html>
        """,
        %{
          "page" => %{
            "title" => "My Website",
            "sections" => [
              %{
                "id" => "intro",
                "title" => "Introduction",
                "items" => [
                  %{"url" => "/about", "title" => "About Us", "description" => "Learn more about our company"},
                  %{"url" => "/contact", "title" => "Contact", "description" => nil}
                ]
              }
            ]
          },
          "user" => %{
            "name" => "Dave",
            "notifications" => [
              %{"message" => "Welcome!", "created_at" => "2024-01-01"}
            ]
          }
        }
      }
    ]

    for {name, template, context} <- scenarios do
      IO.puts("=== #{name} ===")
      IO.puts("Template size: #{byte_size(template)} bytes")
      benchmark_full_render(template, context)
      IO.puts("")
    end
  end

  defp benchmark_full_render(template, context) do
    Benchee.run(
      %{
        "Mau (parse+render)" => fn -> 
          case Mau.render(template, context) do
            {:ok, _result} -> :ok
            {:error, _} -> :skip
          end
        end,
        "Solid (parse+render)" => fn -> 
          case Solid.parse(template) do
            {:ok, parsed} ->
              case Solid.render(parsed, context) do
                {:ok, _result, _errors} -> :ok
                {:error, _} -> :skip
              end
            {:error, _} -> :skip
          end
        end,
        "Liquex (parse+render)" => fn -> 
          case Liquex.parse(template) do
            {:ok, parsed} ->
              try do
                {_result, _context} = Liquex.render!(parsed, context)
                :ok
              rescue
                _ -> :skip
              end
            {:error, _} -> :skip
          end
        end
      },
      time: 1,
      memory_time: 1,
      warmup: 0.5,
      print: [benchmarking: false, fast_warning: false],
      formatters: [
        {Benchee.Formatters.Console, 
         comparison: true,
         extended_statistics: false
        }
      ]
    )

    # Verify all engines can render successfully
    verify_rendering(template, context)
  end

  defp verify_rendering(template, context) do
    # Test Mau rendering
    mau_result = case Mau.render(template, context) do
      {:ok, output} -> 
        {"Mau", :success, clean_output(output)}
      {:error, error} -> 
        {"Mau", {:error, error}, nil}
    end

    # Test Solid rendering
    solid_result = case Solid.parse(template) do
      {:ok, parsed} ->
        case Solid.render(parsed, context) do
          {:ok, output, _errors} -> 
            {"Solid", :success, clean_output(IO.iodata_to_binary(output))}
          {:error, error} -> 
            {"Solid", {:error, error}, nil}
        end
      {:error, error} -> 
        {"Solid", {:error, error}, nil}
    end

    # Test Liquex rendering
    liquex_result = case Liquex.parse(template) do
      {:ok, parsed} ->
        try do
          {output, _context} = Liquex.render!(parsed, context)
          {"Liquex", :success, clean_output(to_string(output))}
        rescue
          error -> {"Liquex", {:error, error}, nil}
        end
      {:error, error} -> 
        {"Liquex", {:error, error}, nil}
    end

    results = [mau_result, solid_result, liquex_result]

    # Show rendering results
    successes = Enum.filter(results, fn {_, status, _} -> status == :success end)
    
    case length(successes) do
      0 -> 
        IO.puts("❌ No engines could render this template")
        for {name, {:error, error}, _} <- results do
          IO.puts("   #{name}: #{inspect(error)}")
        end
      3 -> 
        # Check if all outputs match
        outputs = Enum.map(successes, &elem(&1, 2))
        unique_outputs = Enum.uniq(outputs)
        
        case length(unique_outputs) do
          1 -> 
            IO.puts("✅ All engines rendered successfully with matching output")
            IO.puts("Output preview: #{inspect(String.slice(List.first(unique_outputs), 0, 100))}...")
          _ -> 
            IO.puts("⚠️  All engines rendered but outputs differ:")
            for {name, :success, output} <- successes do
              IO.puts("   #{name}: #{inspect(String.slice(output, 0, 50))}...")
            end
        end
      _ -> 
        IO.puts("⚠️  Some engines failed to render:")
        for {name, status, data} <- results do
          case status do
            :success -> IO.puts("   ✅ #{name}: #{inspect(String.slice(data, 0, 50))}...")
            {:error, error} -> IO.puts("   ❌ #{name}: #{inspect(error)}")
          end
        end
    end
  end

  defp clean_output(output) do
    output |> String.trim() |> String.replace(~r/\s+/, " ")
  end
end

# Show engines
IO.puts("Template Engines - Full Render Performance:")
engines = [
  {"Mau", Mau, "Mau.render/2"},
  {"Solid", Solid, "Solid.parse/1 → Solid.render/2"}, 
  {"Liquex", Liquex, "Liquex.parse/1 → Liquex.render!/2"}
]

for {name, module, api} <- engines do
  case Code.ensure_loaded(module) do
    {:module, ^module} -> 
      version = Application.spec(String.to_atom(String.downcase(name)), :vsn) || "unknown"
      IO.puts("✅ #{name} #{version} - #{api}")
    _ -> 
      IO.puts("❌ #{name} not available")
  end
end

IO.puts("\n🎯 This benchmark measures complete template processing: parse + render\n")

FullRenderBenchee.run()