# Parser Module Splitting Plan - Gradual Migration Approach

This document outlines the gradual migration strategy for splitting the monolithic Mau parser into focused modules, based on lessons learned from the successful literal parsing migration.

## Strategy Overview

**Key Principle**: Gradual migration with full test coverage at each step to avoid the complex circular dependency issues that plague modular NimbleParsec architectures.

## Completed Phase 1: Literal Parsing ✅

**Status**: Successfully completed with 0 test failures

### What was done:
1. Created `Mau.Parser.Literal` module with all literal parsing functions
2. Updated main parser to delegate main literal parsing to the new module  
3. Kept internal helper functions in main parser to avoid combinator dependency issues
4. All 751 tests pass with full backward compatibility

### Key learnings:
- **Helper function duplication is acceptable** - NimbleParsec's compilation model requires helper functions to be available in the same module as the combinators that use them
- **Delegate the main parsing functions only** - Keep internal combinators and helpers in the main parser
- **Test at every step** - Each migration step must maintain 100% test coverage

## Phase 2: Variable Parsing ✅

**Status**: Successfully completed with 0 test failures
**Target modules**: Extract variable and identifier parsing
**Actual complexity**: Medium (as estimated)
**Dependencies**: None (successfully references Literal module)

### What was done:
1. Created `Mau.Parser.Variable` module with:
   - `identifier()` function (combines workflow and basic identifiers)
   - Internal helper functions for identifier parsing
   - Proper module-level combinator definitions

2. Updated main parser:
   - Added `alias Mau.Parser.Variable`
   - Replaced main identifier parsing with `Variable.identifier()`
   - Kept internal variable path, property access, and array index parsing in main parser
   - Maintained all internal helper functions (`build_identifier`, `build_workflow_identifier`, etc.)

3. Successfully tested - all 751 tests pass with full backward compatibility

### Key learnings:
- **Successful delegation of identifier parsing only** - Variable path parsing with property access and array indexing proved complex due to circular dependencies with defcombinatorp
- **Partial extraction is valuable** - Even extracting just the identifier parsing improves modularity without breaking functionality
- **NimbleParsec complexity** - Complex path parsing with forward declarations is better kept in the main parser to avoid compilation issues

## Phase 3: Expression Parsing [FUTURE]

**Target modules**: Extract expression evaluation and operator precedence
**Estimated complexity**: High  
**Dependencies**: Variable, Literal modules

### Steps:
1. Create `Mau.Parser.Expression` module with:
   - `primary_expression()` function
   - `pipe_expression()` function
   - Arithmetic operators (`additive_expression`, `multiplicative_expression`)
   - Comparison operators (`equality_expression`, `relational_expression`)
   - Logical operators (`logical_and_expression`, `logical_or_expression`)

2. Keep complex interdependent helpers in main parser
3. Test thoroughly due to complex precedence rules

### Expected challenges:
- High circular dependency risk due to expression precedence
- Complex parser combinator relationships
- May need to keep most helpers in main parser

## Phase 4: Tag Parsing [FUTURE]

**Target modules**: Extract tag parsing (`{% %}` blocks)
**Estimated complexity**: Medium
**Dependencies**: Expression, Variable, Literal modules

### Steps:
1. Create `Mau.Parser.Tag` module
2. Extract assignment, conditional, and loop tag parsing
3. Keep tag evaluation helpers in main parser

## Phase 5: Block Parsing [FUTURE]

**Target modules**: Extract block-level parsing (comments, text content)
**Estimated complexity**: Low
**Dependencies**: All other modules

### Steps:
1. Create `Mau.Parser.Block` module
2. Extract comment block, text content parsing
3. Final orchestration of all block types

## Migration Guidelines

### DO:
- ✅ Test at every single step with full test suite
- ✅ Keep helper functions duplicated between modules when needed
- ✅ Delegate only the main parsing functions to new modules
- ✅ Maintain 100% backward compatibility
- ✅ One module at a time, verify before proceeding

### DON'T:
- ❌ Attempt to eliminate all duplication (NimbleParsec doesn't support this well)
- ❌ Move combinators that have complex interdependencies
- ❌ Skip testing between migration steps
- ❌ Try to migrate multiple modules simultaneously

## Success Metrics

Each migration phase must achieve:
- ✅ All 751 tests pass (0 failures)
- ✅ No compilation errors
- ✅ All doctests pass
- ✅ Backward compatibility maintained
- ✅ Performance equivalent to monolithic version

## Risk Assessment

**Low Risk**: Literal parsing (✅ completed successfully), Basic identifier parsing (✅ completed successfully)
**Medium Risk**: Variable path parsing (partially extracted), Tag parsing, Block parsing
**High Risk**: Expression parsing (complex precedence and circular dependencies)

## Rollback Strategy

If any migration step fails:
1. `git checkout -- <affected_files>` to restore working version
2. `rm -rf lib/mau/parser/<new_module>` to remove broken module
3. Analyze the specific dependency issues
4. Consider alternative approaches or accept the current level of modularization

## Conclusion

The gradual migration approach has proven successful with both the literal parsing module (Phase 1) and identifier parsing module (Phase 2). The key insights are:

1. **Working software is better than perfect architecture** - some duplication of helper functions is acceptable to maintain the robustness and testability of the parser
2. **Partial extraction provides value** - even extracting portions of complex parsing logic improves modularity and maintainability
3. **NimbleParsec circular dependencies are challenging** - complex forward declarations with defcombinatorp may require keeping functionality in the main parser

**Current Status**: 2 phases completed successfully, 751 tests passing consistently. Continue with this methodical, test-driven approach for the remaining modules.