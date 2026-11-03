---
title: iCalendar Plan projection specification
description: VEVENT projections of Actions and Habits, fields and recurrence identity
categories: Reference
---

# iCalendar Plan projection specification

This specification defines RFC 5545 projections in each workspace's `<data_root>/plans/` vdir. The vdir is the complete integration boundary. CalDAV, vdirsyncer, Syncthing, Git, a mounted filesystem, or no transport may sit behind it. ClearHead does not depend on server accounts, hrefs, ETags or vendor metadata.

Actions are native work in ordinary `.actions` files. Habits are native recurring prescriptions in `<charter>.habits.actions`. A one-off Plan is not another domain entity: it projects an Action's `@` block. A recurring Plan projects a Habit. An unscheduled Action has no Plan. See [Action syntax](./action_file_format.md), [workspace layout](./workspace.md) and [process](./process.md).

## File location and discovery

Each resource is one `VCALENDAR` in `plans/<charter-scope>/<resource>.ics`, containing a VEVENT master and any same-UID `RECURRENCE-ID` overrides. ClearHead emits `<uid>.ics`; readers identify the resource by UID, not filename. Transport-selected filenames are preserved. Duplicate master identities, including mixed component kinds, are errors, never traversal-order winners.

Collection ownership follows the charter's canonical workspace anchor, not its alias, title or an arbitrary `next.actions` basename. See [Workspace](./workspace.md#plans).

## VEVENT-only integration

Plans use VEVENT only.

A component has UID, SUMMARY and DTSTART; optional DTEND (or imported DURATION), DESCRIPTION, RRULE, RDATE, EXDATE and occurrence overrides. Missing required fields and duplicate identities are actionable errors local to the resource; unrelated files continue.

The calendar shows the `@` block only. It is half-open: a DATE DTEND is the day after the last included date written in `@`; a time end is the written instant. `:` windows, lifecycle state, priority, contexts, hierarchy and dependencies stay local. Children are template steps, not independently recurring components.

Time frames (UTC, floating, all-day DATE and IANA TZID) are preserved. Unknown/custom zones are not interpreted as the machine's local zone. Regeneration must preserve RDATE, EXDATE, time frames, overrides awaiting materialization, alarms, unrecognized properties, extensions, calendar metadata, original UID and transport-selected path. These facts must survive loss of reconstructible local state.

### Description directives

Leading `key: value` lines are directives until a blank or non-directive line. `template: <name>` binds a named template. Directives are distinct from the human description; calendar edits must not silently turn a directive into ordinary prose. Inline Habit children win over a named binding, with a warning.

## One-off Plans

A scheduled, non-recurring Action realizes exactly one Plan. ClearHead-authored resources use the native Action UUID as UID. A genuinely new calendar-authored one-off keeps its arbitrary external UID and gets an independent native UUID. Transport identity is never native identity. Scheduling and calendar-edit outcomes are defined in [Process](./process.md#plans).

## Habits and occurrence identity

A Habit's native id is its line's `#uuid`; it is not derived from UID. Each Habit projects to one recurring VEVENT. Moving an occurrence changes DTSTART, never the original slot in RECURRENCE-ID. Series and occurrence edit outcomes are defined in [Process](./process.md#habits).

### Canonical slot keys (`slot-key-zone`)

Keys are ASCII strings, independent of the viewer or device zone. Seconds are always present. Equivalent lexical precision normalizes to seconds; nonzero fractional seconds retain their value without trailing zeroes. The prefix distinguishes value types:

| Frame | Original slot | Canonical key |
| --- | --- | --- |
| DATE | `20261026` | `D:2026-10-26` |
| Floating | `20261026T090000` | `F:2026-10-26T09:00:00` |
| UTC/offset | `2026-10-26T09:00:00-07:00` | `U:2026-10-26T16:00:00Z` |
| TZID | `TZID=America/Los_Angeles:20261026T090000` | `U:2026-10-26T16:00:00Z` |

For TZID slots, resolve in the series zone using RFC 5545 §3.3.5 (first occurrence in a fold, pre-gap offset for a nonexistent local time), not the host's zone. Preserve the frame separately for future expansion. In Los Angeles the fold slot `2026-11-01T01:30:00` keys as `U:2026-11-01T08:30:00Z`; the gap slot `2026-03-08T02:30:00` keys as `U:2026-03-08T10:30:00Z`. Devices in UTC, Los Angeles and Tokyo compute all these same keys. DATE and floating keys are never converted to UTC.

The native occurrence id is `UUIDv5(Habit UUID, "occurrence/" + key)`. A stamped step id is `UUIDv5(occurrence UUID, "step/" + template-step UUID)`, with lowercase hyphenated step UUID text. Template-step UUIDs are persisted before stamping: renaming or reordering a step never changes its id; a deliberately new step gets a new UUID. Derived ids are persisted on the generated lines. `app:slot` is the canonical key as `xsd:string`, not a viewer-resolved `xsd:dateTime`.

Transport occurrence addresses remain `(UID, RECURRENCE-ID)`. The durable native link is `(Habit UUID, canonical slot)`, including for history after a transport UID replacement. These are different addresses of the same occurrence, not interchangeable identity inputs.

## Field authority

Name (SUMMARY), human description (DESCRIPTION), planned start/end (DTSTART/DTEND), recurrence and exceptions are editable from either side. Action/Habit state, completion, priority, contexts, hierarchy, dependencies and `:` windows are not calendar-authoritative.

For conflict, kind-change, generation and history outcomes, see [Process](./process.md#plans).
