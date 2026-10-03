---
title: actions file specification
description: File specification for actions in .actions files
author: primary_desktop
categories: Reference
created: 2025-01-19T03:16:49-0800
updated: 2026-04-20T00:00:00-0800
version: 2.0.0
---

This specification defines the `*.actions` format.

Under Decision 21, `.actions` files represent **actions** only (the executable units of work). Recurring schedules and other plan timing logic are represented in `.ics` files. See [ICS Schedule Specification](./ics_schedule_spec.md).

# Scope and Principles

- `.actions` is a plaintext interface for actions.
- It must remain easy to read and write by hand.
- Parsers should be whitespace-tolerant and symbol-driven.
- The format should remain backwards-parseable over time.

## Ontological role

- **Objectives** are higher-level outcomes.
- **Plans/Schedules** live in `.ics` files.
- **Actions** live in `.actions` files.

This split keeps scheduling concerns in calendar tooling and keeps `.actions` focused on actionable execution records.

# Parser Guidance

## Special characters

Reserved characters must be escaped with `\` in freeform fields unless otherwise noted.

Canonical property order (recommended for formatters and linters):

1. `[` `]` state marker
2. `=` alias
3. `$` description block
4. `~` sequential-children marker
5. `!` priority
6. `*` objective/parent reference
7. `+` context tag
8. `@` do date/time
9. `:` due date/time
10. `^` created date/time
11. `%` completed date/time
12. `#` identifier
13. `<` predecessor reference
14. `>` child depth marker

## Reference styles

References are resolved in workspace scope and may be represented as:

1. Full UUID (`01951111-cfa6-718d-b303-d7107f4005b3`)
2. Short UUID prefix (`01951111`)
3. Alias (`staging-deploy`)
4. Name (`Wash clothes`)

Resolution order:

1. Full UUID match
2. Short UUID prefix match
3. Alias match (case-insensitive)
4. Name match (case-insensitive)

Unresolved references should produce lint warnings.

# Date and Time

Dates/times should follow ISO 8601-compatible formats.

Supported date forms:

- `YYYY-MM-DD`
- `YYYYMMDD`

Supported time forms:

- `hh:mm:ss.sss` / `hhmmss.sss`
- `hh:mm:ss` / `hhmmss`
- `hh:mm` / `hhmm`
- `hh`

Timezones are optional; local time is assumed when omitted. Offsets and `Z` are allowed.

A date covers its whole day. A date and time is an instant, however precisely it
is written: `T17:00` and `T17:00:00` are the same instant. A range `start/end` is
half-open: it begins at the start's first instant and ends where the end does, a
date's following midnight or a time itself. `@` and `:` read dates, times and
ranges the same way (Decisions 47 and 51).

# Field Semantics

## Depth (required for children)

Children start with one or more `>` markers. Whitespace indentation is presentation only and should not affect parsing.

## State (required)

- `[ ]` not started
- `[x]` completed
- `[-]` in progress
- `[=]` blocked/awaiting
- `[_]` cancelled

## Name (required)

Primary human-readable label for the action.

## Description (optional)

Description blocks begin and end with a line that starts with `$`:

```actions
[ ] Weekly review
    $ Review commitments and update priorities.
    include links like [[agenda|https://example.com/agenda]] when needed.
    $
```

## Links (optional inline)

Wiki-style links are supported in names and descriptions:

- `[[text|url]]`
- `[[url]]`

Escape literal link tokens with `\[\[`, `\]\]`, and `\|`. Because `[` may begin a link, a literal standalone opening bracket in a description must also be escaped as `\[`; an unescaped lone `[` is a parser-integrity error rather than prose that tools may reinterpret.

Links may span syntactically insignificant whitespace, including newlines. An unescaped `[` inside link content is reserved as a structural synchronization point: when a closing `]]` is missing, it lets Tree-sitter insert a `MISSING` close before the next action's `[state]` marker rather than consuming that action. The recovered link remains available for diagnostics, but the document is not eligible for formatting or semantic mutation until fixed.

## Priority (optional)

`!<number>` where lower numbers are higher urgency by convention.

## Parent / Objective reference (optional)

`*<reference>` links a root act to an objective or higher-level grouping. Objective path notation is allowed, for example: `*work/clearhead/docs`.

## Context tags (optional)

Contexts are designated by `+` tags. The **canonical** form is a single `+` group with comma-separated tags, which is what formatters emit:

```actions
[ ] Prepare deck +work,meeting,client
```

The space-separated form is also **accepted** and parsed losslessly — every `+` group is collected, not just the last:

```actions
[ ] Prepare deck +work +meeting +client
```

Parsers must collect tags from all context nodes; keeping only the final group is silent data loss (see DECISIONS.md Decision 33). Tag hierarchies are configured in [configuration.md](./configuration.md).

## Alias (optional)

Aliases provide stable references independent of name changes:

```actions
[ ] Deploy staging build =staging-deploy
```

## Sequential children (optional)

`~` on a parent means direct children are implicitly sequential.

## Predecessors (optional)

`<ref>` denotes logical dependencies that must be closed before this act is dependency-clean.

## Do date/time (optional)

`@` is intent: when the Action is planned to be worked. It bounds nothing; the
Action may be worked before or after it. It takes one of two forms:

- `@<datetime>`: the planned start. A date alone plans the whole day, as an
  all-day event; a date and time plans a point.
- `@<datetime>/<datetime>`: an ISO 8601 interval, a planned block. Only the full
  `start/end` form is valid, as for `:`.

The block is read as any range is ([Date and Time](#date-and-time)), as a
calendar reads one: `@2026-10-03T09:00/2026-10-03T09:30` is thirty minutes and
`@2026-10-03/2026-10-05` is three whole days.

Duration is never written; it is the length of the `@` block. Earlier files
wrote it as `D<minutes>` after `@` (`@2026-10-03T09:00 D15`); parsers should
keep reading that form, and formatters write it as the equivalent block
(`@2026-10-03T09:00/2026-10-03T09:15`). A `D` after a date-only `@` has no
equivalent block; it is dropped, and the whole day stays planned.

## Due date/time (optional)

`:` is the Action's window: when it can and must be done. It takes one of two
forms:

- `:<datetime>`: a deadline only.
- `:<datetime>/<datetime>`: an ISO 8601 interval, a lower bound ("not before")
  and a deadline. Only this full `start/end` form is valid: no ISO 8601
  durations and no abbreviated end.

The window is read as any range is ([Date and Time](#date-and-time)): it opens
at its lower bound, and the Action is late from where its deadline ends. So
`:2026-10-05` is late from `2026-10-06T00:00`, and `:2026-10-05T17:00` is late
from 17:00.

Action hierarchy composes windows without changing the locally stored values.
An Action's effective window opens at the latest lower bound asserted by itself
or any ancestor and closes at the earliest deadline asserted by itself or any
ancestor. A missing bound therefore inherits an ancestor's naturally, while a
child may narrow the inherited window. `@` is not inherited.

Coherence:

- A planned block outside the effective window is a warning: `@` starting
  before the window opens, or its block ending after it closes.
- A local window bound outside an ancestor's window is a warning.
- An empty effective window, which opens at or after it closes, is a violation,
  as is an `@` block that ends at or before it starts.

Queries use the effective window, but tools must not write inherited bounds into
source unless the user explicitly requests a materializing operation.

Work that can happen outside an Action's window, such as preparing before it
opens, belongs in its own Action with its own window, related by `<` where
order matters.

Note: recurrence is not represented in `.actions`.

## Completed date/time (optional)

`%<datetime>` records completion timestamp.

## Created date/time (optional)

`^<datetime>` records creation timestamp.

If missing, tooling may derive this from UUIDv7 timestamp data when present.

## Identifier (optional)

`#<uuid>` stores a stable identifier.

- Ad-hoc/manual acts typically use UUIDv7.
- Generated acts may use deterministic UUIDv5 based on external schedule identity (see [ics_schedule_spec.md](./ics_schedule_spec.md)).

# Non-goals for .actions

- RRULE or other recurrence syntax
- Calendar event object semantics
- Embedded schedule definition

Those belong to `.ics` and schedule expansion workflows.

# Examples

Examples are in [examples/README.md](./examples/README.md).
