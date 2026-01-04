---
title: Actions File Formatting Specification
description: Canonical formatting rules for .actions files
author: primary_desktop
categories: Reference
created: 2026-01-01
version: 1.1.0
---

# Actions File Formatting Specification

This specification defines the canonical formatting rules for `.actions` files. While the [action_specification.md](./action_specification.md) defines the syntax and structure, this document defines how that syntax should be formatted for optimal readability and consistency.

## Design Principles

1. **Format preserves semantics** - Formatting changes must not alter the meaning of actions
2. **Idempotency** - Formatting the same content twice produces identical results
3. **Context-appropriate** - Different display contexts (wide screens, narrow panels) warrant different formatting styles
4. **Minimal syntax** - The format itself uses minimal characters; formatting should honor this principle
5. **Zero-configuration** - Formatter handles all presentation automatically; users shouldn't think about spacing

## Formatter Scope

The `.actions` formatter enforces **all presentation-level formatting**:

- ✅ **Vertical spacing**: Newline after each action
- ✅ **Line mode**: Compact (all on one line) vs List (metadata on separate lines)
- ✅ **Indentation**: Correct indentation in list mode based on depth
- ✅ **Horizontal spacing**: Exact spacing around all tokens
  - Space after state brackets: `[x] ` not `[x]`
  - Space before metadata: `Task !1` not `Task!1`
  - Space after description icon: `$ Desc` not `$Desc`
  - No space after value icons: `!1` not `! 1`
- ✅ **Metadata order**: Optional canonical sequencing (see configuration)

### Design Philosophy

The formatter is **opinionated and automatic** - it silently fixes all presentation issues without user intervention. Users should never need to think about formatting; running format (e.g., LSP format-on-save) should produce perfectly formatted output.

The `.actions` format is semantically whitespace-insensitive - `[x]Task$Desc` and `[x] Task $ Desc` are equivalent in meaning. This allows the formatter to normalize all spacing without changing semantics.

### Implementation Note

Current implementations may have technical limitations (e.g., tree-sitter grammar constraints around whitespace capture). This specification defines the **target behavior** that implementations should work toward. Implementations may use post-processing, custom parsers, or other techniques to achieve full conformance.

## Formatting Styles

The specification defines two canonical formatting styles, each optimized for different use cases.

### Compact Style

**Purpose**: Optimized for wide displays where horizontal space is abundant. Maximizes information density while maintaining readability.

**Formatting Rules**:
1. ✅ All metadata appears on the same line as the action name
2. ✅ One action per line (newline after each action)
3. ✅ Space after state brackets: `[x] Task` not `[x]Task`
4. ✅ Space after depth markers: `>[ ] Child` not `>[  ]Child`
5. ✅ Space before each metadata token: `Task !1 *Story` not `Task!1*Story`
6. ✅ Space after description icon: `$ Desc` not `$Desc`
7. ✅ No space after value icons: `!1` not `! 1`

**Example**:
```actions
[x] Team meeting $ Discuss Q1 roadmap !1 *Projects +Work @2025-01-20T14:00 D60 %2025-01-20T15:05
[ ] Parent task >[ ] Child task >>[ ] Grandchild task
```

### List Style

**Purpose**: Optimized for narrow displays (e.g., task sidebars, mobile views, split panes). Prioritizes vertical readability over horizontal density.

**Formatting Rules**:
1. ✅ Action name on same line as state
2. ✅ Each metadata item appears on a separate line
3. ✅ Metadata indented to `(action_depth + 1) × indent_width` spaces
4. ✅ Child actions at their respective depth level
5. ✅ Default `indent_width`: 4 spaces
6. ✅ All horizontal spacing rules from compact style apply within each line

**Example** (with `indent_width = 4`):
```actions
[x] Team meeting
    $ Discuss Q1 roadmap
    !1
    *Projects
    +Work
    @2025-01-20T14:00
    D60
    %2025-01-20T15:05
[ ] Parent task
    >[ ] Child task
        $ Child description
        !2
        >>[ ] Grandchild task
            $ Grandchild description
            !3
```

**Indentation details**:
- Root action (depth 0) metadata: `0 + 1 = 1 × 4 = 4 spaces`
- Depth 1 child action: `1 × 4 = 4 spaces` (for the `>` marker)
- Depth 1 child metadata: `1 + 1 = 2 × 4 = 8 spaces`
- Depth 2 grandchild action: `2 × 4 = 8 spaces` (for the `>>` markers)
- Depth 2 grandchild metadata: `2 + 1 = 3 × 4 = 12 spaces`

## Metadata Token Formatting

These rules apply to both compact and list styles.

### Icon Spacing

Metadata tokens consist of an icon and a value. Spacing rules:

| Token | Icon | Value Example | Spacing | Result |
|-------|------|---------------|---------|--------|
| Description | `$` | `Some text` | Space after icon | `$ Some text` |
| Priority | `!` | `1` | No space | `!1` |
| Story | `*` | `Project` | No space | `*Project` |
| Context | `+` | `Work,Home` | No space | `+Work,Home` |
| Do-date | `@` | `2025-01-20` | No space | `@2025-01-20` |
| Duration | `D` | `60` | No space | `D60` |
| Recurrence | `R:` | `FREQ=DAILY` | No space | `R:FREQ=DAILY` |
| Completed | `%` | `2025-01-20T15:05` | No space | `%2025-01-20T15:05` |
| ID | `#` | `uuid` | No space | `#01950000-0000-7000-8000-000000000001` |

**Rationale**: The `$` (description) icon gets a space because descriptions are prose. All other metadata values are terse identifiers or structured data that read better without separation.

### Metadata Order

The format specification does not mandate a specific metadata order - implementations may preserve the author's original ordering or apply a canonical order. If applying a canonical order, the recommended sequence is:

1. Description (`$`)
2. Priority (`!`)
3. Story (`*`)
4. Context (`+`)
5. Do-date/time (`@`)
6. Duration (`D`)
7. Recurrence (`R:`)
8. Completed date (`%`)
9. ID (`#`)

This ordering groups related information: narrative first (description), categorization next (priority, story, context), then temporal data (dates, durations), and finally system metadata (ID).

## Special Cases

### Multiline Descriptions

Descriptions may contain newlines within their text. Formatters must preserve these newlines:

**Compact style**:
```actions
[ ] Task $ This is a description
that spans multiple
lines !1
```

**List style**:
```actions
[ ] Task
    $ This is a description
that spans multiple
lines
    !1
```

Note: In list style, the continuation lines of the description are not indented further - only the `$` icon is indented.

### Links

Links (`[[text|url]]` or `[[url]]`) are treated as atomic units and must not be split or reformatted:

```actions
[ ] Review PR $ See [[Documentation|https://example.com/docs]] for details
```

### Empty Files

An empty `.actions` file (zero bytes or only whitespace) formats to an empty file in both styles.

### Actions Without Metadata

Minimal actions (state + name only) format identically in both styles:

```actions
[ ] Simple task
```

## Formatting Configuration

Implementations should support the following configuration options:

### `style`
- Type: enum
- Values: `compact` | `list`
- Default: `compact`
- Description: Which formatting style to apply

### `indent_width`
- Type: integer
- Valid range: 1-8
- Default: `4`
- Description: Number of spaces per indentation level (list style only)

### Example configuration (TOML):
```toml
[format]
style = "list"
indent_width = 4
```

## Implementation Guidance

### Formatter Requirements

A conformant formatter MUST:
1. Parse the input using the tree-sitter grammar (or equivalent)
2. Reject malformed input (syntax errors)
3. Preserve all semantic information (no data loss)
4. Apply the selected style's formatting rules
5. Produce idempotent output (formatting twice yields identical results)

A conformant formatter SHOULD:
1. Support both compact and list styles
2. Allow configuration via command-line flags and/or config files
3. Provide a `--check` mode that exits non-zero if formatting would change the file
4. Preserve metadata order unless configured otherwise

### Editor Integration

For optimal user experience, editor integrations should:
1. Auto-detect appropriate style based on window width (e.g., `< 80 columns` → list, `≥ 80 columns` → compact)
2. Format on save (configurable)
3. Show formatting changes as diffs before applying
4. Respect user-configured indent width

### Round-Trip Guarantee

Formatters must guarantee round-trip fidelity:

```
input.actions → parse → format(compact) → parse → format(list) → parse → format(compact) → output.actions
```

The final `output.actions` must be semantically identical to `input.actions` (same actions, metadata, hierarchy). Only whitespace and layout may differ.

## Examples

### Full Example: Compact Style

```actions
[x] Team meeting $ Discuss Q1 roadmap !1 *Projects +Work @2025-01-20T14:00 D60 %2025-01-20T15:05
[ ] Take out trash @2025-01-21T19:00 R:FREQ=WEEKLY;BYDAY=TU #01950000-0000-7000-8000-000000000001
[ ] Research task $ Read [[Tree-sitter docs|https://tree-sitter.github.io]] !2 +Learning

[ ] Parent task $ Complex hierarchy example
    >[ ] Child task $ First subtask !1
        >>[ ] Grandchild task $ Deeply nested
    >[ ] Another child $ Second subtask !2
```

### Full Example: List Style

```actions
[x] Team meeting
    $ Discuss Q1 roadmap
    !1
    *Projects
    +Work
    @2025-01-20T14:00
    D60
    %2025-01-20T15:05

[ ] Take out trash
    @2025-01-21T19:00
    R:FREQ=WEEKLY;BYDAY=TU
    #01950000-0000-7000-8000-000000000001

[ ] Research task
    $ Read [[Tree-sitter docs|https://tree-sitter.github.io]]
    !2
    +Learning

[ ] Parent task
    $ Complex hierarchy example
    >[ ] Child task
        $ First subtask
        !1
        >>[ ] Grandchild task
            $ Deeply nested
    >[ ] Another child
        $ Second subtask
        !2
```

## Version History

### 1.1.0 (2026-01-03)
- **Expanded scope:** Formatter now enforces ALL spacing (horizontal and vertical)
- Removed caveats about horizontal spacing limitations
- Clarified that spec defines target behavior; implementations work toward conformance
- Updated philosophy to emphasize zero-configuration automatic formatting

### 1.0.0 (2026-01-01)
- Initial specification
- Defined compact and list styles
- Established formatting rules and configuration options
