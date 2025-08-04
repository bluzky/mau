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

## Group 2: Literal Expressions

### Task 2.1: String Literal Parser
- [ ] Implement `string_literal` combinator for double quotes
- [ ] Implement `string_literal` combinator for single quotes
- [ ] Add escape sequence handling
- [ ] Write tests for string parsing edge cases

### Task 2.2: Number Literal Parser
- [ ] Implement `number_literal` combinator for integers
- [ ] Add float number support
- [ ] Add scientific notation support
- [ ] Add negative number support
- [ ] Create `parse_number/1` reducer function
- [ ] Write tests for all number formats

### Task 2.3: Boolean and Null Literal Parser
- [ ] Implement `boolean_literal` combinator
- [ ] Implement `null_literal` combinator
- [ ] Write tests for boolean and null values

### Task 2.4: Expression Block Parser
- [ ] Implement `expression` combinator with `{{` and `}}`
- [ ] Add whitespace handling inside expressions
- [ ] Combine all literal parsers in `literal_expression`
- [ ] Write tests for expression block parsing

### Task 2.5: Literal Expression Evaluator
- [ ] Implement `evaluate_expression/2` for literal nodes
- [ ] Create literal AST node builders
- [ ] Add type preservation logic
- [ ] Write tests for literal evaluation

### Task 2.6: Expression Rendering Integration
- [ ] Update `render_node/2` for expression nodes
- [ ] Add pure expression vs mixed content detection
- [ ] Implement string conversion for mixed content
- [ ] Write integration tests for literal expressions

---

## Group 3: Variable Expressions

### Task 3.1: Identifier Parser
- [ ] Implement `identifier` combinator
- [ ] Support `$` prefix for workflow variables
- [ ] Add underscore and number support
- [ ] Write tests for identifier parsing

### Task 3.2: Property Access Parser
- [ ] Implement dot notation parser (`.property`)
- [ ] Add property access to variable expression
- [ ] Write tests for property access parsing

### Task 3.3: Array Index Parser
- [ ] Implement `array_index` combinator
- [ ] Support literal number indices `[0]`
- [ ] Support variable indices `[index]`
- [ ] Write tests for array indexing

### Task 3.4: Variable Path Builder
- [ ] Create `build_variable_path/1` reducer
- [ ] Combine identifiers, properties, and indices
- [ ] Create variable AST nodes
- [ ] Write tests for complex path building

### Task 3.5: Variable Evaluator
- [ ] Implement `extract_variable_value/2`
- [ ] Add context lookup for simple variables
- [ ] Add property traversal logic
- [ ] Add array indexing with bounds checking
- [ ] Handle undefined variables (strict vs ease mode)
- [ ] Write comprehensive variable evaluation tests

### Task 3.6: Variable Integration
- [ ] Update main parser to include variable expressions
- [ ] Update renderer to handle variable nodes
- [ ] Add variable support to primary expression parser
- [ ] Write integration tests for variables

---

## Group 4: Arithmetic Expressions

### Task 4.1: Operator Precedence Setup
- [ ] Design precedence levels for arithmetic operators
- [ ] Create parser structure for precedence climbing
- [ ] Write tests for precedence expectations

### Task 4.2: Additive Expression Parser
- [ ] Implement `additive_expression` combinator (`+`, `-`)
- [ ] Add whitespace handling around operators
- [ ] Create `build_binary_op/1` reducer
- [ ] Write tests for addition and subtraction

### Task 4.3: Multiplicative Expression Parser
- [ ] Implement `multiplicative_expression` combinator (`*`, `/`, `%`)
- [ ] Ensure higher precedence than additive
- [ ] Write tests for multiplication, division, modulo

### Task 4.4: Unary Expression Parser
- [ ] Implement `unary_expression` combinator for unary minus
- [ ] Handle negative numbers vs subtraction
- [ ] Write tests for unary operations

### Task 4.5: Parentheses Support
- [ ] Add parentheses to `primary_expression`
- [ ] Ensure parentheses override precedence
- [ ] Write tests for nested parentheses

### Task 4.6: Arithmetic Evaluator
- [ ] Implement binary operation evaluation
- [ ] Add number arithmetic (`+`, `-`, `*`, `/`, `%`)
- [ ] Add string concatenation with `+`
- [ ] Add mixed type concatenation
- [ ] Add division by zero error handling
- [ ] Write comprehensive arithmetic evaluation tests

### Task 4.7: Parser Integration
- [ ] Update `expression_content` to use arithmetic parsing
- [ ] Ensure variables work in arithmetic expressions
- [ ] Write integration tests for arithmetic with variables

---

## Group 5: Boolean and Comparison Expressions

### Task 5.1: Comparison Operator Parser
- [ ] Implement `equality_expression` for `==`, `!=`
- [ ] Implement `relational_expression` for `>`, `>=`, `<`, `<=`
- [ ] Ensure proper precedence (after arithmetic, before logical)
- [ ] Write tests for comparison parsing

### Task 5.2: Logical Operator Parser
- [ ] Implement `logical_and_expression` for `and`
- [ ] Implement `logical_or_expression` for `or`
- [ ] Implement `not` in unary expressions
- [ ] Ensure proper precedence (lowest)
- [ ] Write tests for logical operator parsing

### Task 5.3: Boolean Expression Evaluator
- [ ] Implement comparison operations (`==`, `!=`, `>`, etc.)
- [ ] Implement logical operations (`and`, `or`, `not`)
- [ ] Add truthiness evaluation rules
- [ ] Add short-circuit evaluation for `and`/`or`
- [ ] Write comprehensive boolean evaluation tests

### Task 5.4: Precedence Integration
- [ ] Update parser precedence chain
- [ ] Ensure all operators work together correctly
- [ ] Write complex expression integration tests

---

## Group 6: Filter Expressions

### Task 6.1: Filter Registry System
- [ ] Create `Mau.FilterRegistry` module
- [ ] Add filter registration mechanism
- [ ] Create built-in filter loading
- [ ] Write tests for filter registry

### Task 6.2: Pipe Syntax Parser
- [ ] Implement pipe operator `|` in expressions
- [ ] Add filter name parsing after pipe
- [ ] Handle filter arguments `filter(arg1, arg2)`
- [ ] Write tests for pipe syntax parsing

### Task 6.3: Function Call Syntax Parser
- [ ] Add function call support to primary expressions
- [ ] Parse function arguments `func(arg1, arg2)`
- [ ] Create `argument_list` combinator
- [ ] Write tests for function call parsing

### Task 6.4: Filter Chain Builder
- [ ] Create `build_pipe_chain/1` reducer
- [ ] Convert pipe chains to nested call expressions
- [ ] Handle mixed pipe and function syntax
- [ ] Write tests for filter chain building

### Task 6.5: Built-in String Filters
- [ ] Implement `upper_case`, `lower_case`, `capitalize`
- [ ] Implement `truncate` with length argument
- [ ] Implement `default` filter
- [ ] Write tests for string filters

### Task 6.6: Built-in Number Filters
- [ ] Implement `round` with precision
- [ ] Implement `format_currency`
- [ ] Write tests for number filters

### Task 6.7: Built-in Collection Filters
- [ ] Implement `length`, `first`, `last`
- [ ] Implement `join` with separator
- [ ] Implement `sort`, `reverse`, `uniq`
- [ ] Write tests for collection filters

### Task 6.8: Filter Evaluation Engine
- [ ] Implement `evaluate_call/3` for filter calls
- [ ] Add argument evaluation
- [ ] Add filter application logic
- [ ] Handle filter errors gracefully
- [ ] Write comprehensive filter evaluation tests

---

## Group 7: Assignment Tags

### Task 7.1: Tag Block Parser Foundation
- [ ] Create tag parsing infrastructure with `{%` and `%}`
- [ ] Add tag content parsing
- [ ] Implement basic tag structure
- [ ] Write tests for tag block parsing

### Task 7.2: Assignment Tag Parser
- [ ] Implement `assign_tag` combinator
- [ ] Parse variable name and assignment expression
- [ ] Handle whitespace around `=` operator
- [ ] Write tests for assignment parsing

### Task 7.3: Assignment Tag Evaluator
- [ ] Implement assignment tag rendering
- [ ] Add variable assignment to context
- [ ] Handle assignment expression evaluation
- [ ] Write tests for assignment evaluation

### Task 7.4: Context Management
- [ ] Update context handling for assignments
- [ ] Add variable scoping rules
- [ ] Ensure assignments persist in template
- [ ] Write integration tests for assignments

---

## Group 8: Conditional Tags

### Task 8.1: If Tag Parser
- [ ] Implement `if_tag` combinator
- [ ] Parse condition expression after `if`
- [ ] Write tests for if tag parsing

### Task 8.2: Elsif and Else Tag Parser
- [ ] Implement `elsif_tag` and `else_tag` combinators
- [ ] Implement `endif_tag` combinator
- [ ] Write tests for conditional tag parsing

### Task 8.3: Block Structure Builder
- [ ] Create `Mau.Parser.BlockParser` module
- [ ] Implement `collect_if_block/2` function
- [ ] Build nested if/elsif/else structure
- [ ] Write tests for block structure building

### Task 8.4: Conditional Tag Evaluator
- [ ] Implement `render_tag/4` for `:if`
- [ ] Add condition evaluation and branching
- [ ] Handle multiple elsif clauses
- [ ] Add else clause support
- [ ] Write comprehensive conditional evaluation tests

### Task 8.5: Conditional Integration
- [ ] Update main parser to handle conditional blocks
- [ ] Add conditional support to template parsing
- [ ] Write integration tests for conditionals

---

## Group 9: Loop Tags

### Task 9.1: For Tag Parser
- [ ] Implement `for_tag` combinator
- [ ] Parse loop variable and collection expression
- [ ] Add `in` keyword parsing
- [ ] Write tests for for tag parsing

### Task 9.2: Loop Options Parser
- [ ] Implement `for_options` combinator
- [ ] Add `limit:` and `offset:` option parsing
- [ ] Write tests for loop options

### Task 9.3: Loop Block Structure
- [ ] Add for loop to block structure builder
- [ ] Implement `collect_until_tag/3` for endfor
- [ ] Create nested loop AST structure
- [ ] Write tests for loop block building

### Task 9.4: Loop Context Management
- [ ] Create loop variable context handling
- [ ] Add loop metadata (forloop.index, etc.)
- [ ] Implement context isolation for loops
- [ ] Write tests for loop context

### Task 9.5: Loop Evaluator
- [ ] Implement `render_tag/4` for `:for`
- [ ] Add collection evaluation and iteration
- [ ] Apply limit and offset options
- [ ] Handle empty collections gracefully
- [ ] Write comprehensive loop evaluation tests

### Task 9.6: Loop Variables
- [ ] Add `forloop` object to loop context
- [ ] Implement index, first, last properties
- [ ] Add length and reverse index properties
- [ ] Write tests for loop variables

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