---
title: Actions File Formatting Specification
description: Canonical formatting rules for .actions files
author: primary_desktop
categories: Reference
created: 2026-01-01
version: 2.1.0
---

# Actions File Formatting Specification

This document covers the formatting rules for `.actions` files in the ClearHead ecosystem. The goal of this specification is to ensure consistent and readable formatting across different tools and editors while respecting the syntactically insignificant nature of whitespace in the ClearHead file format.

## Rules

### New Actions on New Lines

While actions themselves may also contain newlines, it is recommended that each action be placed on its own line to enhance readability.

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

This makes each action clearly distinguishable and easier to read.

### Identation for child actions

Child actions should be indented to reflect their hierarchy within the action list. Each level of depth should be represented by either 2 spaces or a tab character, depending on the user's preference.

```actions
[ ] Parent Task
    [ ] Child Task 1
        [ ] Sub-child Task
    [ ] Child Task 2
```


### Metadata Spacing

While the formatter doesn't enforce these, the following are recommended for readability:

- Space after state brackets: `[x] Task` rather than `[x]Task`
- Space before metadata: `Task !1` rather than `Task!1`

These can be checked via linter rules (info severity) if desired.

## Version History

### 2.3.0 (2026-01-30)
- expanded to include guidance on the various formats
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
