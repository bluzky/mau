# Changelog

All notable changes to the Mau template engine project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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