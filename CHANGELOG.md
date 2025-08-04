# Changelog

All notable changes to the Mau template engine project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Group 10: Whitespace Control** - Complete implementation
  - **Task 10.1: Trim Token Parser** - Complete trim detection for expressions and tags
    - Expression trim parsing: `{{-`, `-}}`, `{{-` `-}}`
    - Tag trim parsing: `{%-`, `-%}`, `{%-` `-%}` 
    - Support for left trim, right trim, and both trim combinations
    - Integration with existing expression and tag parsing infrastructure
  - **Task 10.2: AST Trim Options** - Complete trim option integration
    - `trim_left` and `trim_right` options added to AST node structures
    - All expression and tag builder functions support trim options
    - Maintains unified AST structure convention `{type, parts, opts}`
  - **Task 10.3: Whitespace Processor** - Complete trim logic implementation  
    - `Mau.WhitespaceProcessor` module for whitespace control
    - Trims adjacent text nodes based on trim options
    - Handles left trim (trailing whitespace removal) and right trim (leading whitespace removal)
    - Supports complex whitespace including newlines, tabs, and multiple spaces
    - Graceful handling of empty text nodes and non-text adjacent nodes
  - **Task 10.4: Pipeline Integration** - Complete rendering pipeline integration
    - Whitespace processing integrated into main `Mau.render/3` function
    - Applied before block processing to preserve trim information from individual tags
    - Works seamlessly with expressions, tags, conditionals, and loops
    - Zero performance impact when no trim options are used

### Technical Details
- Extended parser with trim token detection using NimbleParsec choice combinators
- Expression trim AST nodes: `{:expression, [...], [trim_left: true, trim_right: true]}`
- Tag trim AST nodes: `{:tag, [...], [trim_left: true, trim_right: true]}`
- Whitespace processor applies `String.trim_trailing/1` and `String.trim_leading/1` to adjacent text nodes
- Integrated before block processing to handle individual tag trim options correctly
- Maintains backward compatibility - templates without trim tokens work unchanged

### Testing
- All tests pass (472 tests: 56 doctests + 416 unit tests)
- New whitespace parser test suite (12 comprehensive parsing tests)
- New whitespace processor test suite (11 whitespace logic tests including 1 doctest)
- New whitespace integration test suite (13 end-to-end scenarios)
- Comprehensive trim token parsing with all combinations (left, right, both, none)
- Full template rendering with whitespace control for expressions, tags, conditionals, and loops
- Complex whitespace handling tests including newlines, tabs, and mixed content

### Added
- **Group 9: Loop Tags** - Complete implementation
  - **Task 9.1: For Tag Parser** - Complete for tag parsing with loop variable and collection expressions
    - `for` tag combinator parsing with `{%` and `%}` delimiters
    - Support for variable collections: `{% for item in items %}`
    - Support for string collections: `{% for char in "abc" %}`
    - Support for complex expressions: `{% for user in users | sort %}`
    - Support for property access: `{% for order in user.orders %}`
    - Integration with full expression system (variables, filters, functions)
  - **Task 9.2: Endfor Tag Parser** - Complete loop termination parsing
    - `endfor` tag combinator for loop block termination
    - Integrated into generic tag parsing infrastructure
  - **Task 9.3: Loop Block Structure** - Complete nested loop processing
    - Extended `Mau.BlockProcessor` to handle for/endfor loop blocks
    - Proper depth counting for matching nested for/endfor pairs
    - Recursive processing of nested conditionals within loop content
    - Loop block AST structure: `{:loop_block, [loop_variable: "item", collection_expression: {...}, content: [...]]}`
  - **Task 9.4: Loop Context Management** - Complete forloop variables and parent loop preservation
    - Full forloop variable support: `index`, `first`, `last`, `length`, `rindex`
    - Parent loop context preservation via `forloop.parentloop` for nested loops
    - Context isolation ensuring inner loops don't interfere with outer loops
    - 0-based indexing system for consistency
  - **Task 9.5: Loop Evaluation Engine** - Complete collection iteration and rendering
    - Support for multiple collection types: arrays, maps (as key-value pairs), strings (as characters)
    - Graceful handling of empty collections, nil values, and missing variables
    - Error handling for non-iterable collections
    - Context-aware rendering maintaining variable assignments within loops
  - **Task 9.6: Comprehensive Test Coverage** - Complete testing infrastructure
    - Loop parser test suite (10 comprehensive parsing tests)
    - Loop integration test suite (22 end-to-end functionality tests)
    - Nested loop testing with parentloop access verification
    - Error handling tests for malformed syntax and invalid collections

### Technical Details
- Extended parser with for/endfor tag combinators supporting `{%` for/endfor `%}` syntax
- Loop AST nodes: `{:tag, [:for/:endfor, ...], opts}` and `{:loop_block, [...], opts}`
- Enhanced block processor with nested loop depth counting and recursive content processing
- Loop rendering system with `render_loop_block_with_context/2` functions
- Parent loop context preservation preventing context collision in nested loops
- Multiple collection type support with automatic type conversion
- Maintains unified AST structure convention `{type, parts, opts}`

### Testing
- All tests pass (436 tests: 55 doctests + 381 unit tests)
- New loop parser test suite (10 comprehensive parsing tests)
- New loop integration test suite (22 end-to-end scenarios including nested loops)
- Comprehensive forloop variable testing with parentloop access verification
- Full template rendering with loop content, conditionals, and variable assignments
- Error handling tests for unclosed loops and invalid collection types

- **Group 8: Conditional Tags** - Complete implementation
  - **Task 8.1: If Tag Parser** - Complete if tag parsing with condition expressions
    - `if` tag combinator parsing with `{%` and `%}` delimiters
    - Support for variable conditions: `{% if user.active %}`
    - Support for literal conditions: `{% if true %}`
    - Support for complex expressions: `{% if age >= 18 and status == "active" %}`
    - Integration with full expression system (arithmetic, comparisons, logical operations)
  - **Task 8.2: Elsif, Else, and Endif Tag Parsers** - Complete conditional tag family
    - `elsif` tag combinator with condition expression parsing
    - `else` tag combinator (no condition required)
    - `endif` tag combinator for block termination
    - All conditional tags integrated into tag content parser
  - **Task 8.3: Block Structure Builder** - Complete conditional processing infrastructure
    - `Mau.BlockProcessor` module for grouping conditional tags into blocks
    - Block collection logic to group if/elsif/else/endif sequences
    - Conditional block AST structure: `{:conditional_block, [if_branch: {...}, elsif_branches: [...], else_branch: ...]}`
    - Error handling for unclosed conditional blocks
  - **Task 8.4: Conditional Tag Evaluator** - Complete conditional rendering logic
    - Conditional block rendering with proper branching evaluation
    - If/elsif/else condition evaluation using existing `is_truthy/1` logic
    - Short-circuit evaluation for elsif branches
    - Context-aware rendering that maintains variable assignments
    - Support for nested content rendering within conditional branches
  - **Task 8.5: Comprehensive Test Coverage** - Complete testing infrastructure
    - Conditional parser test suite (8 comprehensive parsing tests)
    - Conditional integration test suite (7 end-to-end functionality tests)
    - Complex condition parsing with variables, literals, and expressions
    - Full conditional block structure parsing verification

### Technical Details
- Extended parser with conditional tag combinators supporting `{%` if/elsif/else/endif `%}` syntax
- Conditional AST nodes: `{:tag, [:if/:elsif/:else/:endif, condition], opts}`
- Block processor for grouping individual tags into structured conditional blocks
- Conditional rendering system with `render_conditional_block/2` functions
- Integration with existing expression evaluation system for conditions
- Placeholder individual tag rendering for backward compatibility
- Support for complex conditional expressions with full precedence handling

### Testing
- All tests pass (404 tests: 55 doctests + 349 unit tests)
- New conditional parser test suite (8 comprehensive parsing tests)
- New conditional integration test suite (7 end-to-end scenarios)
- Comprehensive condition evaluation with variables and complex expressions
- Full template rendering with conditional content and variable assignments
- Error handling tests for malformed conditional syntax

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