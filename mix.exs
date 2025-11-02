defmodule Mau.MixProject do
  use Mix.Project

  def project do
    [
      app: :mau,
      version: "0.6.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Mau is a powerful Liquid-inspired template engine for Elixir with enhanced expression support.",
      package: package(),
      docs: docs(),
      source_url: "https://github.com/bluzky/mau",
      homepage_url: "https://github.com/bluzky/mau"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.4"},
      # Benchmarking dependencies
      # {:solid, "~> 1.0", only: [:test]},
      # {:liquex, "~> 0.12", only: [:test]},
      # {:benchee, "~> 1.0", only: [:test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "mau",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/bluzky/mau",
        "Documentation" => "https://hexdocs.pm/mau"
      },
      maintainers: ["Dũng Nguyễn"],
      files: ~w(lib docs .formatter.exs mix.exs README* LICENSE* CHANGELOG*)
    ]
  end

  defp docs do
    [
      name: "Mau",
      main: "readme",
      extras: [
        "README.md",
        "docs/reference/template-language.md",
        "docs/reference/ast-specification.md",
        "docs/reference/filters-list.md",
        "docs/reference/api-reference.md",
        "docs/reference/map-directives.md",
        "docs/guides/template-syntax.md",
        "docs/guides/filters.md",
        "docs/guides/control-flow.md",
        "docs/guides/variables.md",
        "docs/guides/whitespace-control.md",
        "docs/guides/map-rendering.md",
        "docs/getting-started/installation.md",
        "docs/getting-started/quick-start.md",
        "docs/getting-started/basic-concepts.md",
        "docs/getting-started/first-template.md",
        "docs/advanced/custom-filters.md",
        "docs/advanced/custom-functions.md",
        "docs/advanced/performance-tuning.md",
        "docs/advanced/error-handling.md",
        "docs/advanced/security.md",
        "docs/advanced/extending-mau.md",
        "docs/examples/email-templates.md",
        "docs/examples/report-generation.md",
        "docs/examples/data-transformation.md"
      ],
      groups_for_extras: [
        "Getting Started": [
          "docs/getting-started/installation.md",
          "docs/getting-started/quick-start.md",
          "docs/getting-started/basic-concepts.md",
          "docs/getting-started/first-template.md"
        ],
        Guides: [
          "docs/guides/template-syntax.md",
          "docs/guides/filters.md",
          "docs/guides/control-flow.md",
          "docs/guides/variables.md",
          "docs/guides/whitespace-control.md",
          "docs/guides/map-rendering.md"
        ],
        Reference: [
          "docs/reference/template-language.md",
          "docs/reference/ast-specification.md",
          "docs/reference/filters-list.md",
          "docs/reference/api-reference.md",
          "docs/reference/map-directives.md"
        ],
        Advanced: [
          "docs/advanced/custom-filters.md",
          "docs/advanced/custom-functions.md",
          "docs/advanced/performance-tuning.md",
          "docs/advanced/error-handling.md",
          "docs/advanced/security.md",
          "docs/advanced/extending-mau.md"
        ],
        Examples: [
          "docs/examples/email-templates.md",
          "docs/examples/report-generation.md",
          "docs/examples/data-transformation.md"
        ]
      ],
      source_ref: "main"
    ]
  end
end
