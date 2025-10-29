# Mau Documentation Structure

This document outlines the recommended documentation structure for the Mau template engine project.

## Current Structure

```
mau/
├── README.md                              # Project overview and quick start
├── CLAUDE.md                              # Claude Code development guidelines
├── CHANGELOG.md                           # Version history and changes
├── IMPLEMENTATION_PLAN.md                 # Technical implementation roadmap
├── TASKS.md                               # Development task tracking
├── BENCHMARKS.md                          # Performance benchmarks
├── LICENSE                                # Project license
│
├── docs/                                  # Documentation directory
│   ├── DOCUMENTATION_STRUCTURE.md         # This file
│   ├── template_language_reference.md     # Template syntax reference
│   ├── template_ast_specification.md      # AST structure specification
│   └── map_directives_reference.md        # Map directive system reference
│
├── lib/                                   # Source code
├── test/                                  # Test files
└── bench/                                 # Benchmark files
```

## Recommended Structure

### Phase 1: Reorganize Existing Documentation

```
docs/
├── README.md                              # Documentation index and navigation
│
├── getting-started/                       # Beginner-friendly guides
│   ├── installation.md                    # Installation instructions
│   ├── quick-start.md                     # 5-minute tutorial
│   ├── basic-concepts.md                  # Core concepts overview
│   └── first-template.md                  # Your first template walkthrough
│
├── guides/                                # Task-oriented guides
│   ├── template-syntax.md                 # Template syntax guide (from template_language_reference.md)
│   ├── filters.md                         # Using and chaining filters
│   ├── control-flow.md                    # If/elsif/else, for loops
│   ├── variables.md                       # Variable access and assignment
│   ├── whitespace-control.md              # Managing whitespace
│   ├── workflow-integration.md            # Using $input, $nodes, $variables
│   └── map-rendering.md                   # Using render_map with directives
│
├── reference/                             # API and detailed references
│   ├── template-language.md               # Complete language reference (current template_language_reference.md)
│   ├── ast-specification.md               # AST structure (current template_ast_specification.md)
│   ├── map-directives.md                  # Map directives (current map_directives_reference.md)
│   ├── filters-list.md                    # Alphabetical filter reference
│   ├── functions-list.md                  # Built-in functions reference
│   └── api-reference.md                   # Elixir API documentation
│
├── advanced/                              # Advanced topics
│   ├── custom-filters.md                  # Creating custom filters
│   ├── custom-functions.md                # Creating custom functions
│   ├── performance-tuning.md              # Optimization techniques
│   ├── error-handling.md                  # Error handling strategies
│   ├── security.md                        # Security best practices
│   └── extending-mau.md                   # Extending the engine
│
└── examples/                              # Real-world examples
    ├── web-templates.md                   # Web templating examples
    ├── email-templates.md                 # Email generation
    ├── report-generation.md               # Dynamic reports
    ├── workflow-automation.md             # Workflow use cases
    └── data-transformation.md             # Data pipeline examples
```

## File Migration Plan

### Immediate Actions

1. **Create `docs/README.md`** - Documentation index with navigation
2. **Move content to guides/** - Extract from `template_language_reference.md`:
   - Template syntax basics → `guides/template-syntax.md`
   - Filter usage → `guides/filters.md`
   - Control flow → `guides/control-flow.md`

3. **Rename for clarity**:
   - `template_language_reference.md` → `reference/template-language.md`
   - `template_ast_specification.md` → `reference/ast-specification.md`
   - `map_directives_reference.md` → `reference/map-directives.md`

### Short-term (Next Release)

1. **Create getting-started/** directory
   - Extract installation from README.md
   - Create quick-start tutorial
   - Write basic concepts overview

2. **Create guides/** directory
   - Extract and expand sections from reference docs
   - Add practical examples for each feature
   - Include common use cases and patterns

3. **Enhance reference/** directory
   - Add comprehensive filter list with examples
   - Document all built-in functions
   - Create API reference from ExDoc

### Medium-term

1. **Create examples/** directory
   - Real-world use cases
   - Integration examples
   - Common patterns and recipes

2. **Create advanced/** directory
   - Custom filter development
   - Performance optimization
   - Security considerations

## Documentation Standards

### File Naming
- Use lowercase with hyphens: `getting-started.md`
- Be descriptive: `creating-custom-filters.md` not `filters.md`
- Group related topics in directories

### Content Structure
Each documentation file should have:

```markdown
# Title

Brief description (1-2 sentences)

## Table of Contents
- [Section 1](#section-1)
- [Section 2](#section-2)

## Overview
What this document covers

## Section 1
Content with examples

## Examples
Practical examples

## See Also
- [Related Doc 1](link)
- [Related Doc 2](link)
```

### Code Examples
- Always include complete, runnable examples
- Show both input and output
- Include error cases where relevant
- Use syntax highlighting

### Cross-References
- Link related documentation
- Reference API documentation
- Point to examples

## Navigation

### docs/README.md Structure

```markdown
# Mau Documentation

Welcome to Mau template engine documentation!

## 🚀 Getting Started
- [Installation](getting-started/installation.md)
- [Quick Start](getting-started/quick-start.md)
- [Basic Concepts](getting-started/basic-concepts.md)

## 📖 Guides
- [Template Syntax](guides/template-syntax.md)
- [Filters](guides/filters.md)
- [Control Flow](guides/control-flow.md)
- [Map Directives](guides/map-rendering.md)

## 📚 Reference
- [Template Language](reference/template-language.md)
- [AST Specification](reference/ast-specification.md)
- [Map Directives](reference/map-directives.md)
- [Filter List](reference/filters-list.md)

## 🔧 Advanced Topics
- [Custom Filters](advanced/custom-filters.md)
- [Performance Tuning](advanced/performance-tuning.md)
- [Security](advanced/security.md)

## 💡 Examples
- [Web Templates](examples/web-templates.md)
- [Email Templates](examples/email-templates.md)
- [Workflow Automation](examples/workflow-automation.md)
```

## Documentation Tools

### Recommended Tools
1. **MkDocs** or **Docusaurus** - Documentation site generator
2. **ExDoc** - Generate API documentation from code
3. **Mermaid** - Diagrams in markdown
4. **Vale** - Documentation linting

### Build Process
```bash
# Generate API docs
mix docs

# Build documentation site (if using MkDocs)
mkdocs build

# Serve locally
mkdocs serve
```

## Maintenance

### Regular Updates
- Update examples with new features
- Keep version compatibility notes current
- Review and update cross-references
- Add new guides as features are added

### Quality Checks
- [ ] All code examples work
- [ ] Cross-references are valid
- [ ] Navigation is complete
- [ ] Search works properly
- [ ] Mobile-friendly

## Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal**: Establish documentation structure and navigation

**Tasks**:
- [ ] Create `docs/README.md` with navigation and quick start
- [ ] Create directory structure (`getting-started/`, `guides/`, `reference/`, `advanced/`, `examples/`)
- [ ] Move existing files to `reference/`:
  - [ ] `template_language_reference.md` → `reference/template-language.md`
  - [ ] `template_ast_specification.md` → `reference/ast-specification.md`
  - [ ] `map_directives_reference.md` → `reference/map-directives.md`
- [ ] Update root `README.md` to link to `docs/README.md`
- [ ] Add navigation breadcrumbs to existing reference docs

**Deliverables**:
- Organized directory structure
- Central documentation index
- All existing docs accessible from new structure

---

### Phase 2: Getting Started (Week 2)
**Goal**: Create beginner-friendly onboarding guides

**Tasks**:
- [ ] `getting-started/installation.md`
  - Installation instructions
  - Prerequisites
  - Verification steps

- [ ] `getting-started/quick-start.md`
  - 5-minute tutorial
  - Basic template rendering
  - Common use cases

- [ ] `getting-started/basic-concepts.md`
  - Template syntax overview
  - Variables and expressions
  - Filters basics
  - Control flow introduction

- [ ] `getting-started/first-template.md`
  - Step-by-step walkthrough
  - Building a complete example
  - Common pitfalls

**Deliverables**:
- 4 getting-started guides
- New users can get started in < 5 minutes

---

### Phase 3: Task-Oriented Guides (Week 3-4)
**Goal**: Extract and expand practical guides from reference docs

**Tasks**:
- [ ] `guides/template-syntax.md`
  - Extract from `template_language_reference.md`
  - Variable interpolation: `{{ }}`
  - Tag blocks: `{% %}`
  - Comments: `{# #}`

- [ ] `guides/filters.md`
  - Filter syntax and chaining
  - Common filter patterns
  - Filter composition examples

- [ ] `guides/control-flow.md`
  - If/elsif/else conditionals
  - For loops with limit/offset
  - Loop metadata (`forloop.*`)

- [ ] `guides/variables.md`
  - Variable assignment
  - Property access
  - Array indexing
  - Nested access

- [ ] `guides/whitespace-control.md`
  - Trim left: `{{-`
  - Trim right: `-}}`
  - Practical examples

- [ ] `guides/map-rendering.md`
  - Using `render_map/3`
  - Map directives overview
  - Practical examples
  - When to use vs `render/3`

**Deliverables**:
- 6 practical guides
- Each guide with 3-5 complete examples

---

### Phase 4: Enhanced Reference (Week 5)
**Goal**: Create comprehensive filter and function references

**Tasks**:
- [ ] `reference/filters-list.md`
  - Alphabetical filter list
  - String filters (21 filters)
  - Collection filters (12 filters)
  - Math filters (11 filters)
  - Type filters (2 filters)
  - Each with syntax, description, examples

- [ ] `reference/functions-list.md`
  - Built-in functions
  - Syntax and parameters
  - Return values
  - Examples

- [ ] `reference/api-reference.md`
  - Generate from ExDoc
  - Public API documentation
  - Module references

**Deliverables**:
- Complete filter reference (40+ filters)
- Function reference
- Generated API docs

---

### Phase 5: Real-World Examples (Week 6)
**Goal**: Provide copy-paste ready examples for common use cases

**Tasks**:
- [ ] `examples/web-templates.md`
  - HTML page rendering
  - Navigation menus
  - Dynamic content sections
  - SEO meta tags

- [ ] `examples/email-templates.md`
  - Welcome emails
  - Order confirmations
  - Password reset
  - Newsletters

- [ ] `examples/report-generation.md`
  - Data reports
  - CSV generation
  - Summary tables
  - Charts data

- [ ] `examples/workflow-automation.md`
  - Workflow node integration
  - Data transformation pipelines
  - Conditional processing
  - Multi-step workflows

- [ ] `examples/data-transformation.md`
  - Using `#pipe` directive
  - Chaining `#filter` and `#map`
  - Complex transformations
  - Performance patterns

**Deliverables**:
- 5 example guides
- Each with 5+ complete, runnable examples
- Copy-paste ready code snippets

---

### Phase 6: Advanced Topics (Week 7-8)
**Goal**: Document advanced features and extension points

**Tasks**:
- [ ] `advanced/custom-filters.md`
  - Creating custom filters
  - Filter registration
  - Error handling in filters
  - Testing custom filters

- [ ] `advanced/custom-functions.md`
  - Implementing custom functions
  - Function signature
  - Context access
  - Examples

- [ ] `advanced/performance-tuning.md`
  - Template compilation tips
  - Context optimization
  - Filter performance
  - Benchmarking

- [ ] `advanced/error-handling.md`
  - Strict vs lenient modes
  - Custom error handlers
  - Debugging templates
  - Common error patterns

- [ ] `advanced/security.md`
  - Input validation
  - XSS prevention
  - Safe context handling
  - Sandboxing templates

- [ ] `advanced/extending-mau.md`
  - Architecture overview
  - Adding new directives
  - Parser extensions
  - Evaluator customization

**Deliverables**:
- 6 advanced guides
- Extension examples
- Security best practices

---

### Phase 7: Documentation Site (Week 9-10)
**Goal**: Set up professional documentation website

**Tasks**:
- [ ] Choose documentation platform (MkDocs or Docusaurus)
- [ ] Set up project configuration
- [ ] Configure theme and navigation
- [ ] Add search functionality
- [ ] Configure versioning
- [ ] Set up CI/CD for docs deployment
- [ ] Add analytics (optional)
- [ ] Test on mobile devices

**Deliverables**:
- Live documentation site
- Search functionality
- Mobile-friendly design
- Auto-deployment pipeline

---

### Phase 8: Polish & Maintenance (Ongoing)
**Goal**: Maintain documentation quality and accuracy

**Tasks**:
- [ ] Review all code examples for accuracy
- [ ] Test all examples against current version
- [ ] Fix broken cross-references
- [ ] Add missing screenshots/diagrams
- [ ] Spell check and grammar review
- [ ] Gather user feedback
- [ ] Update based on common questions
- [ ] Add more examples based on usage patterns

**Deliverables**:
- All examples verified working
- No broken links
- Consistent terminology
- User-tested documentation

## Success Metrics

- [ ] New users can get started in < 5 minutes
- [ ] All features have documentation
- [ ] Documentation is searchable
- [ ] Examples are copy-paste ready
- [ ] Clear navigation between related topics
- [ ] Mobile-friendly reading experience

## Notes

- Keep documentation in sync with code
- Use the same terminology consistently
- Prefer examples over long explanations
- Include "See Also" sections for discoverability
- Tag documentation with version numbers when features are added
