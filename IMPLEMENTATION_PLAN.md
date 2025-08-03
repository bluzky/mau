# Mau Template Engine Implementation Plan

## Overview

This document outlines the detailed implementation plan for the Mau template engine, which supports the Prana template language syntax. The engine will provide three main public methods with comprehensive error handling and performance optimization.

## Public API Design

### 1. `Mau.compile/2`

**Signature:**
```elixir
@spec compile(template :: String.t(), opts :: keyword()) :: 
  {:ok, ast :: term()} | 
  {:ok, ast :: term(), warnings :: [term()]} |
  {:error, error_details :: term()}
```

**Options:**
- `:strict_mode` - boolean, default `false`
- `:trim_blocks` - boolean, default `false`
- `:lstrip_blocks` - boolean, default `false`

**Behavior:**
- **Ease mode** (`strict_mode: false`): Return `{:ok, ast, warnings}` with warnings for incomplete/malformed expressions
- **Strict mode** (`strict_mode: true`): Return `{:ok, ast, []}` for valid templates, `{:error, details}` for any syntax errors
- Parse template string into AST following the specification in `docs/template_ast_specification.md`

### 2. `Mau.render/3`

**Signature:**
```elixir
@spec render(template :: String.t() | ast :: term(), context :: map(), opts :: keyword()) :: 
  {:ok, result :: String.t() | term()} | 
  {:error, error_details :: term()}
```

**Behavior:**
- Accept either template string or pre-compiled AST
- **Pure expression** (`{{ exp }}`): Return `{:ok, evaluated_value}`
- **Mixed content**: Return `{:ok, rendered_string}`
- Handle variable interpolation, control flow, and filters

### 3. `Mau.render_map/3`

**Signature:**
```elixir
@spec render_map(nested_map :: map(), context :: map(), opts :: keyword()) :: 
  {:ok, result_map :: map()} | 
  {:error, error_details :: term()}
```

**Behavior:**
- Recursively traverse nested map structure
- Render any string values that contain template syntax
- Leave non-template strings unchanged
- Preserve map structure and non-string values

## Implementation Architecture

### Phase 1: Core Infrastructure (Week 1-2)

#### 1.1 Project Structure
```
lib/
├── mau.ex                           # Main public API
├── mau/
│   ├── lexer.ex                     # Tokenization
│   ├── parser.ex                    # AST generation
│   ├── evaluator.ex                 # Expression evaluation
│   ├── renderer.ex                  # Template rendering
│   ├── filter_registry.ex           # Filter system
│   ├── ast/
│   │   ├── nodes.ex                 # AST node helpers
│   │   └── validator.ex             # AST validation
│   ├── filters/
│   │   ├── string_filters.ex
│   │   ├── number_filters.ex
│   │   ├── collection_filters.ex
│   │   └── math_filters.ex
│   └── error.ex                     # Error handling
```

#### 1.2 Error Handling System
```elixir
defmodule Mau.Error do
  defstruct [:type, :message, :line, :column, :source_file, :context]
  
  @type t :: %__MODULE__{
    type: :syntax | :runtime | :type | :undefined_variable,
    message: String.t(),
    line: integer() | nil,
    column: integer() | nil,
    source_file: String.t() | nil,
    context: map()
  }
end
```

### Phase 2: Parser Implementation with NimbleParsec (Week 2)

#### 2.1 NimbleParsec Setup
```elixir
# mix.exs - Add dependency
defp deps do
  [
    {:nimble_parsec, "~> 1.4"}
  ]
end
```

#### 2.2 Parser Architecture with NimbleParsec
- **Single-pass parsing** using NimbleParsec combinators
- **Context-aware** parsing for different template sections
- **Error recovery** and position tracking
- **Modular combinators** for reusable parsing logic

**Key Design Decisions:**
- Use `choice([])` for alternatives (expressions, tags, comments, text)
- Implement delimiter detection with `string()` combinators  
- Apply `reduce()` functions to transform parser output into AST nodes
- Handle whitespace trimming with optional `-` detection in delimiters

#### 2.3 Expression Parsing Strategy

**Precedence Hierarchy (lowest to highest):**
1. Logical OR (`or`)
2. Logical AND (`and`) 
3. Equality (`==`, `!=`)
4. Relational (`<`, `<=`, `>`, `>=`)
5. Additive (`+`, `-`)
6. Multiplicative (`*`, `/`, `%`)
7. Unary (`not`, `-`)
8. Primary (literals, variables, function calls, parentheses)

**Key Parsing Challenges:**
- **Pipe vs Binary Operations**: Handle `|` as filter pipe, not bitwise OR
- **Variable Path Building**: Support dot notation and bracket access (`user.name`, `items[0]`)
- **Function vs Filter Syntax**: Parse both `func(arg)` and `value | func` identically
- **Whitespace Handling**: Allow flexible spacing around operators
- **Number Parsing**: Distinguish integers, floats, and scientific notation

#### 2.4 Tag Parsing Strategy

**Tag Categories:**
- **Control Flow**: `if/elsif/else/endif`, `for/endfor`
- **Utility**: `assign`
- **Comments**: `{# ... #}` (ignored during parsing)

**Block Structure Challenge:**
- Parse tags individually first, then post-process into nested blocks
- Use a separate `BlockParser` module to collect tag sequences
- Handle nested blocks (if inside for, etc.) with proper scoping

**For Loop Options:**
- Support `limit:` and `offset:` modifiers
- Parse as optional keyword list after collection expression

### Phase 3: AST Transformation and Validation

#### 3.1 AST Node Construction Strategy
- Create helper functions to transform NimbleParsec output into spec-compliant AST
- Follow the unified tuple format: `{type, parts, opts}`
- Include position tracking and trim options in node metadata

#### 3.2 NimbleParsec Reducer Strategy
- Use reducer functions to transform parsed tokens into AST nodes
- Handle operator precedence in `build_binary_op/1` reducer
- Convert pipe chains into nested function calls in `build_pipe_chain/1`
- Extract trim options from delimiter parsing
- Properly distinguish integers from floats in number parsing

#### 3.3 Block Structure Strategy
- **Two-phase approach**: Parse tags individually, then post-process into nested blocks
- **If/Elsif/Else handling**: Collect condition-body pairs until `endif`
- **For loop handling**: Collect body content until `endfor`
- **Nested block support**: Handle if statements inside for loops, etc.
- **Error recovery**: Handle mismatched or missing end tags gracefully

### Phase 4: Evaluator/Renderer Implementation

#### 4.1 Context Management Strategy
- Maintain variable state with scoping support
- Handle strict vs ease modes for undefined variables
- Support loop context isolation and forloop metadata
- Efficient context updates for assignments

#### 4.2 Expression Evaluation Strategy
- Pattern match on AST node types for dispatch
- Implement recursive evaluation for nested expressions
- Handle type coercion and error propagation
- Support variable path traversal with bounds checking

#### 4.3 Template Rendering Strategy
- Unified tag interface: `render_tag(tag_name, params, opts, context)`
- Clear separation between evaluation and rendering
- Support for pure expressions vs mixed content detection
- Handle whitespace control during rendering

### Phase 5: Filter System

#### 5.1 Filter Registry Strategy
- Dynamic filter registration system
- Built-in filter loading at startup
- Filter categorization (string, number, collection, math)
- Error handling for unknown filters

#### 5.2 Built-in Filter Categories
- **String filters**: upper_case, lower_case, capitalize, truncate, default
- **Number filters**: round, format_currency
- **Collection filters**: length, first, last, join, sort, reverse, uniq
- **Math filters**: abs, ceil, floor, max, min, power, sqrt, mod, clamp

### Phase 6: Public API Implementation

#### 6.1 Main Module Implementation Strategy
- **Compile function**: Parse template → transform to AST → validate/extract warnings
- **Render function**: Detect template type (pure expression vs mixed) → evaluate/render accordingly
- **Render_map function**: Recursively process nested maps, rendering template strings
- **Error handling**: Structured error returns with position information

#### 6.2 Template Detection Strategy
- **Pure expression detection**: Single expression node in AST
- **Template syntax detection**: Check for `{{`, `{%`, or `{#` delimiters
- **Mixed content handling**: Default to string output for templates with text

## Testing Strategy

### Unit Tests
- Parser combinators for each syntax element
- Expression evaluation with various data types
- Built-in filters with edge cases
- Error handling scenarios

### Integration Tests
- Full pipeline: Template string → AST → rendered output
- Context handling: Variable scoping, assignments, loops
- Edge cases: Malformed templates, missing variables

## Performance Considerations

### Optimization Strategies
1. **AST Caching**: Cache compiled templates by content hash
2. **Context Pooling**: Reuse context objects for similar renders
3. **Filter Memoization**: Cache expensive filter operations
4. **Tail Call Optimization**: Optimize recursive AST traversal

### Memory Management
- **Streaming**: Support for large template processing
- **Lazy Evaluation**: Defer complex operations when possible
- **Resource Limits**: Configurable limits for recursion depth, loop iterations

## Incremental Implementation by Template Feature Groups

### Development Approach
- **Test-Driven Development**: Each feature group requires 100% passing tests before moving to next
- **Incremental Building**: Each group builds upon previous groups
- **Parser + Evaluator**: Implement both parsing and evaluation for each group
- **Comprehensive Testing**: Unit tests, integration tests, and edge cases for each group

### Group 1: Text and Basic Infrastructure
**Goal**: Handle plain text templates and basic project setup

**Features:**
- Plain text rendering (no template syntax)
- Project structure and dependencies
- Error handling framework
- Basic AST structure

**Implementation Focus:**
- Basic text parsing without template syntax
- Project setup with NimbleParsec dependency
- Error handling framework

**Test Cases:**
- Plain text rendering
- Text with special characters
- Empty text
- Multiline text

---

### Group 2: Literal Expressions
**Goal**: Parse and evaluate literal values in expressions

**Features:**
- String literals: `{{ "hello" }}`, `{{ 'world' }}`
- Number literals: `{{ 42 }}`, `{{ 3.14 }}`, `{{ -17 }}`
- Boolean literals: `{{ true }}`, `{{ false }}`
- Null literals: `{{ null }}`, `{{ nil }}`

**Implementation Focus:**
- Expression block parsing with `{{` and `}}`
- Literal value parsing (strings, numbers, booleans, null)
- Type preservation and conversion logic

**Test Cases:**
- String literals (double/single quotes, escapes)
- Number literals (integers, floats, scientific notation)
- Boolean literals (true/false)
- Null literals (null/nil)
- Mixed content with literals
- Pure expression vs mixed content detection

---

### Group 3: Variable Expressions
**Goal**: Parse and evaluate variable access with path traversal

**Features:**
- Simple variables: `{{ name }}`, `{{ $input }}`
- Object property access: `{{ user.name }}`, `{{ $input.email }}`
- Nested property access: `{{ user.profile.settings.theme }}`
- Array indexing: `{{ users[0] }}`, `{{ items[index] }}`
- Mixed access: `{{ $nodes.api_call.response.data.users[0].name }}`

**Implementation Focus:**
- Variable path parsing with dot notation and bracket access
- Context lookup with nested property traversal
- Array indexing with bounds checking
- Strict vs ease mode error handling

**Test Cases:**
- Simple variables and workflow variables with $ prefix
- Object property access and nested properties
- Array indexing (positive, negative, out of bounds)
- Dynamic indexing with variables
- Complex workflow paths ($nodes, $input, etc.)
- Mixed variable and literal content
- Type preservation in pure expressions
- Error handling for undefined variables in strict/ease modes

---

### Group 4: Arithmetic Expressions
**Goal**: Parse and evaluate arithmetic operations with proper precedence

**Features:**
- Basic operators: `+`, `-`, `*`, `/`, `%`
- Operator precedence: `*` and `/` before `+` and `-`
- Parentheses: `{{ (a + b) * c }}`
- String concatenation: `{{ "Hello " + name }}`
- Mixed operands: `{{ count + 1 }}`

**Implementation Focus:**
- Precedence climbing parser for arithmetic operations
- Support for parentheses and unary operators
- String concatenation with + operator
- Division by zero error handling

**Test Cases:**
- Basic arithmetic operations (+, -, *, /, %)
- Float arithmetic
- Operator precedence and left associativity
- Parentheses overriding precedence
- Unary minus
- String concatenation with + operator
- Mixed type concatenation
- Variables in arithmetic expressions
- Error cases (division by zero, invalid operations)
- Arithmetic in mixed content

---

### Group 5: Boolean and Comparison Expressions
**Goal**: Parse and evaluate boolean logic and comparison operations

**Features:**
- Comparison operators: `==`, `!=`, `>`, `>=`, `<`, `<=`
- Logical operators: `and`, `or`, `not`
- Boolean evaluation in different contexts
- Truthiness rules for non-boolean values

**Test Cases:**
- Comparison operations (==, !=, >, >=, <, <=)
- Logical operations (and, or, not)
- Complex boolean expressions with variables
- Truthiness rules for different value types
- Short-circuit evaluation

---

### Group 6: Filter Expressions
**Goal**: Parse and evaluate filter applications

**Features:**
- Pipe syntax: `{{ name | upper_case }}`
- Function syntax: `{{ upper_case(name) }}`
- Filters with arguments: `{{ text | truncate(50) }}`
- Chained filters: `{{ name | upper_case | truncate(10) }}`

**Test Cases:**
- Basic filters (upper_case, lower_case, capitalize)
- Filters with arguments (truncate, round)
- Chained filters
- Function call syntax vs pipe syntax
- Built-in filter categories (string, number, collection, math)

---

### Group 7: Assignment Tags
**Goal**: Parse and evaluate assignment operations

**Features:**
- Basic assignment: `{% assign name = "value" %}`
- Expression assignment: `{% assign total = price + tax %}`
- Assignment with variable scope

---

### Group 8: Conditional Tags
**Goal**: Parse and evaluate if/elsif/else constructs

**Features:**
- Simple if: `{% if condition %}...{% endif %}`
- If/else: `{% if condition %}...{% else %}...{% endif %}`
- If/elsif/else chains

---

### Group 9: Loop Tags
**Goal**: Parse and evaluate for loops

**Features:**
- Basic loops: `{% for item in items %}...{% endfor %}`
- Loop with options: `{% for item in items limit: 5 %}...{% endfor %}`
- Loop variables (forloop.index, etc.)

---

### Group 10: Whitespace Control
**Goal**: Handle whitespace trimming

**Features:**
- Trim left: `{{- expression }}`, `{%- tag %}`
- Trim right: `{{ expression -}}`, `{% tag -%}`
- Complex whitespace scenarios

---

### Implementation Rules

**Before starting each group:**
1. Write test cases for the group features
2. Implement parser changes needed
3. Implement evaluator changes needed
4. Run tests until all pass
5. Only move to next group when 100% tests pass

**Each group deliverables:**
- Parser combinators for new syntax
- Evaluator functions for new operations  
- Test coverage for all features
- Updated AST node types if needed

## Success Criteria

1. **API Compliance**: All three methods work as specified
2. **Syntax Support**: Full Prana template language implementation
3. **Error Handling**: Graceful degradation and helpful error messages
4. **Performance**: Handle templates up to 1MB with reasonable performance
5. **Test Coverage**: >95% code coverage with comprehensive edge case testing
6. **Documentation**: Complete API documentation with examples

## Risk Mitigation

### Technical Risks
- **Parser Complexity**: Start with simple recursive descent, optimize later
- **Performance**: Implement basic version first, profile and optimize
- **Memory Usage**: Add streaming support if needed

### Implementation Risks
- **Scope Creep**: Strictly follow AST specification
- **Timeline**: Prioritize core functionality over advanced features
- **Quality**: Implement comprehensive testing from day one