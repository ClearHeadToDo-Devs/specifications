---
title: ics schedule specification
description: Plan/schedule semantics in .ics files for planned act generation
author: primary_desktop
categories: Reference
created: 2026-04-20T00:00:00-0800
updated: 2026-04-20T00:00:00-0800
version: 1.0.0
---

This specification defines how `.ics` files represent schedules/plans and how they map into generated planned acts.

The core principle is separation of concerns:

- `.ics` owns schedule timing semantics.
- `.actions` owns planned-act execution records.

See [action_file_format.md](./action_file_format.md) for planned-act syntax.

# Scope

This document covers:

- `.ics` discovery and charter scope expectations
- VEVENT field mapping into schedule records
- Template linkage via DESCRIPTION convention
- Expansion horizon behavior
- Idempotent generation requirements
- External linkage keys carried onto generated acts

This document does not redefine RFC 5545.

# File Location and Discovery

Plan/schedule files are `.ics` files discovered using naming conventions in [naming_conventions.md](./naming_conventions.md).

Common forms:

- `<charter>.ics`
- `<charter>/next.ics`

Each `.ics` file is scoped to the inferred charter for that path.

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

To avoid making core ontology calendar-specific while preserving deterministic behavior, generated planned acts should carry neutral linkage fields:

- `externalScheduleId` (series-level identifier)
- `externalOccurrenceKey` (instance-level identifier)

ICS mapping:

- `externalScheduleId <- VEVENT.UID`
- `externalOccurrenceKey <- RECURRENCE-ID` when present, otherwise canonicalized occurrence datetime

`externalOccurrenceKey` should be canonicalized as RFC3339.

# Expansion Semantics

`expand acts` (or equivalent workflow) should:

1. Read schedule VEVENTs for charter scope.
2. Compute due/upcoming instances within configured horizon.
3. Resolve template, if DESCRIPTION contains a `template: <name>` binding.
4. Generate or upsert planned acts into target `.actions` file.

Default horizon is implementation-configurable; `14 days` is a recommended default.

# Idempotency and Deterministic IDs

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
