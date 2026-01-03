---
title: Actions File Linting Specification
description: Optional checks for correctness, consistency, and best practices in .actions files
author: backup-admin
categories: Reference
created: 2026-01-03
version: 1.0.0
---

# Actions File Linting Specification

This specification defines optional linting rules for `.actions` files. While the [action_specification.md](./action_specification.md) defines valid syntax and [formatting_specification.md](./formatting_specification.md) defines structural layout, this document defines quality checks that detect potential issues without changing file semantics.

## Philosophy

### Linting vs Formatting

- **Formatting** enforces structural layout (vertical spacing, indentation)
- **Linting** detects correctness, consistency, and style issues
- **Parsing** validates syntax

A linter is *optional* and *configurable* - teams choose which rules to enforce based on their workflow.

### Design Principles

1. **Non-destructive** - Linters report issues, they don't automatically fix semantic problems
2. **Configurable** - Rules have severity levels (error, warning, info) and can be disabled
3. **Helpful** - Messages guide users toward fixes with clear explanations
4. **Fast** - Checks should be efficient enough for real-time editor integration
5. **Layered** - Rules grouped by concern (correctness, style, best practices)

## Severity Levels

Linting rules are categorized by severity:

| Level | Symbol | Meaning | Recommended Action |
|-------|--------|---------|-------------------|
| **Error** | ❌ | Violates semantic correctness | Must fix |
| **Warning** | ⚠️ | Likely mistake or bad practice | Should fix |
| **Info** | ℹ️ | Suggestion or style preference | Consider fixing |

## Rule Categories

### 1. Spacing (Fixable)

These rules check horizontal spacing that the formatter cannot enforce due to grammar constraints.

#### S001: Space After State
**Severity:** Warning
**Fixable:** Yes

State brackets should be followed by exactly one space.

```actions
❌ [x]Task
❌ [x]  Task
✅ [x] Task
```

**Rationale:** Consistent spacing improves readability. While semantically equivalent, `[x]Task` is harder to scan.

#### S002: Space Before Metadata
**Severity:** Warning
**Fixable:** Yes

Each metadata item should be preceded by exactly one space.

```actions
❌ [x] Task$Desc!1*Project
❌ [x] Task  $  Desc
✅ [x] Task $ Desc !1 *Project
```

#### S003: Space After Description Icon
**Severity:** Warning
**Fixable:** Yes

The `$` icon should be followed by exactly one space before the description text.

```actions
❌ [ ] Task $Desc
❌ [ ] Task $  Desc
✅ [ ] Task $ Desc
```

**Exception:** Empty descriptions are allowed: `[ ] Task $`

#### S004: No Space Around Value Icons
**Severity:** Info
**Fixable:** Yes

Non-description metadata icons (`!`, `*`, `+`, `@`, `D`, `R:`, `%`, `#`) should have no space between icon and value.

```actions
❌ [ ] Task ! 1
❌ [ ] Task * Project
✅ [ ] Task !1 *Project
```

**Rationale:** These values are terse identifiers, not prose. Spacing makes them harder to scan: `! 1` looks like "exclamation one" rather than "priority one".

### 2. Semantic Correctness (Errors)

These rules detect logical inconsistencies that likely indicate mistakes.

#### E001: Completed State Requires Completed Date
**Severity:** Error
**Fixable:** No (requires user input)

Actions with state `[x]` (completed) must have a completed date (`%`).

```actions
❌ [x] Task $ Description !1
✅ [x] Task $ Description !1 %2025-01-20T15:00
```

**Rationale:** Completion tracking requires knowing *when* the action was completed.

**Fix suggestion:** Add `%YYYY-MM-DDTHH:MM` or change state to `[ ]`.

#### E002: Completed Date Requires Completed State
**Severity:** Error
**Fixable:** No

Actions with completed date (`%`) must have state `[x]`.

```actions
❌ [ ] Task %2025-01-20
✅ [x] Task %2025-01-20
```

**Rationale:** A completed date without completed state is contradictory.

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

#### E004: Invalid UUID Format
**Severity:** Error
**Fixable:** No

UUIDs must follow standard format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (UUIDv7 recommended).

```actions
❌ [ ] Task #not-a-uuid
❌ [ ] Task #123
✅ [ ] Task #01950000-0000-7000-8000-000000000001
```

#### E005: Duplicate ID
**Severity:** Error
**Fixable:** No

Action IDs must be unique within the file (and ideally across the project).

```actions
❌ [ ] Task1 #01950000-0000-7000-8000-000000000001
   [ ] Task2 #01950000-0000-7000-8000-000000000001
```

**Scope:** File-level check is mandatory. Cross-file checking is optional (requires project context).

#### E006: Duration Without Do-Date
**Severity:** Error
**Fixable:** No

Duration (`D`) requires a do-date (`@`) to be meaningful.

```actions
❌ [ ] Meeting D60
✅ [ ] Meeting @2025-01-20T14:00 D60
```

**Rationale:** A duration without a start time is nonsensical.

#### E007: Recurrence Without Do-Date
**Severity:** Error
**Fixable:** No

Recurrence (`R:`) requires a do-date (`@`) as the starting point.

```actions
❌ [ ] Task R:FREQ=DAILY
✅ [ ] Task @2025-01-20 R:FREQ=DAILY
```

#### E008: Empty Context Tag
**Severity:** Error
**Fixable:** No

Context tags cannot be empty.

```actions
❌ [ ] Task +
❌ [ ] Task +work,,home
✅ [ ] Task +work,home
```

#### E009: Hierarchy Depth Exceeded
**Severity:** Error
**Fixable:** No

Maximum nesting depth is 5 levels (depth 0-5).

```actions
❌ [ ] Root >>>>>>[ ] Too deep (depth 6)
✅ [ ] Root >>>>>[ ] OK (depth 5)
```

#### E010: Orphaned Child Marker
**Severity:** Error
**Fixable:** No

Child actions (`>`) must follow a parent action at the appropriate depth.

```actions
❌ >[ ] No parent
✅ [ ] Parent
   >[ ] Child
```

#### E011: Skipped Hierarchy Level
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

### 3. Temporal Logic (Warnings)

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
⚠️  [x] Meeting @2025-01-20T14:00 %2025-01-20T10:00  # 4 hours early
✅ [x] Meeting @2025-01-20T14:00 %2025-01-20T14:30  # Slightly late is normal
```

**Configuration:** `early_completion_threshold_minutes` (default: 60)

#### W003: Excessive Duration
**Severity:** Info
**Fixable:** No

Very long durations may indicate data entry errors.

```actions
ℹ️  [ ] Task @2025-01-20 D10080  # 1 week = 168 hours
✅ [ ] Task @2025-01-20 D120  # 2 hours
```

**Configuration:** `max_duration_minutes` (default: 480 = 8 hours)

#### W004: Very Old Action
**Severity:** Info
**Fixable:** No

Not-started or in-progress actions with very old do-dates may need review.

```actions
ℹ️  [ ] Ancient task @2020-01-01  # 5+ years old
```

**Configuration:** `old_action_threshold_days` (default: 365)

### 4. Style and Conventions (Info)

These rules enforce team conventions and best practices. All are configurable.

#### I001: Metadata Order
**Severity:** Info
**Fixable:** Yes (if auto-reordering is enabled)

Metadata should follow canonical order: `$` → `!` → `*` → `+` → `@` → `D` → `R:` → `%` → `#`.

```actions
ℹ️  [ ] Task !1 $ Desc  # Priority before description
✅ [ ] Task $ Desc !1   # Canonical order
```

**Configuration:** `enforce_metadata_order` (default: false)

**Rationale:** Consistent ordering improves scanability across files.

#### I002: High Priority Without Do-Date
**Severity:** Info
**Fixable:** No

Priority 1-2 actions without do-dates may need scheduling.

```actions
ℹ️  [ ] Critical task !1  # High priority but no schedule
✅ [ ] Critical task !1 @2025-01-20
```

**Configuration:** `high_priority_threshold` (default: 2)

#### I003: Blocked Without Description
**Severity:** Info
**Fixable:** No

Blocked actions (`[=]`) should explain why in the description.

```actions
ℹ️  [=] Task !1
✅ [=] Task $ Waiting for API access !1
```

#### I004: Action Name Too Long
**Severity:** Info
**Fixable:** No

Very long action names hurt readability and should use descriptions instead.

```actions
ℹ️  [ ] This is a really long action name that should probably be split into a short name and a description
✅ [ ] Implement feature $ Split long text into name + description
```

**Configuration:** `max_name_length` (default: 50)

#### I005: Missing Context
**Severity:** Info
**Fixable:** No

Actions may benefit from context tags for organization.

```actions
ℹ️  [ ] Call dentist
✅ [ ] Call dentist +personal,phone
```

**Configuration:** `require_contexts` (default: false)

#### I006: Missing Story Assignment
**Severity:** Info
**Fixable:** No

Root actions may benefit from story/project assignment.

```actions
ℹ️  [ ] Implement authentication !1
✅ [ ] Implement authentication !1 *Security-Project
```

**Configuration:** `require_story` (default: false)

#### I007: Child Higher Priority Than Parent
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

### 5. Content Quality (Info)

These rules check for common content issues.

#### I008: TODO/FIXME Markers
**Severity:** Info
**Fixable:** No

TODO/FIXME markers in descriptions may indicate incomplete planning.

```actions
ℹ️  [ ] Task $ TODO: figure out the details
✅ [ ] Task $ Complete description with clear next steps
```

**Configuration:** `detect_todo_markers` (default: true), `todo_markers` (default: `["TODO", "FIXME", "XXX"]`)

#### I009: Question Marks in Name
**Severity:** Info
**Fixable:** No

Question marks may indicate uncertainty or incomplete planning.

```actions
ℹ️  [ ] Maybe do this?
✅ [ ] Complete specific action
```

**Configuration:** `detect_uncertainty_markers` (default: false)

#### I010: All Caps Name
**Severity:** Info
**Fixable:** No

All-caps names may indicate shouting or improper emphasis.

```actions
ℹ️  [ ] URGENT TASK
✅ [ ] Urgent task !1  # Use priority instead
```

**Configuration:** `detect_all_caps` (default: false)

## Configuration

Linters should support configuration files to customize rule behavior.

### Configuration Format

```toml
# .actions-lint.toml

[rules]
# Spacing rules
S001.enabled = true
S001.severity = "warning"
S002.enabled = true
S003.enabled = true
S004.enabled = false  # Team prefers spaces around all icons

# Semantic rules (errors)
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

### Severity Overrides

Users can change severity levels:

```toml
[rules]
W001.severity = "error"  # Treat past do-dates as errors
I002.severity = "warning"  # Promote high-priority-without-date to warning
```

### Ignore Directives

Inline comments can suppress warnings:

```actions
[ ] Legacy task @2020-01-01  # lint-ignore W001
```

Or disable for entire file:

```actions
# lint-disable W001, I002

[ ] File contents...
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

## Auto-Fix Behavior

Some rules are fixable automatically:

### Safe Fixes (Apply Automatically with `--fix`)

- **Spacing rules** (S001-S004): Mechanical changes, no semantic impact
- **Metadata reordering** (I001): If enabled and no ambiguity

### Suggested Fixes (Require User Confirmation)

- **Adding completion dates**: Linter can't guess the timestamp
- **Changing states**: Requires understanding user intent
- **Removing duplicate IDs**: Which one to keep?

Example fix workflow:

```bash
# Check for issues
actions-lint tasks.actions

# Auto-fix spacing
actions-lint --fix tasks.actions

# Interactive fix for semantic issues
actions-lint --fix-interactive tasks.actions
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
| **Formatter** | Fix structural layout | On save, pre-commit |
| **Linter** | Check quality/correctness | On save, pre-commit, CI |
| **LSP** | Real-time editor feedback | Continuous |

Recommended workflow:

```bash
# Pre-commit hook
tree-sitter parse file.actions || exit 1  # Syntax check
topiary format file.actions               # Format
actions-lint --fix file.actions           # Auto-fix spacing
actions-lint file.actions || exit 1       # Check for errors
git add file.actions
```

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

# Warning: S001 - Missing space after state
[x]Another task

# Warning: W001 - Past do-date
[ ] Old task @2020-01-01

# Info: I002 - High priority without do-date
[ ] Critical !1

# Info: I001 - Metadata order
[ ] Task !1 $ Wrong order
```

### Linter Output

```
tasks.actions:2:1: error[E001]: Completed action missing completed date
tasks.actions:5:1: warning[S001]: Missing space after state bracket
tasks.actions:8:1: warning[W001]: Not-started action with past do-date (>5 years old)
tasks.actions:11:1: info[I002]: High priority action without do-date
tasks.actions:14:1: info[I001]: Metadata not in canonical order

5 problems (1 error, 2 warnings, 2 info)
1 error and 1 warning potentially fixable with --fix
```

## Version History

### 1.0.0 (2026-01-03)
- Initial specification
- Defined 5 rule categories (Spacing, Semantic, Temporal, Style, Content)
- 32 rules total (11 errors, 4 warnings, 17 info)
- Configuration format and severity levels
- Auto-fix guidance
