# Habit transition — Darrion's specification review

Review branch: `review/spec-habits-darrion`, continuing Darrion's edits through `9ef1cf8` on the original draft based on specifications main `a8a09ad`.
Darrion approved source `2d812ec` on 2026-11-03 (findings 1–5 applied). Publication is tracked by platform `=release-habits`; see [release verification](habit-release-verification.md). Decisions 31, 54, 55 and 57 govern it. The vdir stays at the workspace's `plans/`; the calendar A/B/C proposal is closed, not part of this review. The already approved recurrence source/formatting fixtures are unchanged.

## Read these changes, in order

1. `action_file_format.md` — syntax and field meanings only, including `R:` after a complete `@` block; file placement and Habit behavior are linked rather than specified here.
2. `ics_schedule_spec.md` — VEVENT format, native/transport separation, `Canonical slot keys (slot-key-zone)` (DATE, floating, UTC/TZID, fold/gap examples and UUID recipes), field authority and lossless preservation. Workflow outcomes now live in group 3; implementation mechanics wait in platform's `=core-habit` action.
3. `process.md`, Plans/Habits, Kind changes and identity, and On Closure — every arrived slot survives; incremental catch-up cannot truncate backlog; active and archived occurrences suppress duplicates; rule edits preserve history; template precedence and window offsets; kind-change identities and explicit UID-link safeguards. All open Habit states generate; completed and cancelled stop generation without closing occurrences.
4. `workspace.md`, Plans/Actions and Archival — known suffixes, reader classification and unchanged plans location/archive boundary. `ontology.md`, Habit terms/Habits — native ids, state and string slot typing.
5. `linting.md`, E002 and Habit scope/template warnings; `observability.md`, Habit Events; `configuration.md`, retired codec and projection-only expansion cap.
6. Machine contracts: `schemas/{actions,charter_metadata,config}.schema.json`, `schemas/app.shapes.ttl`, `ontology/mapping/{entities,habits}.rq`, `ontology/unmapped.ttl`, and `examples/conformance/habits/`. Formatting README now indexes the approved Habit category.

Please review the actual diff, not just this summary. In particular the slot-string/UUID recipe, stable step UUID requirement, window-offset wording and rule-edit re-evaluation are concrete draft interpretations of the already requested deterministic, lossless behavior; approval precedes publication. There is no Habit pausing: blocked still generates; to stop temporarily, close and recreate. The approved content preserves existing syntax: `[-]` is in progress, `[_]` is cancelled, and `[x]` and `[_]` stop generation. There is no Habit-specific marker remapping. Recurring → one-off with no open occurrence keeps the Habit's UUID (Darrion, 2026-11-03, `=habit-unrecur-no-open`).

## Findings applied before group 3 (2026-11-03)

- Findings 1–2: file roles and text moves → `workspace.md`; entity roles → `ontology.md`; recurrence scope diagnostics stay in `linting.md`; template/window behavior → `process.md`.
- Finding 3: slot strings and UUID recipes stay in the ICS format contract; generation, history, edit targeting and kind-change outcomes → `process.md`. Storage split, merge bases/three-way merge, command/link/doctor flows, per-transaction catch-up, quarantine and migration mechanics are preserved in full in platform's `=core-habit` description, not discarded or made normative here. Decision/proposal references are removed from the ICS specification.
- Finding 4 amended: no pausing, all open states generate, both terminal states stop including catch-up, each with a closed date. Ontology, lint and SHACL/check examples agree.
- Finding 5: Habit states mirror Action states, so `[ ]` maps to `app:NotStarted`, not `app:Active`.

## Validation and release gate

`python examples/conformance/habits/check.py` passes with the pinned Python dependencies in its README; `git diff --check` passes. The existing `expected-app.ttl` and `expected.ttl` graphs also pass their updated SHACL shapes, and mapping the existing app fixture remains isomorphic to its expected CCO graph. These checks validate artifacts and vectors, not Core behavior. Full existing graph/ontology reasoner validation and implementation conformance remain release gates, alongside independent review. No tags, registry publication, Core bumps or platform gitlink changes are part of this draft.

After Darrion approves the content: resolve review findings; run specification graph/reasoner checks and grammar corpus/Topiary checks against these exact approved fixtures; publish specification and grammar together; then bump Core's crates.io grammar dependency, lockfile and `[package.metadata.clearhead] specification`, adopt exactly those releases as platform pins and run `scripts/validate-pinned`. Never pin this draft branch or commit a local grammar patch (Decision 54).

## Reader/discovery inventory for implementation review

Confirmed current paths needing suffix-aware audit:

- Core: `workspace/store/assembly.rs` discovery; `workspace/action_files.rs`, `resource.rs`, `mutate_actions.rs`, `transaction.rs`, `archive_actions.rs`, `archive_facts.rs`, `store/doctor.rs`; domain identity/update paths.
- CLI: `filesystem/{discovery,mounts,mod,archive_charter,archive_facts,doctor}.rs`, `cli/{action,file}.rs` and command arguments/help. Source paths above are relative to each crate's `src/`.
- nvim: `lua/clearhead/init.lua`: charter stem inference, archive routing, active-file picker and `*.actions` autocmds. Grammar handles syntax for all suffixes; semantic scope belongs to readers/lints. VS Code currently contains only a LICENSE and has no reader implementation.
- Publication/query locations, formatting and template readers must distinguish Habit roots/template data from executable Actions; the archive reader must still expose lineage for duplicate checks without polluting live queries.

This is a starting inventory, not a claim of an exhaustive completed sweep. The readers increment must search all callers and add root/flat/directory/archived/template fixtures plus an inventory guard; close it only when tests prove every discovered reader classified the suffix correctly. Nvim adoption/release occurs in the same implementation cycle, not deferred after Core ships.
