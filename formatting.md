---
title: Actions File Formatting Specification
description: Canonical formatting rules for .actions files
author: primary_desktop
categories: Reference
created: 2026-01-01
version: 3.1.0
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

The formatter enforces exactly one space at every boundary between distinct fields:

- Space after state brackets: `[x] Task` rather than `[x]Task`
- Space before each metadata field: `Task !1 +tag #id` rather than `Task!1+tag#id`

It does **not** add a space between a field's own icon and its value: `!1`, `#id`, `*StoryName` stay compact. Only the boundary *between* fields is owned by the formatter; the inside of a field is not.

This is enforced at two levels, and both matter for idempotency:

- The grammar (`tree-sitter-actions/patterns.js`) never lets a text-bearing token (name, story, tags, predecessor names) absorb a leading or trailing whitespace run into its own byte range -- interior spaces (multi-word names) are untouched, but the space right before the next sigil is never silently swallowed into the preceding token.
- The Topiary query (`queries/actions/formatting.scm`) then unconditionally prepends one space at every `name`/`metadata` field boundary.

Because no token can absorb the boundary space itself, the two never compete, and `format(format(x)) == format(x)` for spacing.

## Version History

### 3.1.0 (2026-07-03)
- **Breaking:** Formatter now enforces horizontal spacing at field boundaries (reverses the 2.1.0 decision to leave this to lint-only)
- Root cause of the earlier inconsistent double-spacing: `notChars()`-based grammar tokens (name, story, tags, predecessor names) greedily absorbed boundary whitespace into their own byte range, so a topiary `@prepend_space` directive could double up with whitespace already baked into the preceding token
- Fixed at the grammar level with `notCharsTrimmed()`, which never lets a token start or end on whitespace while still allowing interior spaces
- `formatting.scm` now uses two blanket rules covering state->name and every field->field boundary
- Icon->value spacing within a single field (`!1`, `#id`) remains unenforced/compact -- unchanged from prior versions

### 3.0.0 (2026-01-31)
- **Breaking:** Formatter now enforces indentation based on action depth
- Depth markers themselves are indented (not just action content)
- Indentation respects user preferences (spaces vs tabs, width)
- Updated Topiary query to add indentation rules
- Updated Neovim indents.scm to match Topiary behavior

**Migration:** Run `clearhead format --in-place` on existing files to update formatting

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
