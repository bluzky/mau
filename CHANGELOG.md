# Changelog

All notable changes to the Mau template engine project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Group 7: Assignment Tags** - Complete implementation
  - **Task 7.1: Tag Block Parser Foundation** - Complete tag parsing infrastructure
    - Tag block parsing with `{%` and `%}` delimiters  
    - Integrated tag blocks into main template content parser
    - Tag structure validation and AST node creation
    - Support for mixed content (text, expressions, and tags)
  - **Task 7.2: Assignment Tag Parser** - Complete assignment syntax parsing
    - `assign` tag combinator with variable name and expression parsing
    - Assignment operator `=` parsing with whitespace handling
    - Integration with full expression system (arithmetic, filters, variables)
    - Support for complex assignment expressions: `{% assign result = (price + tax) | round(2) %}`
  - **Task 7.3: Assignment Tag Evaluator** - Complete assignment rendering
    - Assignment tag evaluation that produces no output but updates context
    - Expression evaluation for assignment values with full feature support
    - Error handling for assignment expression failures
    - Integration with existing expression evaluation system
  - **Task 7.4: Context Management** - Complete context update system
    - Context-aware rendering that propagates variable assignments
    - Variable assignment persistence throughout template execution
    - Assignment overwrites existing context variables
    - Support for chained assignments using previously assigned variables

### Technical Details
- Extended parser with tag block combinators supporting `{%` and `%}` syntax
- Assignment AST nodes: `{:tag, [:assign, variable_name, expression], opts}`
- Context-aware rendering system with `render_node_with_context/2` functions
- Assignment tags return empty strings but update rendering context
- Full expression support in assignments: variables, arithmetic, filters, functions
- Integrated with existing precedence system and all expression types
- Tag rendering functions with `render_tag_with_context/3` for stateful operations

### Testing
- All tests pass (334 tests + 32 doctests)
- New tag parser test suite (10 comprehensive parsing tests)
- New assignment tag evaluation test suite (15 evaluation scenarios)
- New assignment integration test suite (18 end-to-end scenarios)
- Comprehensive error handling tests for assignment failures
- Mixed content template testing with assignments, expressions, and text
- Context persistence and variable scoping validation

### Added
- **Group 6: Filter Expressions** - Complete implementation
  - **Task 6.1: Filter Registry System** - Static compile-time filter storage
    - `Mau.FilterRegistry` module with 25 built-in filters
    - Compile-time filter storage using module attributes (no GenServer overhead)
    - Filter application with error handling and graceful fallbacks
  - **Task 6.2: Pipe Syntax Parser** - Complete pipe operator implementation  
    - Pipe operator `|` parsing at top expression level
    - Chained filter support: `{{ "hello" | upper_case | length }}`
    - Seamless integration with existing expression precedence system
  - **Task 6.3: Function Call Syntax Parser** - Complete function call support
    - Function call parsing: `{{ upper_case("hello") }}`
    - Multi-argument function calls: `{{ truncate("text", 5) }}`
    - Argument list parsing with primary expressions
  - **Task 6.4: Filter Chain Builder** - Automatic chain conversion
    - Pipe chains converted to nested call expressions in AST
    - Both pipe and function call syntax supported identically
    - Left-to-right filter application order
  - **Task 6.5-6.7: Built-in Filter Library** - Complete filter collection
    - **String filters**: `upper_case`, `lower_case`, `capitalize`, `truncate`, `default`
    - **Number filters**: `round`, `format_currency` 
    - **Collection filters**: `length`, `first`, `last`, `join`, `sort`, `reverse`, `uniq`
    - **Math filters**: `abs`, `ceil`, `floor`, `max`, `min`, `power`, `sqrt`, `mod`, `clamp`
  - **Task 6.8: Filter Evaluation Engine** - Complete evaluation system
    - Filter evaluation integrated into renderer with `evaluate_call/3`
    - Recursive argument evaluation for complex expressions
    - Comprehensive error handling for unknown filters and execution errors
    - Structured error messages with context information

### Technical Details
- Extended parser with pipe expression combinators and function call support
- Call AST nodes: `{:call, [function_name, args], opts}`
- Static filter registry using module attributes for zero-runtime overhead
- Avoided circular parser dependencies through careful combinator design
- Filter chain conversion to nested call expressions for consistent evaluation
- Comprehensive type conversion and error handling in filter implementations
- Maintains unified AST structure convention `{type, parts, opts}`

### Testing
- All tests pass (291 tests + 32 doctests)
- New filter registry test suite (20 test scenarios)
- New filter parser test suite (12 comprehensive parsing tests)
- New filter evaluator test suite (15 evaluation scenarios)
- Comprehensive filter functionality testing for all 25 built-in filters
- Error condition testing for unknown filters and malformed expressions
- Integration testing with existing arithmetic and boolean expressions

### Added
- **Task 5.1: Comparison Operator Parser** - Complete implementation
  - Equality operators: `==` (equal to), `!=` (not equal to)
  - Relational operators: `>` (greater than), `>=` (greater than or equal), `<` (less than), `<=` (less than or equal)
  - Number comparisons: `{{ 5 > 3 }}`, `{{ 10 >= 10 }}`
  - String comparisons: `{{ "apple" < "banana" }}`
  - Mixed-type equality: `{{ 5 == "5" }}` (evaluates to false)
  - Word boundary detection to prevent keyword conflicts with variables
- **Task 5.2: Logical Operator Parser** - Complete implementation
  - Logical AND operator: `and` with proper precedence
  - Logical OR operator: `or` with lowest precedence
  - Left-associative operation building for logical expressions
  - Proper precedence chain: Arithmetic → Comparison → Logical AND → Logical OR
- **Task 5.3: Boolean Expression Evaluator** - Complete implementation
  - Comparison operation evaluation for all operators (`==`, `!=`, `>`, `>=`, `<`, `<=`)
  - Number and string comparison support
  - Logical operation evaluation with short-circuit logic
  - AND short-circuiting: `false and expression` doesn't evaluate `expression`
  - OR short-circuiting: `true or expression` doesn't evaluate `expression`
- **Task 5.4: Truthiness Evaluation Rules** - Complete implementation
  - Falsy values: `nil`, `false`, `""`, `0`, `0.0`, `[]`, `%{}`
  - All other values are truthy
  - Float zero handling with proper guards
  - Consistent truthiness across logical operations
- **Task 5.5: Precedence Integration** - Complete implementation
  - Complete operator precedence chain: Parentheses > Arithmetic > Comparison > Logical
  - Proper expression parsing order: `2 + 3 > 4 and 1 < 2`
  - Circular dependency resolution in parser using `defcombinatorp`
  - Word boundary parsing for boolean/null literals to avoid variable conflicts
- **Task 5.6: Comprehensive Test Suites** - Complete implementation
  - Boolean parser tests (11 tests): syntax, precedence, complex expressions
  - Boolean evaluator tests (18 tests): comparison logic, logical operations, truthiness
  - Boolean integration tests (17 tests): end-to-end template rendering
  - All existing tests maintain compatibility (260 tests total: 26 doctests + 234 unit tests)

### Technical Details
- Extended NimbleParsec parser with comparison and logical expression combinators
- Logical operation AST nodes: `{:logical_op, [operator, left, right], opts}`
- Short-circuit evaluation implementation for performance optimization
- Word boundary detection using `lookahead_not` for keyword parsing
- Circular dependency resolution using `defcombinatorp` for recursive parsing
- Comprehensive truthiness evaluation with type guards
- Maintains unified AST structure convention `{type, parts, opts}`

### Testing
- All tests pass without warnings (260 tests total: 26 doctests + 234 unit tests)
- New boolean parsing test suite (11 comprehensive tests)
- New boolean evaluation test suite (18 comprehensive tests)
- New boolean integration test suite (17 end-to-end scenarios)
- Fixed all compiler warnings in test files
- Comprehensive precedence and logical operation testing
- Error condition testing for unsupported comparisons
- Mixed content template testing with boolean expressions

- **Task 4.1: Operator Precedence Setup** - Complete implementation
  - Designed arithmetic operator precedence: Parentheses > Multiplicative > Additive
  - Clean precedence chain architecture using NimbleParsec combinators
  - Proper left-associative operation handling
- **Task 4.2: Additive Expression Parser** - Complete implementation
  - Addition (`+`) and subtraction (`-`) operator parsing
  - String concatenation support with `+` operator
  - Mixed type concatenation (string + number, number + string)
  - Whitespace handling around operators
- **Task 4.3: Multiplicative Expression Parser** - Complete implementation
  - Multiplication (`*`), division (`/`), and modulo (`%`) operator parsing
  - Higher precedence than additive operations
  - Proper precedence enforcement in parser combinators
- **Task 4.4: Unary Expression Parser** - Simplified approach
  - Determined unary minus redundant due to existing negative number parsing
  - Streamlined arithmetic precedence chain without unary layer
  - Maintained compatibility with existing negative number literals
- **Task 4.5: Parentheses Support** - Complete implementation
  - Parentheses parsing for precedence override: `(2 + 3) * 4`
  - Nested parentheses support: `((2 + 3) * 4) / 2`
  - Recursive parsing using `parsec(:additive_expression)`
- **Task 4.6: Arithmetic Evaluator** - Complete implementation
  - Binary operation evaluation for all arithmetic operators
  - Number arithmetic: `+`, `-`, `*`, `/`, `%`
  - String concatenation with `+` operator
  - Mixed type concatenation with automatic type conversion
  - Division by zero and modulo by zero error handling
  - Graceful nil handling (undefined variables as empty strings)
- **Task 4.7: Parser Integration** - Complete implementation
  - Arithmetic expressions integrated into main expression parsing system
  - Variables work seamlessly in arithmetic: `user.age * 2`
  - Complex paths in arithmetic: `rates[0] + rates[1]`
  - Mixed content templates with arithmetic expressions
  - Workflow variable support in arithmetic operations

### Technical Details
- Extended NimbleParsec parser with precedence-climbing arithmetic parsing
- Binary operation AST nodes: `{:binary_op, [operator, left, right], opts}`
- Left-associative operation building with `build_left_associative_ops/2`
- Comprehensive arithmetic evaluation in renderer with type coercion
- Error handling for division/modulo by zero and unsupported operations
- Maintains unified AST structure convention `{type, parts, opts}`

### Testing
- All existing tests continue to pass (214 tests total: 26 doctests + 188 unit tests)
- New arithmetic parsing test suite (17 comprehensive tests)
- New arithmetic evaluation test suite (19 comprehensive tests)
- New arithmetic integration test suite (17 end-to-end scenarios)
- Comprehensive precedence and associativity testing
- Error condition testing for all edge cases
- Mixed content template testing with arithmetic expressions
- **Task 3.1: Identifier Parser** - Complete implementation
  - Basic identifier parsing (letters, numbers, underscores)
  - Workflow variable support with `$` prefix (`$input`, `$variables`, etc.)
  - Test suite with 10 comprehensive tests covering all identifier patterns
- **Task 3.2: Property Access Parser** - Complete implementation
  - Dot notation property access parsing (`user.name`, `user.profile.email`)
  - Workflow variable property access (`$input.data.field`)
  - Test suite with 10 comprehensive tests including nested properties
- **Task 3.3: Array Index Parser** - Complete implementation
  - Array index parsing with `[]` notation (`users[0]`, `matrix[1][2]`)
  - Support for both literal integer indices and variable indices
  - Whitespace handling within array index brackets
  - Test suite with 11 comprehensive tests covering all access patterns
- **Task 3.4: Variable Path Builder** - Complete implementation
  - Complex variable path construction combining identifiers, properties, and indices
  - Unified AST structure using `{:variable, path_segments, opts}` format
  - Support for mixed access patterns (`user.orders[0].name`)
- **Task 3.5: Variable Evaluator** - Complete implementation
  - Context-based variable value extraction with path traversal
  - Property access on maps with graceful fallback for undefined properties
  - Array index access with bounds checking
  - Support for nested data structures and complex paths
  - Workflow variable evaluation with `$` prefix support
  - Test suite with 14 comprehensive evaluation scenarios
- **Task 3.6: Variable Integration** - Complete implementation
  - Variable expressions integrated into main expression parsing system
  - Mixed content templates with variables and literals
  - End-to-end parsing and rendering of variable expressions
  - Updated expression block parser to handle both literals and variables
  - Test suite with 14 integration scenarios covering all variable features

### Technical Details
- Extended NimbleParsec parser with variable parsing combinators
- Variable path representation using structured tuples: `{:property, "name"}`, `{:index, 0}`
- Context traversal algorithms for complex nested data access
- Graceful handling of undefined variables and out-of-bounds access
- Maintains unified AST structure convention `{type, parts, opts}`
- Proper separation of parsing, AST construction, and evaluation concerns

### Testing
- All existing tests continue to pass (161 tests total: 26 doctests + 135 unit tests)
- New variable parsing test suites with comprehensive coverage
- Variable evaluation tests covering all access patterns and edge cases
- Integration tests for mixed content templates with variables
- Workflow variable tests for specialized use cases
- Error condition testing for malformed variable syntax

## [0.1.0-group-1] - 2025-08-04

### Added
- **Group 1: Text and Basic Infrastructure** - Complete implementation
- Project setup with NimbleParsec dependency
- Error handling system with structured error types:
  - Syntax errors
  - Runtime errors
  - Type errors
  - Undefined variable errors
- AST node structure with unified tuple format `{type, parts, opts}`
- Basic text node support
- Plain text template parser using NimbleParsec
- Template renderer for text nodes
- Main API with core functions:
  - `compile/2` - Parse template string into AST
  - `render/3` - Render template string or AST with context
  - `render_map/3` - Recursively render template strings in nested maps
- Comprehensive test suite (28 tests, 6 doctests)
- Template syntax detection helpers

### Technical Details
- Unified AST structure: All nodes use `{type, parts, opts}` format
- Clean separation of concerns: Parser → AST → Renderer
- Context-based rendering system
- Graceful error handling with detailed error information
- Support for empty templates and edge cases

### Testing
- 100% test coverage for Group 1 features
- Unit tests for all modules
- Integration tests for end-to-end functionality
- Doctests for API documentation

## [0.0.0] - 2025-08-04

### Added
- Initial project repository
- Basic Elixir project structure
- Documentation framework