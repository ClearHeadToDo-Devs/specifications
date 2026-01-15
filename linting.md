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
    **Fixable:** No

    Duration (`D`) requires a do-date (`@`) to be meaningful.

    ```actions
    [ ] Meeting D60
    [ ] Meeting @2025-01-20T14:00 D60
    ```

    **Rationale:** A duration without a start time is nonsensical.

#### E002: Recurrence Without Do-Date
    **Fixable:** No

    Recurrence (`R:`) requires a do-date (`@`) as the starting point.

    ```actions
    [ ] Task R:FREQ=DAILY
    [ ] Task @2025-01-20 R:FREQ=DAILY
    ```

#### E003: Empty Context Tag
    **Fixable:** No

    Context tags cannot be empty.

    ```actions
    [ ] Task +
    [ ] Task +work,home
    [ ] Task +work +home
    ```


#### E004: Orphaned Child Marker
    **Fixable:** No

    Child actions (`>`) must follow a parent action at the appropriate depth.

    ```actions
    >[ ] No parent
    [ ] Parent
    >[ ] Child
    ```

#### E005: Skipped Hierarchy Level
    **Fixable:** No

    Cannot skip depth levels (e.g., depth 0 → depth 2).

    ```actions
    [ ] Root
    >>[ ] Skipped depth 1
    [ ] Root
    >[ ] Depth 1
    >>[ ] Depth 2
    ```

#### E006: Invalid UUID Format
    **Fixable:** No

    UUIDs must follow standard format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (UUIDv7 recommended).

    ```actions
    [ ] Task #not-a-uuid
    [ ] Task #123
    [ ] Task #01950000-0000-7000-8000-000000000001
    ```

    UUIDs are critical for the unique identification of actions across files and systems.

    V7 adds the benefit of being time-sortable, which is useful for tracking creation order.

#### E007: No State Brackets
    **Fixable:** Yes

    ```actions
    bad action
    [ ] good action
    ```

    State is a fundamental part of the syntax and actions without state are considered invalid

### 2. Warnings 

    These rules check for suspicious date/time relationships.


#### W005: Hierarchy Depth Exceeded
    **Fixable:** No

    Maximum nesting depth is 5 levels (depth 0-5).

    ```actions
    [ ] Root >>>>>>[ ] Too deep (depth 6)
    [ ] Root >>>>>[ ] OK (depth 5)
    ```

    This may or may not be a breaking issue depending on parser implementation. but either way, the process also discourages deep nesting for clarity.

#### W006: Completed Parent with Uncompleted Children
    **Fixable:** No

    A parent action cannot be marked as completed if it has children that are still active.

    ```actions
    [x] Parent
    >[ ] Uncompleted child
    [x] Parent
    >[x] Completed child
    ```

    **Rationale:** Archiving and completion logic typically operates on trees. A "completed" parent with "active" work is semantically inconsistent.

#### W007: Uncompleted Parent with All Children Completed
    **Fixable:** No

    A parent action that is not completed but has all its children marked as completed should likely be completed as well.

    ```actions
    [ ] Parent
    >[x] Child 1
    >[x] Child 2
    [x] Parent
    >[x] Child 1
    >[x] Child 2
    ```

    **Rationale:** Serves as a nudge to the user to wrap up the parent action once all its sub-tasks are finished.

#### W008: Missing Creation Date
    **Fixable:** Yes (derive from UUID v7 or add current date)

    Actions should ideally have a creation date, either explicitly via the `^` marker or implicitly via a UUID v7 in the `#` field.

    ```actions
    [ ] New task
    [ ] New task ^2026-01-03
    [ ] New task #01942db4-0000-7000-8000-000000000001
    ```

    **Rationale:** Creation timestamps help with aging analysis and history tracking, but are not required for correctness. This is a best practice for teams wanting detailed action tracking, but can be disabled for casual use.

#### W009: Creation Date in Future
    **Fixable:** No

    The creation date (`^`) cannot be in the future relative to the current system time.

    ```actions
    [ ] Task ^2099-01-01
    ```

#### W010: Completion Before Creation
    **Fixable:** No

    The completion date (`%`) cannot be before the creation date (`^`).

    ```actions
    [x] Impossible Task ^2026-01-03 %2026-01-01
    ```

#### W011: Circular Dependency
    **Severity:** Warning
    **Fixable:** No

    Actions cannot have circular dependencies (directly or transitively).

    ```actions
    [ ] Task A < Task B
    [ ] Task B < Task A
    ```

    **Rationale:** Circular dependencies are logically impossible — neither action can ever be completed.

    **Fix suggestion:** Review the dependency structure and break the cycle by removing or reworking one of the dependencies.

#### W012: Invalid Predecessor Reference
    **Severity:** Warning
    **Fixable:** No

    A predecessor references an action that doesn't exist in the workspace.

    ```actions
    [ ] Task < Nonexistent Action
    ```

    **Rationale:** Actions should only depend on other actions that actually exist.

    **Fix suggestion:** Check the name/UUID spelling, or create the missing predecessor action.

#### W013: Ambiguous Predecessor Reference
    **Severity:** Warning
    **Fixable:** No

    Multiple actions in the workspace match the predecessor name. Use UUID to disambiguate.

    ```actions
    [ ] Deploy < setup  # Three "setup" actions exist in workspace
    [ ] Deploy < #01951111-cfa6-718d-b303-d7107f4005b3
    ```

    **Rationale:** Name-based references should be unambiguous. When multiple matches exist, recommend UUIDs for clarity.

    **Configuration:** `require_uuid_for_ambiguous_predecessors` (default: false) — if true, escalates to error severity.


### 3. Style and Conventions (Info)

#### I001: Completed State Requires Completed Date
    **Severity:** Info
    **Fixable:** No (requires user input)

    Actions with state `[x]` (completed) must have a completed date (`%`).

    ```actions
    [x] Task $ Description !1
    [x] Task $ Description !1 %2025-01-20T15:00
    ```

    **Rationale:** Completion tracking requires knowing *when* the action was completed.

    **Fix suggestion:** Add `%YYYY-MM-DDTHH:MM` or change state to `[ ]`.

#### I002: Completed Date Requires Completed State
    **Severity:** Info
    **Fixable:** No

    Actions with completed date (`%`) must have state `[x]`.

    ```actions
    [ ] Task %2025-01-20
    [x] Task %2025-01-20
    ```

    **Rationale:** A completed date without completed state is contradictory.

    We may consider reopen date if requested but for now it is assumed that actions are completed if they have a completed date.

#### I003: Invalid Priority Level
    **Severity:** Info
    **Fixable:** No

    Priority must be 1-5 (1 = highest, 5 = lowest).

    ```actions
    [ ] Task !0
    [ ] Task !6
    [ ] Task !high
    [ ] Task !1
    ```

    **Rationale:** Priority levels are defined by the format specification.

    While we dont necessarily stop you from putting higher values, for the sake of the process, we conform to the eisenhower matrix


#### I004: Duplicate ID
    **Severity:** Info
    **Fixable:** No

    Action IDs must be unique within the file (and ideally across the project).

    ```actions
    [ ] Task1 #00000000-0000-0000-0000-000000000000
    [ ] Task2 #00000000-0000-0000-0000-000000000000
    ```

    **Scope:** File-level check is mandatory. Cross-file checking is optional (requires project context).


    These rules enforce team conventions and best practices. All are configurable.

#### I006: Metadata Order
    **Severity:** Info
    **Fixable:** Yes (if auto-reordering is enabled)

    Metadata should follow canonical order: `$` → `!` → `*` → `+` → `@` → `D` → `R:` → `%` → `#`.

    ```actions
    [ ] Task !1 $ Desc  # Priority before description
    [ ] Task $ Desc !1   # Canonical order
    ```

    **Configuration:** `enforce_metadata_order` (default: false)

    **Rationale:** Consistent ordering improves scanability across files.

#### I007: High Priority Without Do-Date
    **Severity:** Info
    **Fixable:** No

    Priority 1-2 actions without do-dates may need scheduling.

    ```actions
    [ ] Critical task !1  # High priority but no schedule
    [ ] Critical task !1 @2025-01-20
    ```

    **Configuration:** `high_priority_threshold` (default: 2)

#### I008: Blocked Without Description
    **Severity:** Info
    **Fixable:** No

    Blocked actions (`[=]`) should explain why in the description.

    ```actions
    [=] Task !1
    [=] Task $ Waiting for API access !1
    ```


#### I009: Child Higher Priority Than Parent
    **Severity:** Info
    **Fixable:** No

    Child actions with higher priority than parents may indicate organizational issues.

    ```actions
    [ ] Parent !3
    >[ ] Child !1  # Higher priority than parent
    [ ] Parent !1
    >[ ] Child !2
    ```

    **Configuration:** `check_child_priority` (default: false)


    We keep the hierarchy limited for process requirements but many 

#### I010: Excessive Duration
    **Severity:** Info
    **Fixable:** No

    Very long durations may indicate data entry errors.

    ```actions
    [ ] Task @2025-01-20 D10080  # 1 week = 168 hours
    [ ] Task @2025-01-20 D120  # 2 hours
    ```

    **Configuration:** `max_duration_minutes` (default: 480 = 8 hours)

#### I011: Past Do-Date on Not-Started Action
    **Severity:** Warning
    **Fixable:** No

    Actions with state `[ ]` (not started) probably shouldn't have do-dates in the past.

    ```actions
    [ ] Task @2020-01-01  # Several years ago
    [x] Task @2020-01-01 %2020-01-02  # Completed in the past is fine
    [ ] Task @2026-01-20  # Future is fine
    ```

    **Rationale:** Likely indicates stale actions that should be updated or archived.

    **Configuration:** `past_do_date_threshold_days` (default: 7) - how many days past before warning.


