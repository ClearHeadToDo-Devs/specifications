---
title: ics schedule specification
description: Plan/schedule semantics in .ics files for action generation
author: primary_desktop
categories: Reference
created: 2026-04-20T00:00:00-0800
updated: 2026-04-20T00:00:00-0800
version: 1.0.0
---

This specification defines how `.ics` files represent schedules/plans and how they map into generated actions.

The core principle is separation of concerns:

- `.ics` owns schedule timing semantics.
- `.actions` owns action execution records.

See [action_file_format.md](./action_file_format.md) for action syntax.

# Scope

This document covers:

- `.ics` discovery and charter scope expectations
- VEVENT field mapping into schedule records
- Template linkage via DESCRIPTION convention
- Instance-count generation bounds
- Idempotent generation requirements
- External linkage keys carried onto generated acts

This document does not redefine RFC 5545.

# File Location and Discovery

Plan/schedule files are `.ics` files discovered using naming conventions in [workspace.md](./workspace.md).

Plans are stored as individual `.ics` files (one VEVENT per file) within a `plans/` directory per charter:

- `/plans/<charter-name>/<uid>.ics`

Each file within a charter's `plans/` directory is scoped to that charter. See [workspace.md](./workspace.md) for full directory structure.

# VEVENT Mapping

Each `VEVENT` represents one schedule definition.

Required/expected fields:

- `UID` (required): stable schedule identity from calendar source
- `SUMMARY` (recommended): human-readable schedule name
- `DTSTART` (required for expansion): anchor datetime
- `RRULE` (optional): recurrence semantics
- `DURATION` (optional): schedule-level duration hint
- `DESCRIPTION` (optional): if the first line starts with `template: <name>`, it binds a template for structural instantiation; remaining text is the plan description

If `RRULE` is absent, VEVENT is treated as a one-off schedule.

# External Identity Bridge

To avoid making core ontology calendar-specific while preserving deterministic behavior, generated actions should carry neutral linkage fields:

- `externalScheduleId` (series-level identifier)
- `externalOccurrenceKey` (instance-level identifier)

ICS mapping:

- `externalScheduleId <- VEVENT.UID`
- `externalOccurrenceKey <- RECURRENCE-ID` when present, otherwise canonicalized occurrence datetime

`externalOccurrenceKey` should be canonicalized as RFC3339.

# Expansion Semantics

`expand acts` (or equivalent workflow) should:

1. Read schedule VEVENTs for charter scope.
2. For each schedule, count open instances already present across both `<charter>.actions` and `<charter>.upcoming.actions` (open = `[ ]` not-started or `[-]` in-progress; cancelled `[_]` and completed `[x]` do not count).
3. Resolve the per-schedule `upcoming:` directive from VEVENT DESCRIPTION if present (see [DESCRIPTION Directives](#description-directives)); otherwise use the workspace-level `expansion_total_instances` and `expansion_primary_instances` from configuration.
4. Generate instances up to `total_instances` for this schedule (respecting the RRULE end date or count if present).
5. Resolve template, if DESCRIPTION contains a `template: <name>` binding.
6. Place the first `primary_instances` instances (by scheduled date ascending) into `<charter>.actions`; place remaining instances into `<charter>.upcoming.actions`.
7. Upsert — do not duplicate instances that already exist (matched by deterministic UUID).

This process must be idempotent: rerunning expansion for the same schedule must not create duplicates or change placement of already-existing instances.

## Instance Bounds

Generation is bounded by instance count, not by a date horizon. This makes expansion cadence-agnostic: a daily habit and a quarterly review both produce a predictable number of instances regardless of their recurrence frequency.

The two relevant config values (see [Configuration](./configuration.md)):

- `expansion_total_instances` (default: `2`) — total instances generated per schedule across both files. Must be > `expansion_primary_instances`.
- `expansion_primary_instances` (default: `1`) — how many of those land in the primary `<charter>.actions` file.

For a schedule where `total=2, primary=1`: the next upcoming occurrence lands in `<charter>.actions`; the one after lands in `<charter>.upcoming.actions`.

## DESCRIPTION Directives

The VEVENT DESCRIPTION field supports a block of `key: value` directives at the top before the human-readable description body. The parser reads leading lines that match `key: value` until it hits a blank line or a non-matching line.

Supported directives:

| Directive | Type | Description |
|---|---|---|
| `template` | string | Template name to expand per occurrence (e.g. `template: weekly-review`) |
| `upcoming` | integer | Per-schedule override for `expansion_primary_instances` — how many instances of this schedule stay in the primary file |

Example DESCRIPTION:
```
template: weekly-review
upcoming: 2

Notes about this recurring review go here.
```

If `upcoming:` is set on a schedule, it overrides the global `expansion_primary_instances` for that schedule only. `expansion_total_instances` continues to apply globally unless also overridden — a future directive key (`total:`) may be introduced for that purpose.

Calendar applications that do not understand these directives will simply display them as part of the event notes, which is acceptable.

Expansion must be idempotent.

For generated acts:

- Determine act identity from schedule identity + occurrence identity.
- Recommended: UUIDv5 derived from (`externalScheduleId`, `externalOccurrenceKey`).

Running expansion multiple times for the same schedule window must not create duplicates.

Ad-hoc acts (not schedule-derived):

- do not require external linkage fields
- typically use UUIDv7

# Template Resolution

When a `template: <name>` binding is present in the DESCRIPTION, resolve templates in this order:

1. Charter-local `templates/`
2. Workspace/platform-root `templates/`

If template resolution fails, implementations may:

- generate a single act from VEVENT summary/timing, and warn, or
- skip generation and warn

Behavior should be documented and consistent per implementation.

# Error Handling

Invalid VEVENTs should be non-fatal at file level.

Implementations should:

- continue processing other VEVENTs
- emit actionable diagnostics (file + event context + reason)

# Contract Boundaries

- Core ontology/domain stays source-agnostic.
- ICS semantics are integration-profile concerns.
- The bridge is external identity, not calendar class adoption.
