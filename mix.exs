defmodule Mau.MixProject do
  use Mix.Project

  def project do
    [
      app: :mau,
      version: "0.4.0",
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
      {:solid, "~> 1.0", only: [:dev, :test]},
      {:liquex, "~> 0.12", only: [:dev, :test]},
      {:benchee, "~> 1.0", only: [:dev, :test]},
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
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*)
    ]
  end

  defp docs do
    [
      name: "Mau",
      main: "readme",
      extras: [
        "README.md",
        "docs/template_language_reference.md",
        "docs/template_ast_specification.md",
        "docs/template_evaluator_implementation.md"
      ],
      groups_for_extras: [
        "Getting Started": ["README.md"],
        Documentation: [
          "docs/template_language_reference.md",
          "docs/template_ast_specification.md",
          "docs/template_evaluator_implementation.md"
        ]
      ],
      source_ref: "main"
    ]
  end
end
