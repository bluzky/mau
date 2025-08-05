defmodule ParsingBenchee do
  @moduledoc """
  Benchmark focusing purely on parsing performance.
  
  Tests how fast each engine can convert template strings to AST.
  """

  def run do
    IO.puts("=== Template Engine PARSING Performance Benchmark ===\n")
    
    # Test scenarios of increasing complexity
    scenarios = [
      {
        "Simple Text",
        "Hello World!"
      },
      {
        "Variable Interpolation", 
        "Hello {{ name }}! Welcome to {{ site }}!"
      },
      {
        "Property Access",
        "Hello {{ user.name }}! Your email is {{ user.profile.email }}."
      },
      {
        "Simple Conditionals",
        "{% if active %}Active{% else %}Inactive{% endif %}"
      },
      {
        "Complex Conditionals",
        "{% if user.active and user.verified %}Welcome {{ user.name }}!{% elsif user.active %}Please verify your account.{% else %}Account inactive.{% endif %}"
      },
      {
        "Simple Loop",
        "{% for item in items %}{{ item }}{% endfor %}"
      },
      {
        "Nested Loop",
        "{% for category in categories %}{{ category.name }}: {% for item in category.items %}{{ item }}{% if forloop.last %}{% else %}, {% endif %}{% endfor %}{% endfor %}"
      },
      {
        "Assignment and Logic",
        "{% assign total = 0 %}{% for item in items %}{% assign item_price = item.price %}{% assign total = total %}{% endfor %}Total: {{ total }}"
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
        """
      }
      # NOTE: Arithmetic Operations template removed because Solid and Liquex don't support arithmetic
      # {
      #   "Arithmetic Operations",
      #   "Result: {{ a + b }} and {{ x - y }} and {{ a * b / c }}"
      # }
    ]

    for {name, template} <- scenarios do
      IO.puts("=== #{name} ===")
      IO.puts("Template size: #{byte_size(template)} bytes")
      benchmark_parsing(template)
      IO.puts("")
    end
  end

  defp benchmark_parsing(template) do
    Benchee.run(
      %{
        "Mau.compile" => fn -> 
          case Mau.compile(template) do
            {:ok, _ast} -> :ok
            {:error, _} -> :skip
          end
        end,
        "Solid.parse" => fn -> 
          case Solid.parse(template) do
            {:ok, _parsed} -> :ok
            {:error, _} -> :skip
          end
        end,
        "Liquex.parse" => fn -> 
          case Liquex.parse(template) do
            {:ok, _parsed} -> :ok
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

    # Verify all engines can parse successfully
    verify_parsing(template)
  end

  defp verify_parsing(template) do
    # Test Mau parsing
    mau_result = case Mau.compile(template) do
      {:ok, ast} -> 
        ast_size = :erlang.external_size(ast)
        {"Mau", :success, ast_size}
      {:error, error} -> 
        {"Mau", {:error, error}, nil}
    end

    # Test Solid parsing
    solid_result = case Solid.parse(template) do
      {:ok, parsed} -> 
        parsed_size = :erlang.external_size(parsed)
        {"Solid", :success, parsed_size}
      {:error, error} -> 
        {"Solid", {:error, error}, nil}
    end

    # Test Liquex parsing
    liquex_result = case Liquex.parse(template) do
      {:ok, parsed} -> 
        parsed_size = :erlang.external_size(parsed)
        {"Liquex", :success, parsed_size}
      {:error, error} -> 
        {"Liquex", {:error, error}, nil}
    end

    results = [mau_result, solid_result, liquex_result]

    # Show parsing results
    successes = Enum.filter(results, fn {_, status, _} -> status == :success end)
    
    case length(successes) do
      0 -> 
        IO.puts("❌ No engines could parse this template")
        for {name, {:error, error}, _} <- results do
          IO.puts("   #{name}: #{inspect(error)}")
        end
      3 -> 
        IO.puts("✅ All engines parsed successfully")
        IO.puts("AST sizes:")
        for {name, :success, size} <- successes do
          IO.puts("   #{name}: #{size} bytes")
        end
      _ -> 
        IO.puts("⚠️  Some engines failed to parse:")
        for {name, status, data} <- results do
          case status do
            :success -> IO.puts("   ✅ #{name}: #{data} bytes")
            {:error, error} -> IO.puts("   ❌ #{name}: #{inspect(error)}")
          end
        end
    end
  end
end

# Show engines
IO.puts("Template Engines - Parsing Performance:")
engines = [
  {"Mau", Mau, "Mau.compile/1"},
  {"Solid", Solid, "Solid.parse/1"}, 
  {"Liquex", Liquex, "Liquex.parse/1"}
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

IO.puts("\n🎯 This benchmark measures pure parsing speed - template string → AST\n")

ParsingBenchee.run()