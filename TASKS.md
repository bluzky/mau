# Mau Template Engine - Task Breakdown

## Group 1: Text and Basic Infrastructure ✅ COMPLETED

### Task 1.1: Project Setup and Dependencies ✅
- [x] Add NimbleParsec dependency to mix.exs
- [x] Create basic project structure
- [x] Set up test framework configuration
- [x] Create basic module stubs

### Task 1.2: Error Handling System ✅
- [x] Create `Mau.Error` struct
- [x] Define error types (syntax, runtime, type, undefined_variable)
- [x] Create error formatting helpers
- [x] Write unit tests for error handling

### Task 1.3: Basic AST Node Structure ✅
- [x] Create `Mau.AST.Nodes` module
- [x] Implement `text_node/2` helper
- [x] Define basic AST node validation
- [x] Write tests for AST node creation

### Task 1.4: Plain Text Parser ✅
- [x] Create basic `Mau.Parser` module with NimbleParsec
- [x] Implement `text_content` parser combinator
- [x] Implement `template` parser that handles plain text only
- [x] Write parser tests for plain text

### Task 1.5: Basic Renderer ✅
- [x] Create `Mau.Renderer` module
- [x] Implement `render_node/2` for text nodes
- [x] Create context management basics
- [x] Write renderer tests for text nodes

### Task 1.6: Main API Skeleton ✅
- [x] Create main `Mau` module
- [x] Implement basic `render/3` function (text-only)
- [x] Add template type detection (pure vs mixed)
- [x] Write integration tests for plain text rendering

---

## Group 2: Literal Expressions ✅ COMPLETED

### Task 2.1: String Literal Parser ✅
- [x] Implement `string_literal` combinator for double quotes
- [x] Implement `string_literal` combinator for single quotes
- [x] Add escape sequence handling (including Unicode \uXXXX)
- [x] Write tests for string parsing edge cases (9 comprehensive tests)

### Task 2.2: Number Literal Parser ✅
- [x] Implement `number_literal` combinator for integers
- [x] Add float number support
- [x] Add scientific notation support (e/E with +/- exponents)
- [x] Add negative number support
- [x] Create `parse_number/1` reducer function
- [x] Write tests for all number formats (10 comprehensive tests)

### Task 2.3: Boolean and Null Literal Parser ✅
- [x] Implement `boolean_literal` combinator
- [x] Implement `null_literal` combinator
- [x] Write tests for boolean and null values (7 comprehensive tests)

### Task 2.4: Expression Block Parser ✅
- [x] Implement `expression` combinator with `{{` and `}}`
- [x] Add whitespace handling inside expressions (spaces, tabs, newlines)
- [x] Combine all literal parsers in `literal_expression`
- [x] Write tests for expression block parsing (8 comprehensive tests)

### Task 2.5: Literal Expression Evaluator ✅
- [x] Implement `evaluate_expression/2` for literal nodes
- [x] Create literal AST node builders
- [x] Add type preservation logic and value formatting
- [x] Write tests for literal evaluation (9 comprehensive tests)

### Task 2.6: Expression Rendering Integration ✅
- [x] Update `render_node/2` for expression nodes
- [x] Add mixed content parsing and rendering (text + expressions)
- [x] Implement multi-node AST rendering system
- [x] Write integration tests for literal expressions (11 comprehensive scenarios)

---

## Group 3: Variable Expressions ✅ COMPLETED

### Task 3.1: Identifier Parser ✅
- [x] Implement `identifier` combinator for basic identifiers
- [x] Support `$` prefix for workflow variables (`$input`, `$variables`, etc.)
- [x] Add underscore and number support in identifiers
- [x] Write tests for identifier parsing (10 comprehensive tests)

### Task 3.2: Property Access Parser ✅
- [x] Implement dot notation parser (`.property`) with `build_property_access/1`
- [x] Add property access to variable expression with `variable_access` combinator
- [x] Support nested property access (`user.profile.email`)
- [x] Write tests for property access parsing (10 comprehensive tests)

### Task 3.3: Array Index Parser ✅
- [x] Implement `array_index` combinator with `[` and `]` delimiters
- [x] Support literal number indices `[0]`, `[123]`
- [x] Support variable indices `[index]`, `[i]` (simple identifiers)
- [x] Add whitespace handling within brackets `[ 0 ]`
- [x] Write tests for array indexing (11 comprehensive tests)

### Task 3.4: Variable Path Builder ✅
- [x] Create `build_variable_path/1` reducer combining all access types
- [x] Combine identifiers, properties, and indices in unified path structure
- [x] Create variable AST nodes using `Nodes.variable_node/2`
- [x] Support complex mixed access patterns (`user.orders[0].name`)
- [x] Write tests for complex path building (integrated with property/array tests)

### Task 3.5: Variable Evaluator ✅
- [x] Implement `extract_variable_value/2` with recursive path traversal
- [x] Add context lookup for simple variables with `Map.get/2`
- [x] Add property traversal logic for nested maps
- [x] Add array indexing with bounds checking using `Enum.at/2`
- [x] Handle undefined variables gracefully (return nil/empty string)
- [x] Support workflow variables with `$` prefix
- [x] Write comprehensive variable evaluation tests (14 comprehensive scenarios)

### Task 3.6: Variable Integration ✅
- [x] Update main parser to include variable expressions in `expression_value`
- [x] Update renderer to handle variable nodes with `evaluate_expression/2`
- [x] Add variable support to expression block parser
- [x] Update expression parsing to handle both literals and variables
- [x] Write integration tests for variables (14 comprehensive scenarios)
- [x] Update existing tests to handle new variable capabilities

---

## Group 4: Arithmetic Expressions ✅ COMPLETED

### Task 4.1: Operator Precedence Setup ✅
- [x] Design precedence levels for arithmetic operators
- [x] Create parser structure for precedence climbing
- [x] Write tests for precedence expectations

### Task 4.2: Additive Expression Parser ✅
- [x] Implement `additive_expression` combinator (`+`, `-`)
- [x] Add whitespace handling around operators
- [x] Create `build_binary_operation/1` reducer for left-associative operations
- [x] Write tests for addition and subtraction (17 comprehensive parser tests)

### Task 4.3: Multiplicative Expression Parser ✅
- [x] Implement `multiplicative_expression` combinator (`*`, `/`, `%`)
- [x] Ensure higher precedence than additive
- [x] Write tests for multiplication, division, modulo

### Task 4.4: Unary Expression Parser ✅
- [x] Determined unary minus redundant due to existing negative number parsing
- [x] Simplified arithmetic precedence chain without unary layer
- [x] Maintained compatibility with existing negative number literals

### Task 4.5: Parentheses Support ✅
- [x] Add parentheses to `primary_expression`
- [x] Ensure parentheses override precedence using recursive `parsec(:additive_expression)`
- [x] Write tests for nested parentheses

### Task 4.6: Arithmetic Evaluator ✅
- [x] Implement binary operation evaluation for all arithmetic operators
- [x] Add number arithmetic (`+`, `-`, `*`, `/`, `%`)
- [x] Add string concatenation with `+`
- [x] Add mixed type concatenation with automatic type conversion
- [x] Add division by zero and modulo by zero error handling
- [x] Add graceful nil handling (undefined variables as empty strings)
- [x] Write comprehensive arithmetic evaluation tests (19 comprehensive tests)

### Task 4.7: Parser Integration ✅
- [x] Update `expression_value` to use arithmetic parsing (`additive_expression`)
- [x] Ensure variables work seamlessly in arithmetic expressions
- [x] Support complex variable paths in arithmetic (`user.age * 2`)
- [x] Support workflow variables in arithmetic operations
- [x] Write integration tests for arithmetic with variables (17 end-to-end scenarios)

---

## Group 5: Boolean and Comparison Expressions ✅ COMPLETED

### Task 5.1: Comparison Operator Parser ✅
- [x] Implement `equality_expression` for `==`, `!=`
- [x] Implement `relational_expression` for `>`, `>=`, `<`, `<=`
- [x] Ensure proper precedence (after arithmetic, before logical)
- [x] Write tests for comparison parsing (11 comprehensive tests)
- [x] Add word boundary detection to prevent keyword conflicts with variables

### Task 5.2: Logical Operator Parser ✅
- [x] Implement `logical_and_expression` for `and` 
- [x] Implement `logical_or_expression` for `or`
- [x] Determined `not` operator not needed for current scope
- [x] Ensure proper precedence (AND before OR, lowest overall)
- [x] Write tests for logical operator parsing (integrated with comparison tests)
- [x] Implement left-associative operation building for logical expressions

### Task 5.3: Boolean Expression Evaluator ✅
- [x] Implement comparison operations (`==`, `!=`, `>`, `>=`, `<`, `<=`)
- [x] Support number comparisons and string comparisons
- [x] Implement logical operations (`and`, `or`) with short-circuit evaluation
- [x] Add comprehensive truthiness evaluation rules (nil, false, "", 0, 0.0, [], %{} are falsy)
- [x] Add short-circuit evaluation for `and`/`or` for performance optimization
- [x] Write comprehensive boolean evaluation tests (18 comprehensive tests)
- [x] Handle mixed-type equality checking and error cases

### Task 5.4: Precedence Integration ✅
- [x] Update parser precedence chain: Parentheses > Arithmetic > Comparison > Logical
- [x] Resolve circular dependency in parser using `defcombinatorp`
- [x] Ensure all operators work together correctly with proper precedence
- [x] Write complex expression integration tests (17 end-to-end scenarios)
- [x] Test expressions like: `{{ (2 + 3) > 4 and user.age >= 18 }}`

### Task 5.5: Word Boundary Parsing ✅
- [x] Fix keyword parsing conflicts between literals and variables
- [x] Implement `lookahead_not` for boolean and null literals
- [x] Ensure variables like `null_value`, `true_flag` parse correctly
- [x] Test and validate parsing precedence order

### Task 5.6: Warning Fixes and Code Quality ✅
- [x] Fix all unused variable warnings in test files
- [x] Use pin operator `^` for proper pattern matching in tests
- [x] Ensure all 260 tests pass without warnings
- [x] Clean compilation with no compiler warnings

---

## Group 6: Filter Expressions ✅ COMPLETED

### Task 6.1: Filter Registry System ✅
- [x] Create `Mau.FilterRegistry` module with static compile-time storage
- [x] Add filter registration mechanism (static module attribute)
- [x] Create built-in filter loading (25 built-in filters)
- [x] Write tests for filter registry (20 comprehensive test scenarios)

### Task 6.2: Pipe Syntax Parser ✅
- [x] Implement pipe operator `|` in expressions at top expression level
- [x] Add filter name parsing after pipe with identifier parsing
- [x] Handle chained filters `value | filter1 | filter2`
- [x] Write tests for pipe syntax parsing (6 comprehensive test scenarios)

### Task 6.3: Function Call Syntax Parser ✅
- [x] Add function call support to atom expressions
- [x] Parse function arguments `func(arg1, arg2)` with `argument_list` combinator
- [x] Create `argument_list` combinator with primary expressions
- [x] Write tests for function call parsing (6 comprehensive test scenarios)

### Task 6.4: Filter Chain Builder ✅
- [x] Create `build_pipe_chain/1` reducer for nested call expressions
- [x] Convert pipe chains to nested call expressions automatically
- [x] Handle both pipe and function syntax seamlessly
- [x] Write tests for filter chain building (integrated in parser tests)

### Task 6.5: Built-in String Filters ✅
- [x] Implement `upper_case`, `lower_case`, `capitalize` with type conversion
- [x] Implement `truncate` with length argument and bounds checking
- [x] Implement `default` filter for fallback values
- [x] Write tests for string filters (comprehensive doctest coverage)

### Task 6.6: Built-in Number Filters ✅
- [x] Implement `round` with precision argument
- [x] Implement `format_currency` with symbol support and thousands separator
- [x] Write tests for number filters (comprehensive doctest coverage)

### Task 6.7: Built-in Collection Filters ✅
- [x] Implement `length`, `first`, `last` for collections and strings
- [x] Implement `join` with separator argument
- [x] Implement `sort`, `reverse`, `uniq` for list manipulation
- [x] Write tests for collection filters (comprehensive doctest coverage)

### Task 6.8: Filter Evaluation Engine ✅
- [x] Implement `evaluate_call/3` for filter calls in renderer
- [x] Add argument evaluation with recursive expression evaluation  
- [x] Add filter application logic via FilterRegistry.apply/3
- [x] Handle filter errors gracefully with structured error messages
- [x] Write comprehensive filter evaluation tests (15 test scenarios)

### Additional Achievements ✅
- [x] **Math Filters**: Added 9 additional math filters (`abs`, `ceil`, `floor`, `max`, `min`, `power`, `sqrt`, `mod`, `clamp`)
- [x] **Error Handling**: Comprehensive error handling for unknown filters and filter execution errors  
- [x] **Performance**: Static compile-time filter registry (no GenServer overhead)
- [x] **Parser Integration**: Seamless integration with existing expression precedence system
- [x] **Test Coverage**: 291 tests + 32 doctests all passing
- [x] **Documentation**: Complete API documentation with examples for all filters

---

## Group 7: Assignment Tags ✅ COMPLETED

### Task 7.1: Tag Block Parser Foundation ✅
- [x] Create tag parsing infrastructure with `{%` and `%}`
- [x] Add tag content parsing
- [x] Implement basic tag structure
- [x] Write tests for tag block parsing

### Task 7.2: Assignment Tag Parser ✅
- [x] Implement `assign_tag` combinator
- [x] Parse variable name and assignment expression
- [x] Handle whitespace around `=` operator
- [x] Write tests for assignment parsing

### Task 7.3: Assignment Tag Evaluator ✅
- [x] Implement assignment tag rendering
- [x] Add variable assignment to context
- [x] Handle assignment expression evaluation
- [x] Write tests for assignment evaluation

### Task 7.4: Context Management ✅
- [x] Update context handling for assignments
- [x] Add variable scoping rules
- [x] Ensure assignments persist in template
- [x] Write integration tests for assignments

---

## Group 8: Conditional Tags ✅ COMPLETED

### Task 8.1: If Tag Parser ✅
- [x] Implement `if_tag` combinator
- [x] Parse condition expression after `if`
- [x] Write tests for if tag parsing

### Task 8.2: Elsif and Else Tag Parser ✅
- [x] Implement `elsif_tag` and `else_tag` combinators
- [x] Implement `endif_tag` combinator
- [x] Write tests for conditional tag parsing

### Task 8.3: Block Structure Builder ✅
- [x] Create `Mau.BlockProcessor` module
- [x] Implement `collect_conditional_block/6` function
- [x] Build nested if/elsif/else structure
- [x] Write tests for block structure building

### Task 8.4: Conditional Tag Evaluator ✅
- [x] Implement `render_conditional_block/2` for conditional blocks
- [x] Add condition evaluation and branching
- [x] Handle multiple elsif clauses
- [x] Add else clause support
- [x] Write comprehensive conditional evaluation tests

### Task 8.5: Conditional Integration ✅
- [x] Update main parser to handle conditional blocks
- [x] Add conditional support to template parsing
- [x] Write integration tests for conditionals

---

## Group 9: Loop Tags ✅ COMPLETED

### Task 9.1: For Tag Parser ✅
- [x] Implement `for_tag` combinator
- [x] Parse loop variable and collection expression
- [x] Add `in` keyword parsing
- [x] Write tests for for tag parsing

### Task 9.2: Loop Options Parser (Deferred)
- [ ] Implement `for_options` combinator
- [ ] Add `limit:` and `offset:` option parsing
- [ ] Write tests for loop options

### Task 9.3: Loop Block Structure ✅
- [x] Add for loop to block structure builder
- [x] Implement proper for/endfor matching with nested loop support
- [x] Create nested loop AST structure
- [x] Write tests for loop block building

### Task 9.4: Loop Context Management ✅
- [x] Create loop variable context handling
- [x] Add loop metadata (forloop.index, first, last, length, rindex)
- [x] Implement context isolation for loops with parentloop support
- [x] Write tests for loop context

### Task 9.5: Loop Evaluator ✅
- [x] Implement loop block rendering for all collection types
- [x] Add collection evaluation and iteration (arrays, maps, strings)
- [x] Handle empty collections and nil values gracefully
- [x] Write comprehensive loop evaluation tests

### Task 9.6: Loop Variables ✅
- [x] Add `forloop` object to loop context
- [x] Implement index, first, last properties (0-based indexing)
- [x] Add length and reverse index properties
- [x] Add parentloop support for nested loop access
- [x] Write tests for loop variables including parentloop access

---

## Group 10: Whitespace Control

### Task 10.1: Trim Token Parser
- [ ] Add trim detection to expression delimiters
- [ ] Parse `{{-` and `-}}` variants
- [ ] Parse `{%-` and `-%}` variants
- [ ] Write tests for trim token parsing

### Task 10.2: Trim Options in AST
- [ ] Add `trim_left` and `trim_right` to AST options
- [ ] Update all expression and tag node builders
- [ ] Write tests for trim options in AST

### Task 10.3: Whitespace Processor
- [ ] Create `apply_whitespace_control/1` function
- [ ] Implement trim logic for adjacent text nodes
- [ ] Handle complex trim scenarios
- [ ] Write tests for whitespace processing

### Task 10.4: Trim Integration
- [ ] Add whitespace processing to main rendering pipeline
- [ ] Ensure trim works with all expression and tag types
- [ ] Write comprehensive whitespace control tests

---

## Implementation Workflow

### For Each Task:
1. **Create branch**: `feature/task-X.Y`
2. **Write tests first**: Add failing tests
3. **Implement**: Make tests pass
4. **Refactor**: Clean up implementation
5. **Commit**: Single focused commit
6. **Test integration**: Ensure no regressions

### For Each Group:
1. **Complete all tasks** in the group
2. **Run full test suite** for the group
3. **Write integration tests** that combine group features
4. **Update documentation** for new features
5. **Tag release**: `v0.1.0-group-X`
6. **Only proceed** when 100% tests pass

### Quality Gates:
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Code coverage > 95%
- [ ] No compiler warnings
- [ ] Documentation updated
- [ ] Performance benchmarks (for Groups 4+)

This breakdown provides **88 specific, actionable tasks** organized into 10 groups, with clear success criteria and workflow for each task and group.