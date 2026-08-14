---
title: iCalendar VTODO projection specification
description: VTODO plan, Action, expansion, and vdir synchronization semantics
author: primary_desktop
categories: Reference
created: 2026-04-20T00:00:00-0800
updated: 2026-07-23T00:00:00-0800
version: 1.1.0
---

This specification defines ClearHead's RFC 5545 projection in the configured plans vdir. The vdir is the complete integration boundary: CalDAV, vdirsyncer, Syncthing, Git, mounted storage, or no transport may sit behind it. ClearHead does not depend on server accounts, hrefs, ETags, or vendor metadata.

The core separation is:

- recurring VTODOs own Plan recurrence semantics;
- standalone VTODOs project executable Actions;
- `.actions` files remain the human-readable Action projection.

See [action_file_format.md](./action_file_format.md) for Action syntax.

# File location and discovery

Each resource is one `.ics` file under a charter-scoped vdir directory:

```text
plans/<charter-scope>/<resource>.ics
```

ClearHead emits canonical files named `<uid>.ics`, but readers must identify a resource by its RFC 5545 `UID`, not by its filename. Transport tooling may choose a different filename. Duplicate standalone identities are an error; traversal order must never pick a winner.

Collection ownership is constructed from each charter's canonical workspace anchor whether or not the directory or any resource exists. The configured `plan_path` changes the physical vdir root, not those relative ownership keys. Calendar loading attaches resources by exact collection path; aliases, titles, and arbitrary `next.actions` basenames are not collection identity.

# Component classification

Component kind and recurrence determine meaning:

| Component | RRULE | ClearHead meaning |
|---|---:|---|
| `VTODO` | yes | recurring Plan master |
| `VTODO` | no | standalone Action projection |

ClearHead's calendar surface is VTODO-only. Other iCalendar component types are ignored. There is no legacy Plan compatibility, migration, or alternate import path; pre-release fixtures and workspaces were updated directly to VTODO.

# Recurring Plan VTODO

A Plan master is a VTODO carrying `RRULE`.

Expected fields:

- `UID` (required): stable Plan identity
- `SUMMARY` (required): Plan name
- `DTSTART` (required for expansion): recurrence anchor
- `RRULE` (required): recurrence semantics
- `DESCRIPTION` (optional): directives followed by human-readable notes
- `EXDATE`/`RDATE` (optional): RFC 5545 recurrence exceptions/additions

Recurrence remains exclusively Plan semantics. `.actions` files contain materialized instances, never recurrence definitions.

## External identity bridge

Generated instances carry neutral linkage:

- `externalScheduleId <- VTODO.UID`
- `externalOccurrenceKey <- RECURRENCE-ID`, otherwise the canonical RFC 3339 occurrence datetime

The generated Action UUID is UUIDv5 over the Plan UID and occurrence key. This linkage expresses a real Plan-to-instance relationship; it is not needed for standalone Action mirrors.

## DESCRIPTION directives

Leading `key: value` lines are directives until a blank or non-directive line. The remaining text is the Plan description.

| Directive | Type | Description |
|---|---|---|
| `template` | string | Template expanded for each occurrence |
| `upcoming` | integer | Per-Plan override for primary instance count |

Example:

```text
template: weekly-review
upcoming: 2

Notes about this recurring review.
```

Clients that do not understand these directives may display them as notes.

# Expansion semantics

`expand actions` must:

1. read recurring VTODO Plan masters in charter scope;
2. count existing open instances across primary and upcoming Action files;
3. resolve DESCRIPTION directives and workspace expansion bounds;
4. generate occurrences in ascending order, respecting RRULE limits;
5. instantiate the referenced template when present;
6. place the first configured count in the primary file and the remainder in the upcoming file;
7. upsert by deterministic occurrence UUID.

Expansion is idempotent. Completed and cancelled instances vacate an open slot; not-started and in-progress instances occupy one.

# Standalone Action VTODO

A non-recurring VTODO projects one Action. ClearHead synchronizes these fields independently through three-way merge bases in the machine-local plans projection store:

| Action | VTODO |
|---|---|
| identity | `UID` |
| name | `SUMMARY` |
| description | `DESCRIPTION` |
| scheduled time | `DTSTART` |
| due time | `DUE` |
| state | `STATUS` |
| completion time | `COMPLETED` |
| priority | `PRIORITY` |
| contexts | `CATEGORIES` |

Priority uses RFC 5545 values directly: `1` is highest and `9` is lowest; `0` means undefined and maps to no ClearHead priority. Context names map to standard CATEGORIES values. ClearHead context names use commas as separators, so a literal comma inside one category is not representable.

RFC 5545 has no blocked status. ClearHead emits:

```text
STATUS:NEEDS-ACTION
X-CLEARHEAD-STATUS:blocked
```

A later standard status edit wins over a stale blocked extension.

Predecessors, sequential behavior, parent-action hierarchy, and charter semantics are ClearHead-only because RFC 5545 has no equivalent contract.

## Identity adoption

RFC 5545 UIDs are arbitrary globally unique text, not necessarily UUIDs.

- a UUID UID is used directly as the Action UUID;
- any other UID deterministically derives an Action UUIDv5;
- the original UID is never rewritten merely to fit the Action model;
- no charter sidecar identity map is used.

ClearHead-authored standalone resources use the Action UUID as UID and as the canonical filename. For an adopted arbitrary UID, the plans projection store remembers the UID so a missing resource can be recreated without changing its interoperable identity.

## Calendar-created Actions

A standalone VTODO whose derived identity does not match an existing Action is imported as a new root Action into the charter that owns its containing vdir directory. A directory with no constructed charter owner is quarantined as an `unowned-plans-collection` violation; it never creates an implicit charter. `clearhead doctor --fix` may explicitly remove that local collection after warning that vdirsyncer can propagate the deletion.

## Missing resources

Resource absence has no lifecycle meaning. If an Action previously projected to the vdir has no current VTODO, ClearHead recreates the VTODO from the Action. Only `STATUS:CANCELLED` cancels an Action; deleting a file does not.

# Merge and write behavior

Each synchronized field has an independent merge base. A conflict in one field must not block safe changes in another. First sync converges agreeing values and surfaces differing values as conflicts rather than guessing by timestamps.

When updating an existing VTODO, ClearHead changes only fields it owns. It must preserve alarms, unrecognized properties, vendor extensions, calendar-level metadata, the original UID, and the transport-selected resource path.

Date handling accepts UTC, floating local time, all-day DATE values, and IANA TZID values. Unknown/custom time zones must not be silently interpreted as the machine's local zone.

# Error handling

Invalid resources are non-fatal to unrelated files. Implementations should continue processing other resources and emit actionable diagnostics including file and component context. Missing UID/SUMMARY components cannot be adopted as Actions. Duplicate derived Action identities are errors.

# Contract boundaries

- Domain meaning remains source-agnostic.
- RFC 5545 and vdir behavior belong to the projection layer.
- Transport and server implementation details remain outside ClearHead.
