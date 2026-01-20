---
title: Actions File Linting Specification
description: Optional checks for correctness, consistency, and best practices in .actions files
author: backup-admin
categories: Reference
created: 2026-01-03
version: 1.1.0
---

# Actions File Linting Specification

This specification defines optional linting rules for `.actions` files. While the [action_specification.md](./action_specification.md) defines valid syntax and [formatting.md](./formatting.md) handles presentation (spacing, indentation), this document defines semantic quality checks that detect correctness issues, temporal problems, and style violations.

## Philosophy

This specification defines a **relaxed parser, strict linter** approach:

- **Relaxed parser:** Accepts most valid input into a parse tree structure. Even minor issues produce a parseable tree rather than parse errors.
- **Strict linter:** Performs rigorous checking of the parsed tree for correctness, consistency, and best practices.

This approach aligns with modern tooling like TypeScript, where the parser is permissive and the typechecker/linter provides strict validation.

### Severity Levels

Linter rules are categorized into three levels that map to LSP diagnostic severity:

- **Errors:** Logical inconsistencies that block core functionality (e.g., duration without do-date, circular dependencies)
- **Warnings:** Semantic issues that don't block functionality but may indicate problems (e.g., completed parent with uncompleted children, invalid dates)
- **Info:** Style violations and process improvements (e.g., metadata order, completed date missing)

### Linting vs Formatting

- **Formatter** enforces presentation (spacing, indentation, layout) - automatic, opinionated, zero-config
- **Linter** detects semantic issues, temporal problems, and style preferences - optional, configurable, informative
- **Parser** validates syntax with relaxed acceptance

The formatter handles everything about *how code looks*. The linter handles everything about *what code means* and whether it's correct, consistent, or following best practices.

A linter is *optional* and *configurable* - teams choose which rules to enforce based on their workflow. The formatter runs automatically (e.g., on save) and needs no configuration.

### Design Principles

1. **Relaxed parsing, strict linting** - Parser accepts most input, linter validates rigorously
2. **Non-destructive** - Linters report issues, they don't automatically fix semantic problems
3. **Configurable** - Rules have severity levels (error, warning, info) and can be disabled
4. **Helpful** - Messages guide users toward fixes with clear explanations
5. **Fast** - Checks should be efficient enough for real-time editor integration
6. **Layered** - Rules grouped by concern (correctness, style, best practices)

## Rule Categories

### 1. Correctness (Errors)

These rules detect logical inconsistencies that block core functionality. These are NOT parse errors - the parser accepts this input, but the linter identifies semantic problems.

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

    Context tags cannot be empty, including whitespace-only tags or trailing commas.

    ```actions
    [ ] Task +
    [ ] Task +work,,home
    [ ] Task +   
    [ ] Task +work,
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


#### W001: Hierarchy Depth Exceeded
    **Fixable:** No

    Maximum nesting depth is 5 levels (depth 0-5).

    ```actions
    [ ] Root >>>>>>[ ] Too deep (depth 6)
    [ ] Root >>>>>[ ] OK (depth 5)
    ```

    This may or may not be a breaking issue depending on parser implementation. but either way, the process also discourages deep nesting for clarity.

#### W002: Completed Parent with Uncompleted Children
    **Fixable:** No

    A parent action cannot be marked as completed if it has children that are still active.

    ```actions
    [x] Parent
    >[ ] Uncompleted child
    [x] Parent
    >[x] Completed child
    ```

    **Rationale:** Archiving and completion logic typically operates on trees. A "completed" parent with "active" work is semantically inconsistent.

#### W003: Uncompleted Parent with All Children Completed
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

#### W004: Missing Creation Date
    **Fixable:** Yes (derive from UUID v7 or add current date)

    Actions should ideally have a creation date, either explicitly via the `^` marker or implicitly via a UUID v7 in the `#` field.

    ```actions
    [ ] New task
    [ ] New task ^2026-01-03
    [ ] New task #01942db4-0000-7000-8000-000000000001
    ```

    **Rationale:** Creation timestamps help with aging analysis and history tracking, but are not required for correctness. This is a best practice for teams wanting detailed action tracking, but can be disabled for casual use.

#### W005: Creation Date in Future
    **Fixable:** No

    The creation date (`^`) cannot be in the future relative to the current system time.

    ```actions
    [ ] Task ^2099-01-01
    ```

#### W006: Completion Before Creation
    **Fixable:** No

    The completion date (`%`) cannot be before the creation date (`^`).

    ```actions
    [x] Impossible Task ^2026-01-03 %2026-01-01
    ```

#### W007: Circular Dependency
    **Fixable:** No

    Actions cannot have circular dependencies (directly or transitively).

    ```actions
    [ ] Task A < Task B
    [ ] Task B < Task A
    ```

    **Rationale:** Circular dependencies are logically impossible — neither action can ever be completed.

    **Fix suggestion:** Review the dependency structure and break the cycle by removing or reworking one of the dependencies.

#### W008: Invalid Predecessor Reference
    **Fixable:** No

    A predecessor references an action that doesn't exist in the workspace.

    ```actions
    [ ] Task < Nonexistent Action
    ```

    **Rationale:** Actions should only depend on other actions that actually exist.

    **Fix suggestion:** Check the name/UUID spelling, or create the missing predecessor action.

#### W009: Ambiguous Predecessor Reference
    **Fixable:** No

    Multiple actions in the workspace match the predecessor name. Use UUID or alias to disambiguate.

    ```actions
    [ ] Deploy < setup  # Three "setup" actions exist in workspace
    [ ] Deploy < 01951111-cfa6-718d-b303-d7107f4005b3
    [ ] Deploy < setup-alias  # Using alias is also valid
    ```

    **Rationale:** Name-based references should be unambiguous. When multiple matches exist, recommend UUIDs, short UUIDs, or aliases for clarity.

    **Configuration:** `require_uuid_for_ambiguous_predecessors` (default: false) — if true, escalates to error severity.

#### W010: Duplicate Alias
    **Fixable:** No

    Multiple actions in the workspace define the same alias.

    ```actions
    [ ] First task =deploy
    [ ] Second task =deploy  # Duplicate alias
    ```

    **Rationale:** Aliases must be unique for unambiguous reference resolution.

    **Fix suggestion:** Rename one of the aliases to be unique.

#### W011: Ambiguous Short UUID
    **Fixable:** No

    Multiple UUIDs in the workspace share the same 8-character prefix.

    ```actions
    [ ] Task A #01951111-aaaa-aaaa-aaaa-aaaaaaaaaaaa
    [ ] Task B #01951111-bbbb-bbbb-bbbb-bbbbbbbbbbbb
    [ ] Task C < 01951111  # Ambiguous - matches both
    ```

    **Rationale:** Short UUID references should resolve to exactly one action. While prefix collisions are rare, they can occur.

    **Fix suggestion:** Use the full UUID or an alias for the reference.

#### W012: Sequential Marker on Childless Action
    **Fixable:** No

    The `~` marker is used on an action with no children.

    ```actions
    [ ] Single task ~  # No children to sequence
    ```

    **Rationale:** The sequential marker only affects child actions. Using it on a leaf action has no effect and may indicate a mistake.


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

#### I012: Invalid Alias Format
    **Severity:** Info
    **Fixable:** No

    Alias names should contain only alphanumeric characters, underscores, and hyphens.

    ```actions
    [ ] Task =my alias  # Spaces not allowed
    [ ] Task =my@alias  # Special chars not allowed
    [ ] Task =my-alias  # Valid
    [ ] Task =my_alias  # Valid
    ```

    **Rationale:** Aliases are used as identifiers and should be simple, machine-friendly strings.

#### I013: Redundant Tag (Covered by Hierarchy)
    **Severity:** Info
    **Fixable:** Yes

    An action is tagged with both a child tag and its ancestor tag from the configured hierarchy.

    ```actions
    # Given config: terminal includes neovim
    [ ] Task +neovim,terminal  # "terminal" is redundant
    [ ] Task +neovim  # Correct - "terminal" is implied
    ```

    **Rationale:** The child tag already implies the parent. Listing both adds noise without value.

    **Configuration:** Requires `tag_hierarchies` to be configured.

#### I014: Story Path Depth Excessive
    **Severity:** Info
    **Fixable:** No

    Story paths with more than 4 levels may indicate over-organization.

    ```actions
    [ ] Task *work/dept/team/project/subproject/epic  # 6 levels deep
    [ ] Task *work/clearhead/cli  # 3 levels - reasonable
    ```

    **Configuration:** `max_story_path_depth` (default: 4)

    **Rationale:** Deep hierarchies become hard to navigate and may indicate scope creep.

#### I015: Empty Alias
    **Severity:** Info
    **Fixable:** No

    An alias marker `=` is present but no alias name follows.

    ```actions
    [ ] Task =
    [ ] Task =deploy  # Valid
    ```

    **Rationale:** An alias marker without a name serves no purpose.


