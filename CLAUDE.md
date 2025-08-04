# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mau is an Elixir library for a template engine called "Prana" that implements a Liquid-like template language. The project includes:

- Template AST specification with unified tuple format
- Template evaluator implementation patterns
- Complete language reference with workflow integration

## Common Development Commands

**Build and compile:**
```bash
mix compile
```

**Run tests:**
```bash
mix test
```

**Run specific test:**
```bash
mix test test/mau_test.exs
```

**Interactive shell:**
```bash
iex -S mix
```

**Generate documentation:**
```bash
mix docs
```

## Architecture Overview

The Mau template engine follows a clean separation of concerns:

1. **AST Structure**: All nodes use unified tuple format `{type, parts, opts}`
   - `:text` - Raw text content
   - `:literal` - Constant values (numbers, strings, booleans, nil)
   - `:expression` - Variable interpolation in `{{ }}`
   - `:tag` - Control flow and logic in `{% %}`

2. **Expression Types**: Nested expression tuples for:
   - Variable access with path segments: `{:variable, ["user", "name"], []}`
   - Binary operations: `{:binary_op, [op, left, right], []}`
   - Logical operations: `{:logical_op, [op, left, right], []}`
   - Function calls: `{:call, [func_name, args], []}`

3. **Tag System**: Pattern-matched tag rendering with subtypes:
   - Control flow: `:if`, `:for` loops
   - Utility: `:assign` for variable assignment

4. **Workflow Integration**: Special variables with `$` prefix:
   - `$input` - Workflow input data
   - `$nodes` - Node execution results
   - `$variables` - Workflow-level variables
   - `$context` - Execution metadata

## Key Implementation Patterns

**Unified Tag Interface**: All tags use `render_tag(tag_name, params, opts, context)` for consistent handling.

**Expression Evaluation**: Clear separation between evaluation (expressions) and rendering (tags/text) with `evaluate_expression/2` and `render_tag/4`.

**Whitespace Control**: Support for trimming with `trim_left` and `trim_right` options in AST nodes.

**Error Handling**: Configurable strict mode - graceful degradation vs explicit errors for undefined variables.

## Project Structure

- `lib/mau.ex` - Main module (currently placeholder)
- `docs/` - Comprehensive documentation:
  - `template_ast_specification.md` - Complete AST node definitions
  - `template_evaluator_implementation.md` - Implementation patterns and examples
  - `template_language_reference.md` - Language syntax and features
- `test/` - ExUnit test suite with doctests
- `IMPLEMENTATION_PLAN.md` - implementation details plan
- `TASKS.md` task check list

## Command line node
- There is no `-v` option for `mix test`. Use `mix test file.exs --trace`
- To run code with elixir within project use `mix run -e "your code"`
