defmodule Mau.MixProject do
  use Mix.Project

  def project do
    [
      app: :mau,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:benchee, "~> 1.0", only: [:dev, :test]}
    ]
  end
end
