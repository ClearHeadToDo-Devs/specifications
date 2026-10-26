---
title: iCalendar Plan projection specification
description: VEVENT projections of Actions and Habits, recurrence identity, and vdir reconciliation
categories: Reference
---

# iCalendar Plan projection specification

This specification defines RFC 5545 projections in each workspace's `<data_root>/plans/` vdir. The vdir stays at that location (Decision 31) and is the complete integration boundary. CalDAV, vdirsyncer, Syncthing, Git, a mounted filesystem, or no transport may sit behind it. ClearHead does not depend on server accounts, hrefs, ETags or vendor metadata.

Actions are native work in ordinary `.actions` files. Habits are native recurring prescriptions in `<charter>.habits.actions` (Decision 57). A one-off Plan is not another domain entity: it projects an Action's `@` block. A recurring Plan projects a Habit. An unscheduled Action has no Plan. See [Action syntax](./action_file_format.md), [workspace layout](./workspace.md) and [process](./process.md).

## File location and discovery

Each resource is one `VCALENDAR` in `plans/<charter-scope>/<resource>.ics`, containing a VEVENT master and any same-UID `RECURRENCE-ID` overrides. ClearHead emits `<uid>.ics`; readers identify the resource by UID, not filename. Transport-selected filenames are preserved. Duplicate master identities, including mixed component kinds, are errors, never traversal-order winners.

Collection ownership comes from each charter's canonical workspace anchor even if no directory exists. Loading attaches resources by exact collection path, never by alias, title or an arbitrary `next.actions` basename. An unowned collection is quarantined (`unowned-plans-collection`); doctor may explicitly remove it after warning that transport can propagate deletion. It never creates an implicit charter.

## VEVENT-only integration (Decision 55)

Plans use VEVENT only. `plan_component` is retired; a legacy `vtodo` setting warns. For one transition release, sync converts linked VTODO Plans and all same-UID overrides atomically to VEVENT, keeping UID, time frames, alarms, unknown properties and paths wherever representable. Unsupported/lossy conversion leaves the resource unchanged and reports why. Unlinked VTODOs are not adopted; doctor reports them. One-way `clearhead export plans` may still write VTODO and reads nothing back.

A component has UID, SUMMARY and DTSTART; optional DTEND (or imported DURATION), DESCRIPTION, RRULE, RDATE, EXDATE and occurrence overrides. Missing required fields and duplicate identities are actionable errors local to the resource; unrelated files continue.

The calendar shows the `@` block only. It is half-open: a DATE DTEND is the day after the last included date written in `@`; a time end is the written instant. `:` windows, lifecycle state, priority, contexts, hierarchy and dependencies stay local. Children are template steps, not independently recurring components.

Time frames (UTC, floating, all-day DATE and IANA TZID) are preserved. Unknown/custom zones are not interpreted as the machine's local zone. RDATE, EXDATE, time frames and overrides awaiting materialization belong in the Habit's durable semantic sidecar (or its charter's sidecar), not solely in the reconstructible projection store. Regeneration must not discard them.

### Description directives

Leading `key: value` lines are directives until a blank or non-directive line. `template: <name>` binds a named template. Directives are excluded from the human description's three-way merge; calendar editors must not cause a directive to be silently treated as ordinary prose. Inline Habit children win over a named binding, with a warning.

## One-off Plans

A scheduled, non-recurring Action realizes exactly one Plan. ClearHead-authored resources use the native Action UUID as UID. A genuinely new calendar-authored one-off keeps its arbitrary external UID and gets an independent native UUID, with the link in the Action sidecar. Transport identity is never native identity.

Assigning or changing `@` creates or patches the resource; a calendar schedule edit updates `@`. Clearing `@` removes the Plan without closing the Action. Deleting an established Plan unschedules the Action without deleting or cancelling it. Resource absence is interpreted through the merge base, not guessed from an untracked snapshot. A new unrelated VEVENT in an owned collection seeds a not-started scheduled Action using SUMMARY and human DESCRIPTION.

## Habits and occurrence identity

A Habit's native id is its line's `#uuid`; it is not derived from UID. Each Habit projects to one recurring VEVENT. Series time/rule edits reconcile to its line; RDATE/EXDATE/frame edits reconcile to its sidecar. Single-occurrence edits reconcile to the occurrence Action, or wait durably in the sidecar until it exists. Moving an occurrence changes DTSTART, never the original slot in RECURRENCE-ID.

### Canonical slot keys (`slot-key-zone`)

Keys are ASCII strings, independent of the viewer or device zone. Seconds are always present. Equivalent lexical precision normalizes to seconds; nonzero fractional seconds retain their value without trailing zeroes. The prefix distinguishes value types:

| Frame | Original slot | Canonical key |
| --- | --- | --- |
| DATE | `20261026` | `D:2026-10-26` |
| Floating | `20261026T090000` | `F:2026-10-26T09:00:00` |
| UTC/offset | `2026-10-26T09:00:00-07:00` | `U:2026-10-26T16:00:00Z` |
| TZID | `TZID=America/Los_Angeles:20261026T090000` | `U:2026-10-26T16:00:00Z` |

For TZID slots, resolve in the series zone using RFC 5545 §3.3.5 (first occurrence in a fold, pre-gap offset for a nonexistent local time), not the host's zone. Preserve the frame separately for future expansion. In Los Angeles the fold slot `2026-11-01T01:30:00` keys as `U:2026-11-01T08:30:00Z`; the gap slot `2026-03-08T02:30:00` keys as `U:2026-03-08T10:30:00Z`. Devices in UTC, Los Angeles and Tokyo compute all these same keys. DATE and floating keys are never converted to UTC. This corrects the old UTC-only slot wording.

The native occurrence id is `UUIDv5(Habit UUID, "occurrence/" + key)`. A stamped step id is `UUIDv5(occurrence UUID, "step/" + template-step UUID)`, with lowercase hyphenated step UUID text. Template-step UUIDs are persisted before stamping: renaming or reordering a step never changes its id; a deliberately new step gets a new UUID. Derived ids are persisted on the generated lines. `app:slot` is the canonical key as `xsd:string`, not a viewer-resolved `xsd:dateTime`.

Transport occurrence addresses remain `(UID, RECURRENCE-ID)`. The durable native link is `(Habit UUID, canonical slot)`, including for history after a transport UID replacement. These are different addresses of the same occurrence, not interchangeable identity inputs.

## Reconciliation and kind changes

Name, human description, planned start/end, recurrence and exceptions use independent field-wise three-way merge bases. Safe changes in one field continue while another conflicts. First sync converges agreeing values and presents differing values, not timestamp winners. Series edits target the Habit; an occurrence rename targets only its Action. Action/Habit state, completion, priority and contexts are never calendar-authoritative.

The committed semantic sidecar holds native/transport links and recurrence-only facts. The machine-local projection store holds merge bases and reconstructible state. Loss of that store must not lose occurrence identity, frame, exceptions or pending overrides. Updates preserve alarms, unrecognized properties, extensions, calendar metadata, original UID and transport-selected path.

A recurrence kind change is detected against the merge base and proposed, never silently applied (Decisions 56/57). Accept, revert (restore the last synchronized kind), and defer (ask again next sync) are explicit operations. `--accept-all` accepts kind proposals for scripted runs; a noninteractive run otherwise defers. It never substitutes for an explicit native-identity link confirmation.

- Accepted one-off → recurring moves the Action to the habits file, retaining its native UUID as the Habit id; no duplicate old Action remains. The first occurrence has its own derived id. The proposal exposes effects on children, dependencies, state, priority and contexts before acceptance.
- Accepted recurring → one-off ends the Habit. The newest open occurrence keeps its id and becomes the one-off Action; older open occurrences remain open for manual completion/cancellation. The proposal shows the resulting block, including clients that return to the original series start. If there is no open occurrence, the proposal requires explicit resolution rather than inventing an identity.
- A text kind change moves the line between files, adding/removing `R:` and retaining its UUID. It is not adopting that line as a generated occurrence.

UID replacement and `this and following` series splits are separate from same-UID kind proposals. Sync presents a link for user confirmation at arrival; native identity is retained only through an explicitly confirmed link, never automatic matching. Ambiguous links defer and recur next sync. Suspected replacements with no candidate stay held until a user supplies a link by hand; no new entity is adopted for the held event. Doctor reports held relationships read-only; `--fix` invokes the same explicit link operation, never merges native identities. Candidate detection must not be sold as proof of identity.

## Generation and history

See [Habit workflow](./process.md#habits). Every arrived slot is materialized, even while older ones remain open. Generation is bounded per write transaction and resumable without dropping slots. Active and archived occurrence ids both suppress duplicates. Rule edits do not rewrite or delete existing occurrence history. Future slots remain computed projections, not editable Action rows. Calendar-only exclusions skip unmaterialized excluded slots, not erase existing work silently.

The transition is a clean break: existing vdir-owned recurring prescriptions are rewritten once into habits files. Their old event-derived occurrence ids are not carried forward. Migration is explicit, previewable and restart-safe; published specification and grammar releases precede Core adoption (Decision 54).
