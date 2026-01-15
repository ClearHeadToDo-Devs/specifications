---
title: Actions File Linting Specification
description: Optional checks for correctness, consistency, and best practices in .actions files
author: backup-admin
categories: Reference
created: 2026-01-03
version: 1.1.0
---

# Actions File Linting Specification

This specification defines optional linting rules for `.actions` files. While the [action_specification.md](./action_specification.md) defines valid syntax and [formatting_specification.md](./formatting_specification.md) handles all presentation (spacing, indentation, layout), this document defines semantic quality checks that detect correctness issues, temporal problems, and style violations.

## Philosophy
Linting is a strange topic. As the research has continued its clear that different languages use their linters differently.

For this, We will break it into three sections that roughly correspond to the error levels found in things like LSP server diagnostics
- Errors: Parse Errors for the tree. These errors should indicate that the file is unable to parse as valid when these errors are present.
- Warnings: Errors that, while not preventing parsing, will make downstream systems less able to input the information as data and may lead to headaches down the line.
- Info: Finally, these elements are those we cover in the 

### Linting vs Formatting

- **Formatter** enforces ALL presentation (spacing, indentation, layout) - automatic, opinionated, zero-config
- **Linter** detects semantic issues, temporal problems, and style preferences - optional, configurable, informative
- **Parser** validates syntax

The formatter handles everything about *how code looks*. The linter handles everything about *what code means* and whether it's correct, consistent, or following best practices.

A linter is *optional* and *configurable* - teams choose which rules to enforce based on their workflow. The formatter runs automatically (e.g., on save) and needs no configuration.

### Design Principles

1. **Non-destructive** - Linters report issues, they don't automatically fix semantic problems
2. **Configurable** - Rules have severity levels (error, warning, info) and can be disabled
3. **Helpful** - Messages guide users toward fixes with clear explanations
4. **Fast** - Checks should be efficient enough for real-time editor integration
5. **Layered** - Rules grouped by concern (correctness, style, best practices)

## Rule Categories

### 1. Parser Correctness (Errors)

These rules detect logical inconsistencies that likely indicate mistakes.

#### E001: Duration Without Do-Date
**Severity:** Error
**Fixable:** No

Duration (`D`) requires a do-date (`@`) to be meaningful.

```actions
❌ [ ] Meeting D60
✅ [ ] Meeting @2025-01-20T14:00 D60
```

**Rationale:** A duration without a start time is nonsensical.

#### E002: Recurrence Without Do-Date
**Severity:** Error
**Fixable:** No

Recurrence (`R:`) requires a do-date (`@`) as the starting point.

```actions
❌ [ ] Task R:FREQ=DAILY
✅ [ ] Task @2025-01-20 R:FREQ=DAILY
```

#### E003: Empty Context Tag
**Severity:** Error
**Fixable:** No

Context tags cannot be empty.

```actions
❌ [ ] Task +
❌ [ ] Task +work,,home
✅ [ ] Task +work,home
```


#### E004: Orphaned Child Marker
**Severity:** Error
**Fixable:** No

Child actions (`>`) must follow a parent action at the appropriate depth.

```actions
❌ >[ ] No parent
✅ [ ] Parent
   >[ ] Child
```

#### E005: Skipped Hierarchy Level
**Severity:** Error
**Fixable:** No

Cannot skip depth levels (e.g., depth 0 → depth 2).

```actions
❌ [ ] Root
   >>[ ] Skipped depth 1
✅ [ ] Root
   >[ ] Depth 1
   >>[ ] Depth 2
```

#### E006: Invalid UUID Format
**Severity:** Error
**Fixable:** No

UUIDs must follow standard format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (UUIDv7 recommended).

```actions
❌ [ ] Task #not-a-uuid
❌ [ ] Task #123
✅ [ ] Task #01950000-0000-7000-8000-000000000001
```

UUIDs are critical for the unique identification of actions across files and systems.

V7 adds the benefit of being time-sortable, which is useful for tracking creation order.

### 2. Warnings 

These rules check for suspicious date/time relationships.

#### W001: Past Do-Date on Not-Started Action
**Severity:** Warning
**Fixable:** No

Actions with state `[ ]` (not started) probably shouldn't have do-dates in the past.

```actions
⚠️  [ ] Task @2020-01-01  # Several years ago
✅ [x] Task @2020-01-01 %2020-01-02  # Completed in the past is fine
✅ [ ] Task @2026-01-20  # Future is fine
```

**Rationale:** Likely indicates stale actions that should be updated or archived.

**Configuration:** `past_do_date_threshold_days` (default: 7) - how many days past before warning.

#### W002: Completed Before Scheduled
**Severity:** Warning
**Fixable:** No

Completed date shouldn't be significantly before do-date.

```actions
 [x] Meeting @2025-01-20T14:00 %2025-01-20T10:00  
 [x] Meeting @2025-01-20T14:00 %2025-01-20T14:30  
```

**Configuration:** `early_completion_threshold_minutes` (default: 60)


#### W005: Hierarchy Depth Exceeded
**Severity:** Warning
**Fixable:** No

Maximum nesting depth is 5 levels (depth 0-5).

```actions
❌ [ ] Root >>>>>>[ ] Too deep (depth 6)
✅ [ ] Root >>>>>[ ] OK (depth 5)
```

This may or may not be a breaking issue depending on parser implementation. but either way, the process also discourages deep nesting for clarity.

#### E006: Completed Parent with Uncompleted Children
**Severity:** Error
**Fixable:** No

A parent action cannot be marked as completed if it has children that are still active.

```actions
❌ [x] Parent
   >[ ] Uncompleted child
✅ [x] Parent
   >[x] Completed child
```

**Rationale:** Archiving and completion logic typically operates on trees. A "completed" parent with "active" work is semantically inconsistent.

#### E007: Uncompleted Parent with All Children Completed
**Severity:** Warning
**Fixable:** No

A parent action that is not completed but has all its children marked as completed should likely be completed as well.

```actions
⚠️  [ ] Parent
   >[x] Child 1
   >[x] Child 2
✅ [x] Parent
   >[x] Child 1
   >[x] Child 2
```

**Rationale:** Serves as a nudge to the user to wrap up the parent action once all its sub-tasks are finished.

#### E008: Missing Creation Date
**Severity:** Warning (style/tracking preference, not a correctness issue)
**Fixable:** Yes (derive from UUID v7 or add current date)

Actions should ideally have a creation date, either explicitly via the `^` marker or implicitly via a UUID v7 in the `#` field.

```actions
⚠️  [ ] New task
✅ [ ] New task ^2026-01-03
✅ [ ] New task #01942db4-0000-7000-8000-000000000001
```

**Rationale:** Creation timestamps help with aging analysis and history tracking, but are not required for correctness. This is a best practice for teams wanting detailed action tracking, but can be disabled for casual use.

#### E009: Creation Date in Future
**Severity:** Error
**Fixable:** No

The creation date (`^`) cannot be in the future relative to the current system time.

```actions
❌ [ ] Task ^2099-01-01
```

#### E010: Completion Before Creation
**Severity:** Error
**Fixable:** No

The completion date (`%`) cannot be before the creation date (`^`).

```actions
❌ [x] Impossible Task ^2026-01-03 %2026-01-01
```

#### E011: Circular Dependency
**Severity:** Error
**Fixable:** No

Actions cannot have circular dependencies (directly or transitively).

```actions
❌ [ ] Task A < Task B
❌ [ ] Task B < Task A
```

**Rationale:** Circular dependencies are logically impossible — neither action can ever be completed.

**Fix suggestion:** Review the dependency structure and break the cycle by removing or reworking one of the dependencies.

#### W012: Invalid Predecessor Reference
**Severity:** Warning
**Fixable:** No

A predecessor references an action that doesn't exist in the workspace.

```actions
❌ [ ] Task < Nonexistent Action
```

**Rationale:** Actions should only depend on other actions that actually exist.

**Fix suggestion:** Check the name/UUID spelling, or create the missing predecessor action.

#### W013: Ambiguous Predecessor Reference
**Severity:** Warning
**Fixable:** No

Multiple actions in the workspace match the predecessor name. Use UUID to disambiguate.

```actions
⚠️  [ ] Deploy < setup  # Three "setup" actions exist in workspace
✅ [ ] Deploy < #01951111-cfa6-718d-b303-d7107f4005b3
```

**Rationale:** Name-based references should be unambiguous. When multiple matches exist, recommend UUIDs for clarity.

**Configuration:** `require_uuid_for_ambiguous_predecessors` (default: false) — if true, escalates to error severity.


### 3. Style and Conventions (Info)

#### I001: Completed State Requires Completed Date
**Severity:** Info
**Fixable:** No (requires user input)

Actions with state `[x]` (completed) must have a completed date (`%`).

```actions
❌ [x] Task $ Description !1
✅ [x] Task $ Description !1 %2025-01-20T15:00
```

**Rationale:** Completion tracking requires knowing *when* the action was completed.

**Fix suggestion:** Add `%YYYY-MM-DDTHH:MM` or change state to `[ ]`.

#### I002: Completed Date Requires Completed State
**Severity:** Info
**Fixable:** No

Actions with completed date (`%`) must have state `[x]`.

```actions
❌ [ ] Task %2025-01-20
✅ [x] Task %2025-01-20
```

**Rationale:** A completed date without completed state is contradictory.

We may consider reopen date if requested but for now it is assumed that actions are completed if they have a completed date.

#### E003: Invalid Priority Level
**Severity:** Error
**Fixable:** No

Priority must be 1-5 (1 = highest, 5 = lowest).

```actions
❌ [ ] Task !0
❌ [ ] Task !6
❌ [ ] Task !high
✅ [ ] Task !1
```

**Rationale:** Priority levels are defined by the format specification.

While we dont necessarily stop you from putting higher values, for the sake of the process, we conform to the eisenhower matrix


#### I005: Duplicate ID
**Severity:** Info
**Fixable:** No

Action IDs must be unique within the file (and ideally across the project).

```actions
❌ [ ] Task1 #01950000-0000-7000-8000-000000000001
   [ ] Task2 #01950000-0000-7000-8000-000000000001
```

**Scope:** File-level check is mandatory. Cross-file checking is optional (requires project context).


These rules enforce team conventions and best practices. All are configurable.

#### I006: Metadata Order
**Severity:** Info
**Fixable:** Yes (if auto-reordering is enabled)

Metadata should follow canonical order: `$` → `!` → `*` → `+` → `@` → `D` → `R:` → `%` → `#`.

```actions
ℹ️  [ ] Task !1 $ Desc  # Priority before description
✅ [ ] Task $ Desc !1   # Canonical order
```

**Configuration:** `enforce_metadata_order` (default: false)

**Rationale:** Consistent ordering improves scanability across files.

#### I007: High Priority Without Do-Date
**Severity:** Info
**Fixable:** No

Priority 1-2 actions without do-dates may need scheduling.

```actions
ℹ️  [ ] Critical task !1  # High priority but no schedule
✅ [ ] Critical task !1 @2025-01-20
```

**Configuration:** `high_priority_threshold` (default: 2)

#### I008: Blocked Without Description
**Severity:** Info
**Fixable:** No

Blocked actions (`[=]`) should explain why in the description.

```actions
ℹ️  [=] Task !1
✅ [=] Task $ Waiting for API access !1
```


#### I009: Child Higher Priority Than Parent
**Severity:** Info
**Fixable:** No

Child actions with higher priority than parents may indicate organizational issues.

```actions
ℹ️  [ ] Parent !3
   >[ ] Child !1  # Higher priority than parent
✅ [ ] Parent !1
   >[ ] Child !2
```

**Configuration:** `check_child_priority` (default: false)


We keep the hierarchy limited for process requirements but many 

#### W003: Excessive Duration
**Severity:** Info
**Fixable:** No

Very long durations may indicate data entry errors.

```actions
ℹ️  [ ] Task @2025-01-20 D10080  # 1 week = 168 hours
✅ [ ] Task @2025-01-20 D120  # 2 hours
```

**Configuration:** `max_duration_minutes` (default: 480 = 8 hours)


### 4. Content Quality (Info)

These rules check for common content issues.


## Configuration

Linters should support configuration files to customize rule behavior.

### Configuration Format

```toml
# .actions-lint.toml

[rules]
# Semantic rules (errors) - all default to enabled
E001.enabled = true
E002.enabled = true
# ... all E rules default to enabled

# Temporal rules
W001.enabled = true
W001.past_do_date_threshold_days = 14  # 2 weeks instead of 7

# Style rules
I001.enabled = false  # Don't enforce metadata order
I002.enabled = true
I002.high_priority_threshold = 3
I004.enabled = true
I004.max_name_length = 60
I006.enabled = true  # Require story assignment
```


## Linter Output Format

### Text Format (CLI)

```
tasks.actions:5:1: error[E001]: Completed action missing completed date
  |
5 | [x] Team meeting $ Discuss Q1 roadmap !1
  | ^^^ add completed date (%) or change state
  |
  = help: Add `%2025-01-03T10:00` or change state to `[ ]`

tasks.actions:12:5: warning[S001]: Missing space after state bracket
   |
12 | [x]Task
   |    ^ insert space here
   |
   = help: Change to `[x] Task`
```

### JSON Format (Machine-Readable)

```json
{
  "file": "tasks.actions",
  "diagnostics": [
    {
      "rule": "E001",
      "severity": "error",
      "line": 5,
      "column": 1,
      "message": "Completed action missing completed date",
      "suggestion": "Add `%2025-01-03T10:00` or change state to `[ ]`",
      "fixable": false
    },
    {
      "rule": "S001",
      "severity": "warning",
      "line": 12,
      "column": 5,
      "message": "Missing space after state bracket",
      "suggestion": "Change to `[x] Task`",
      "fixable": true,
      "fix": {
        "range": {"start": {"line": 12, "col": 3}, "end": {"line": 12, "col": 3}},
        "replacement": " "
      }
    }
  ]
}
```

## Code Actions and Fixes

Linters can provide **code actions** (LSP quick fixes) for some rules:

### Auto-fixable via Code Actions

- **Metadata reordering** (I001): If enabled, can automatically reorder to canonical sequence

### Suggested Fixes (Informational Only)

Most linting rules detect issues but cannot automatically fix them, as they require user judgment:

- **Adding completion dates** (E001): Linter can't guess the timestamp
- **Changing states** (E002): Requires understanding user intent
- **Removing duplicate IDs** (E005): Which one to keep?
- **Adding missing metadata** (W001, I002): User must decide values

Linters should provide **helpful suggestions** in diagnostics to guide users toward fixes.

Example workflow:

```bash
# Check for issues
actions-lint tasks.actions

# Use editor code actions (LSP) to apply suggested fixes interactively
# Or fix manually based on diagnostic suggestions
```

## Implementation Guidance

### Minimal Linter

A conformant minimal linter MUST:
1. Support all Error-level rules (E001-E011)
2. Allow configuration to disable rules
3. Report violations with line/column numbers
4. Support both file and stdin input

### Full-Featured Linter

A complete linter SHOULD:
1. Support all rule categories (E, W, I, S)
2. Provide auto-fix for spacing rules
3. Support configuration files (.actions-lint.toml)
4. Provide JSON output for tool integration
5. Support inline ignore directives
6. Integrate with editors via LSP

### LSP Integration

For real-time editor feedback:

```typescript
// Publish diagnostics on file change
connection.sendDiagnostics({
  uri: documentUri,
  diagnostics: [
    {
      range: {start: {line: 4, character: 0}, end: {line: 4, character: 3}},
      severity: DiagnosticSeverity.Error,
      code: "E001",
      message: "Completed action missing completed date",
      source: "actions-lint"
    }
  ]
});

// Provide code actions for fixable rules
connection.onCodeAction((params) => {
  return [
    {
      title: "Add space after state bracket",
      kind: CodeActionKind.QuickFix,
      diagnostics: [/* matching diagnostic */],
      edit: {/* workspace edit */}
    }
  ];
});
```

## Relationship to Other Tools

| Tool | Purpose | When to Run |
|------|---------|-------------|
| **Parser** | Validate syntax | On every file read |
| **Formatter** | Fix ALL presentation (spacing, layout) | On save, pre-commit |
| **Linter** | Check semantic correctness & best practices | On save, pre-commit, CI |
| **LSP** | Real-time editor feedback | Continuous |

Recommended workflow:

```bash
# Pre-commit hook
tree-sitter parse file.actions || exit 1  # Syntax check
topiary format file.actions               # Format (handles all spacing)
actions-lint file.actions || exit 1       # Check semantic correctness
git add file.actions
```

**Note:** The formatter handles all presentation issues automatically. The linter only needs to check semantic correctness (E/W/I rules).

## Examples

### Clean File (No Issues)

```actions
[x] Team meeting $ Discuss Q1 roadmap !1 *Projects +Work @2025-01-20T14:00 D60 %2025-01-20T15:05
[ ] Take out trash @2025-01-21T19:00 R:FREQ=WEEKLY;BYDAY=TU #01950000-0000-7000-8000-000000000001
[ ] Review PR $ Check [[Documentation|https://example.com]] !2 +work
```

### File with Violations

```actions
# Error: E001 - Missing completed date
[x] Completed task !1

# Warning: W001 - Past do-date
[ ] Old task @2020-01-01

# Warning: W002 - Completed before scheduled
[x] Meeting @2025-01-20T14:00 %2025-01-20T10:00

# Info: I002 - High priority without do-date
[ ] Critical !1

# Info: I001 - Metadata order
[ ] Task !1 $ Wrong order
```

### Linter Output

```
tasks.actions:2:1: error[E001]: Completed action missing completed date
tasks.actions:5:1: warning[W001]: Not-started action with past do-date (>5 years old)
tasks.actions:8:1: warning[W002]: Completed 4 hours before scheduled time
tasks.actions:11:1: info[I002]: High priority action without do-date
tasks.actions:14:1: info[I001]: Metadata not in canonical order

5 problems (1 error, 2 warnings, 2 info)
Code actions available for 1 rule (I001)
```

## Version History

### 1.1.0 (2026-01-03)
- **Breaking change:** Removed spacing rules (S001-S004)
- Spacing is now handled entirely by the formatter
- Linter focuses exclusively on semantic correctness, temporal logic, and style preferences
- 28 rules total (11 errors, 4 warnings, 13 info)
- Updated philosophy section to clarify formatter vs linter boundary

### 1.0.0 (2026-01-03)
- Initial specification
- Defined 5 rule categories (Spacing, Semantic, Temporal, Style, Content)
- 32 rules total (11 errors, 4 warnings, 17 info)
- Configuration format and severity levels
- Auto-fix guidance
