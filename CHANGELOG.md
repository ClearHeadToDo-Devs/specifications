# Changelog - Actions Specifications

## 2026-01-24
### Refactor: move older specifications to archive
Moved a few specifications to `Archive` folder as we move to an RDF-centric approach:
- sql_schema: no need as RDF does more work 
- json_schema: superseded by ontology 
- event logging specification as this is now handled by the sync specification

## 2026-01-18

### Changed

**Formatting Specification v2.1.0** (`formatting.md`)
- **Breaking:** Reduced scope to vertical spacing only (newlines between actions)
- Removed horizontal spacing enforcement - format is whitespace-insensitive by design
- Removed indentation enforcement - depth markers define hierarchy, not whitespace
- Formatter now implemented as Topiary query in `tree-sitter-actions/.topiary/`
- No configuration options - formatter does one thing (newlines)
- Dramatically simplified specification

**Formatting Specification v2.0.0** (`formatting.md`)
- Removed list style - single format only
- Removed metadata ordering from formatter scope

### Rationale

The `.actions` format was designed to be whitespace-insensitive: `[x]Task$Desc` and `[x] Task $ Desc` are semantically equivalent. Fighting against this with a formatter that enforces specific spacing was adding complexity without clear benefit.

Similarly, hierarchy is defined by depth markers (`>`, `>>`, etc.), not by indentation. Enforcing indentation is cosmetic, not semantic.

By reducing the formatter to just "ensure newlines between actions," we:
1. Embrace the format's whitespace-insensitive design
2. Enable simple Topiary implementation (50 lines of queries)
3. Move formatting upstream to tree-sitter-actions where it belongs
4. Eliminate ~200 lines of Rust formatter code from clearhead-cli

### Removed

- `specifications/examples/formatting/list/` - List style test examples removed
- Horizontal spacing rules from formatter scope
- Indentation enforcement from formatter scope
- `indent_width` and `indent_style` configuration options

---

## 2026-01-03

### Changed

**Formatting Specification v1.1.0** (`formatting_specification.md`)
- **Expanded scope:** Formatter now enforces ALL spacing (horizontal + vertical)
- Removed caveats about "recommends but doesn't enforce horizontal spacing"
- Clarified that spec defines target behavior; implementations work toward conformance
- Updated philosophy to emphasize zero-configuration automatic formatting
- Design principle #5 changed from "Pragmatic scope" to "Zero-configuration"

**Linting Specification v1.1.0** (`linting_specification.md`)
- **Breaking change:** Removed spacing rules (S001-S004)
- Spacing is now handled entirely by the formatter
- Linter focuses exclusively on semantic correctness, temporal logic, and style preferences
- Reduced from 32 rules to 28 rules (11 errors, 4 warnings, 13 info)
- Updated philosophy section to clarify formatter vs linter boundary
- Renumbered categories: Semantic (1) → Temporal (2) → Style (3) → Content (4)

### Rationale

The original design had formatters handling vertical spacing and linters handling horizontal spacing due to tree-sitter grammar limitations. This created an awkward separation where:
- Formatter: vertical layout only
- Linter: horizontal spacing + semantics

New design has clean separation based on user intent:
- **Formatter** (automatic, opinionated): ALL presentation (horizontal + vertical spacing)
- **Linter** (configurable, optional): Semantic correctness only

This means formatters must work around grammar limitations (e.g., by serializing from IR with proper spacing rather than trying to edit AST).

### Implementation Status (as of 2026-01-03)

**clearhead-cli** (Rust implementation):
- ✅ Horizontal spacing implemented in `format_as_actions_basic()`
- ✅ Spec-compliant formatter working
- ⚠️ Topiary disabled (was stripping spacing)
- ⚠️ LSP still using old Topiary path

See `clearhead-cli/CHANGELOG.md` for detailed implementation notes.
