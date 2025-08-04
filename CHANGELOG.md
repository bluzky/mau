# Changelog

All notable changes to the Mau template engine project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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