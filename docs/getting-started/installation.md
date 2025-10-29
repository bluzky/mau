# Installation

Get Mau up and running in your Elixir project.

## Requirements

- **Elixir** 1.14 or higher
- **Erlang/OTP** 25.0 or higher

## Installation Steps

### 1. Add Mau to Your Dependencies

Open your `mix.exs` file and add Mau to the `deps` function:

```elixir
def deps do
  [
    {:mau, "~> 0.5"}
  ]
end
```

### 2. Fetch Dependencies

Run the following command in your project directory:

```bash
mix deps.get
```

This will download Mau and its dependencies.

### 3. Verify Installation

Create a simple test in your IEx console:

```bash
iex -S mix
```

Then run:

```elixir
iex> template = "Hello {{ name }}!"
iex> context = %{"name" => "World"}
iex> Mau.render(template, context)
{:ok, "Hello World!"}
```

If you see `{:ok, "Hello World!"}`, Mau is properly installed!

## Optional Configuration

### Enable Runtime Custom Filters

If you want to use custom filters at runtime, add configuration to `config/config.exs`:

```elixir
config :mau,
  enable_runtime_filters: true,
  filters: [MyApp.CustomFilters]
```

Then add `Mau.FilterRegistry` to your supervision tree in `lib/my_app/application.ex`:

```elixir
def start(_type, _args) do
  children = [
    # ... other supervisors
    Mau.FilterRegistry
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Troubleshooting

### Compilation Issues

If you encounter compilation errors, try:

```bash
# Clean build artifacts
mix clean

# Recompile
mix compile
```

### Version Conflicts

If you have dependency version conflicts, update your `mix.lock`:

```bash
mix deps.unlock mau
mix deps.get
```

## Next Steps

- [Quick Start](quick-start.md) - 5-minute tutorial
- [Basic Concepts](basic-concepts.md) - Core concepts overview
- [Your First Template](first-template.md) - Step-by-step walkthrough

## Getting Help

- Check the [Troubleshooting Guide](../advanced/error-handling.md)
- Review [Email Template Examples](../examples/email-templates.md)
- Open an issue on [GitHub](https://github.com/bluzky/mau)
