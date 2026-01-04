# Changelog - Actions Specifications

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

### Implementation Status

**clearhead-cli** (Rust implementation):
- ✅ Horizontal spacing implemented in `format_as_actions_basic()`
- ✅ Spec-compliant formatter working
- ⚠️ Topiary disabled (was stripping spacing)
- ⚠️ LSP still using old Topiary path (broken)
- ⚠️ List mode not implemented

See `clearhead-cli/CHANGELOG.md` for detailed implementation notes and decisions needed.
