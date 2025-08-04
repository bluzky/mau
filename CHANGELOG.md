# Changelog

All notable changes to the Mau template engine project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup and repository structure
- Comprehensive documentation suite including:
  - Template AST specification
  - Template evaluator implementation patterns
  - Template language reference
  - Implementation plan and task breakdown

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