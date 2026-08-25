---
title: iCalendar Plan projection specification
description: VEVENT/VTODO Plan codecs, Action realization, recurrence, and vdir synchronization semantics
author: primary_desktop
categories: Reference
created: 2026-04-20T00:00:00-0800
updated: 2026-08-24T00:00:00-0800
version: 1.2.0
---

# iCalendar Plan projection specification

This specification defines ClearHead's RFC 5545 Plan projection in the configured plans vdir. The vdir is the complete integration boundary: CalDAV, vdirsyncer, Syncthing, Git, a mounted filesystem, or no transport may sit behind it. ClearHead does not depend on server accounts, hrefs, ETags, or vendor metadata.

The core separation is:

- calendar resources represent **Plans**, meaning the scheduling relationship for executable work;
- `.actions` files represent **Actions**, including lifecycle state and ClearHead workflow structure;
- an Action with no scheduled time has no Plan resource and is intentionally unplanned;
- a Plan may be one-off or recurring; `RRULE` changes cardinality, not domain type.

See [action_file_format.md](./action_file_format.md) for Action syntax.

## File location and discovery

Each resource is one `.ics` file under a charter-scoped vdir directory:

```text
plans/<charter-scope>/<resource>.ics
```

ClearHead emits canonical files named `<uid>.ics`, but readers identify a resource by its RFC 5545 `UID`, not by its filename. Transport tooling may choose another filename. Duplicate Plan identities are errors; traversal order must never pick a winner.

Collection ownership is constructed from each charter's canonical workspace anchor whether or not the directory or any resource exists. The configured `plan_path` changes the physical vdir root, not those relative ownership keys. Calendar loading attaches resources by exact collection path; aliases, titles, and arbitrary `next.actions` basenames are not collection identity.

## Configured Plan codec

`plan_component` selects the component used to encode Plans:

| Value | Component | Intended integration |
|---|---|---|
| `vevent` | `VEVENT` | ordinary calendar scheduling; **default** |
| `vtodo` | `VTODO` | task-oriented calendar/mobile clients |

VEVENT and VTODO are alternative encodings of the same Plan semantics. A workspace writes new resources using its configured codec. Implementations may read the alternate component during explicit migration or compatibility handling, but a mixed duplicate UID must be diagnosed rather than silently selected.

The component choice does not move Action state into the calendar. In particular, VTODO `STATUS` and `COMPLETED` are not authoritative for Action lifecycle when that component is serving as a Plan.

## Plan components

A Plan component has:

- `UID` (required): stable interoperable Plan identity;
- `SUMMARY` (required): display label, sourced from the realized Action for ClearHead-authored one-off Plans;
- `DTSTART` (required): one-off scheduled time or recurrence anchor;
- `RRULE` (optional): recurring Plan semantics;
- `RDATE`/`EXDATE` (optional): recurrence additions and exclusions;
- `RECURRENCE-ID` components (optional): sparse occurrence rescheduling or cancellation;
- `DESCRIPTION` (optional): Plan directives followed by human-readable notes;
- `DTEND` or `DURATION` for VEVENT, or `DUE`/`DURATION` for VTODO (optional): the end/duration side of the normalized schedule interval.

ClearHead MUST preserve the original time value type and frame when possible: UTC, floating local time, all-day DATE, and IANA `TZID` values are valid. Unknown/custom time zones must not be silently interpreted as the machine's local zone.

### Description directives

Leading `key: value` lines are directives until a blank or non-directive line. The remaining text is the Plan description.

| Directive | Type | Description |
|---|---|---|
| `template` | string | Template used when realizing a recurring occurrence |

Clients that do not understand these directives may display them as notes.

## Plan and Action realization

### One-off Plans

A scheduled, non-recurring Action realizes exactly one Plan. For ClearHead-authored resources the Action UUID is used as the component UID and canonical filename. For a calendar-authored arbitrary text UID, ClearHead retains the UID and deterministically derives the Action UUID; it never rewrites the external UID merely to fit the domain model.

The lifecycle is bidirectional:

- assigning `scheduled_at` to an unplanned Action creates its Plan resource;
- changing the Action schedule patches the Plan;
- changing the Plan schedule updates the Action;
- clearing the Action schedule removes the Plan without deleting or cancelling the Action;
- deleting the Plan resource from the calendar unschedules the Action without deleting or cancelling it;
- creating a Plan resource in an owned collection creates a not-started scheduled Action in that charter.

Resource absence is interpreted through the projection merge base. An Action that has never had a Plan is merely unplanned; an established Plan that disappears is a calendar-side unschedule. Implementations must not guess between these states from a single untracked snapshot.

### Recurring Plans

A Plan carrying `RRULE` prescribes recurring Action occurrences. The Plan master has one UID. Each executable occurrence has a deterministic Action UUIDv5 derived from the Plan UID and a canonical recurrence key.

The canonical occurrence address is:

```text
(Plan UID, canonical RECURRENCE-ID)
```

Calendar-side occurrence rescheduling updates the corresponding materialized Action when one exists. Action-side rescheduling writes or updates the matching `RECURRENCE-ID` component. Moving an occurrence never changes its identity: the recurrence key names the original slot while `DTSTART` carries the moved time.

An `EXDATE` or explicitly cancelled occurrence skips the slot. Completing an Action remains Action-owned state; the VEVENT codec does not acquire task-state semantics merely to record completion. Durable completed history belongs to the Action archive. Codec-specific client compatibility may preserve foreign properties, but those properties do not override the Action's lifecycle state.

## Field authority

The relationship deliberately has split authority:

| Meaning | Authority | Calendar representation |
|---|---|---|
| scheduled start | Plan/calendar, bidirectionally reconciled | `DTSTART` |
| end/duration or due schedule | Plan/calendar, bidirectionally reconciled | `DTEND`, `DUE`, or `DURATION` according to codec |
| recurrence and exceptions | Plan/calendar | `RRULE`, `RDATE`, `EXDATE`, `RECURRENCE-ID` |
| Action name and description | Action after adoption | projected to `SUMMARY`/`DESCRIPTION` for display |
| lifecycle state and completion | Action | not Plan-authoritative |
| hierarchy, dependencies, contexts, workflow metadata | Action/ClearHead | not required of the Plan codec |

A calendar-created Plan uses its `SUMMARY` and optional description to seed the new Action. After adoption, ClearHead's Action remains authoritative for those display fields so calendar editing cannot silently rewrite workflow content while rescheduling.

## Reconciliation

Each synchronized schedule field has an independent three-way merge base in the machine-local plans projection store. A conflict in one field must not block safe changes in another. First sync converges agreeing values and surfaces differing values as conflicts rather than guessing by timestamps.

The store also retains the interoperable UID and recurring occurrence linkage needed to reconnect a materialized Action to its Plan. It is projection bookkeeping, not Action state or canonical history.

When updating an existing component, ClearHead changes only fields it owns. It must preserve alarms, unrecognized properties, vendor extensions, calendar-level metadata, the original UID, and the transport-selected resource path.

## Error handling

Invalid resources are non-fatal to unrelated files. Implementations should continue processing other resources and emit actionable diagnostics including file and component context. Missing UID, SUMMARY, or DTSTART components cannot be adopted as Plans. Duplicate derived identities and mixed same-UID component representations are errors.

A calendar collection with no constructed charter owner is quarantined as an `unowned-plans-collection` violation; it never creates an implicit charter. `clearhead doctor --fix` may explicitly remove that local collection after warning that transport tooling can propagate the deletion.

## Contract boundaries

- Domain meaning remains source-agnostic.
- RFC 5545 and vdir behavior belong to the projection layer.
- Transport and server implementation details remain outside ClearHead.
- `.actions` remains the canonical stateful work interface.
- Calendar resources exist only for planned work; absence of a schedule is a valid Action state, not malformed data.
