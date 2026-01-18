---
title: Actions File Formatting Specification
description: Canonical formatting rules for .actions files
author: primary_desktop
categories: Reference
created: 2026-01-01
version: 2.1.0
---

# Actions File Formatting Specification

This specification defines the minimal formatting rules for `.actions` files. The `.actions` format is **whitespace-insensitive by design** - `[x]Task$Desc` and `[x] Task $ Desc` are semantically equivalent. The formatter respects this by enforcing only structural formatting.

## Design Principles

1. **Format preserves semantics** - Formatting changes must not alter the meaning of actions
2. **Idempotency** - Formatting the same content twice produces identical results
3. **Whitespace-insensitive** - The format doesn't mandate specific horizontal spacing
4. **Minimal intervention** - Formatter handles structure, not style
5. **Storage vs display** - Canonical storage format; display is a tooling concern

## Formatter Scope

The `.actions` formatter enforces **vertical spacing only**:

- ✅ **Newlines between actions** - Each action appears on its own line

The formatter explicitly does **not** enforce:

- ❌ **Horizontal spacing** - User's choice; format is whitespace-insensitive
- ❌ **Indentation** - User's choice; hierarchy is defined by depth markers (`>`, `>>`), not whitespace
- ❌ **Metadata ordering** - See [linting.md](./linting.md) rule I006 for optional canonical ordering

### Rationale

The `.actions` format uses depth markers (`>`, `>>`, `>>>`, etc.) to define hierarchy, not indentation. This means:

```actions
[ ] Parent
>[ ] Child
>>[ ] Grandchild
```

and

```actions
[ ] Parent
    >[ ] Child
        >>[ ] Grandchild
```

are **semantically identical**. The formatter doesn't have an opinion about which is "correct" because both are valid.

Similarly, `[x]Task!1` and `[x] Task !1` parse to the same data. Horizontal spacing is a style preference, not a correctness concern.

## Formatting Rules

**The only rule**: Each action must be on its own line.

Input:
```actions
[ ] Task 1[ ] Task 2[ ] Task 3
```

Output:
```actions
[ ] Task 1
[ ] Task 2
[ ] Task 3
```

All other formatting (spacing, indentation) is preserved from input.

## Configuration

The formatter has no configuration options. It does one thing: ensure newlines between actions.

## Implementation

The formatter is implemented as a [Topiary](https://topiary.tweag.io/) query in the tree-sitter-actions repository:

```
tree-sitter-actions/.topiary/queries/actions.scm
```

This keeps formatting logic with the grammar where it belongs, and allows any tool using tree-sitter-actions to get formatting for free.

### Using the Formatter

```bash
# Via Topiary CLI
topiary format myfile.actions

# Via configuration
export TOPIARY_CONFIG_FILE=/path/to/tree-sitter-actions/.topiary/languages.ncl
topiary format --language actions --query /path/to/tree-sitter-actions/.topiary/queries/actions.scm
```

## Style Recommendations

While the formatter doesn't enforce these, the following are recommended for readability:

- Space after state brackets: `[x] Task` rather than `[x]Task`
- Space before metadata: `Task !1` rather than `Task!1`
- Space after description icon: `$ Description` rather than `$Description`
- Indent child actions: 4 spaces per depth level

These can be checked via linter rules (info severity) if desired.

## Version History

### 2.1.0 (2026-01-18)
- **Breaking:** Reduced scope to vertical spacing only
- Removed horizontal spacing enforcement (whitespace-insensitive by design)
- Removed indentation enforcement (depth markers define hierarchy)
- Formatter now implemented as Topiary query in tree-sitter-actions
- Dramatically simplified specification

### 2.0.0 (2026-01-18)
- Removed list style
- Removed metadata ordering from formatter scope

### 1.1.0 (2026-01-03)
- Expanded scope to all spacing

### 1.0.0 (2026-01-01)
- Initial specification
