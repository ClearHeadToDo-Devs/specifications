# Changelog - Actions Specifications

## 2026-10-08

### Added

**A missing additional workspace is skipped, never created** (`configuration.md`, Error Handling). An `additional_workspaces` entry that does not exist is skipped by every verb with a warning naming it, and `doctor` reports it. Until now the general "missing directories: create automatically" rule would have recreated a stale path, and implementations differed by verb: reads skipped it silently while `delete action` failed.

## v0.2.1 — 2026-10-06

A patch release: the specification is MIT-licensed. Its contract is unchanged from v0.2.0; schema `$id`s are `https://clearhead.dev/schemas/v0.2.1/<name>.schema.json`.

## 2026-10-06

### Changed

**The whole specification is MIT-licensed** (`LICENSE`, `README.md`). Until now only the folded-in ontology carried a license; its MIT license moves to the root and covers everything, prose, schemas, shapes and examples alike, so anyone may implement or build on it, commercially or not. The ontology imports keep their own licenses, credited in the README: CCO, BSD 3-Clause; IAO, CC BY 4.0.

## v0.2.0 — 2026-10-04

The second release: the specifications as of this entry, including every dated entry below down to v0.1.0. It is the first published at `clearhead.dev` (platform Decision 49): schema `$id`s are `https://clearhead.dev/schemas/v0.2.0/<name>.schema.json`, and the application vocabulary is `https://clearhead.dev/vocab/app/v1#`.

## 2026-10-04

### Changed

**Identifiers move to `clearhead.dev`** (platform Decision 49). `app:` is `https://clearhead.dev/vocab/app/v1#`; the shapes, the ontology's own IRIs and the example data follow. The context namespace UUID is unchanged: it is a constant, and moving it would rename every context node. The CCO graph's vocabulary rule rejects terms from either domain, with a new invalid example for an `app:` term.

**The ontology lives here** (`ontology/`; platform Decision 50). The former `ontology` repository's V5 content (the header, imports, examples, competency queries and verify rules), its `domain.md`, `DECISIONS.md` and license are folded in with their history, beside the mapping. `make -C ontology test` is its ROBOT gate, run by the platform's pinned gate; the specification stays inert data.

**`app:plannedFrom`, the planned start's instant** (`ontology.md`, `schemas/app.shapes.ttl`, `ontology/unmapped.ttl`, the graph fixture; platform Decision 53). A derived `xsd:dateTime` in the viewer's zone, so queries compare `@` as they compare the window, never the written start. Every action with `app:plannedStart` has it. Its meaning is `app:plannedStart`'s, so the mapping lists it as unmapped.

**Index rows locate an action from the data root** (`schemas/index_query_result.schema.json`; platform Decision 53). `charter_root` becomes `data_root`, the workspace's absolute data root, and `source_file` is the application graph's `app:file`, relative to it (`charters/next.actions`), so a row and the graph use one path convention. Consumers join `data_root` and `source_file` as before. `scheduled_at` and `due_date` are as written (`app:plannedStart`, `app:due`): a date stays a date. The views filter and sort on the instants `app:plannedFrom` and `app:lateFrom`, the effective deadline.

**A time is kept as written and resolves as RFC 5545 resolves a local time** (`action_file_format.md`; platform Decision 52). A time without an offset is local to the viewer and written back without one; a written offset is kept. A local time that occurs twice is its first occurrence, and one that does not occur is read with the offset before the gap.

## 2026-10-03

### Added

**The mapping from the application vocabulary to CCO** (`ontology/mapping/*.rq`, `ontology/unmapped.ttl`; platform Decisions 45, 49 and 50). One SPARQL CONSTRUCT per structure; mapping the fixture's `expected-app.ttl` yields `expected.ttl`, and every application term is read by a query or listed in `unmapped.ttl` with why. The mapping reads effective terms (`app:waitsOn`, `app:notBefore`, `app:lateFrom`), so an inherited wait or window bound is a condition of the child, and each fact is one condition.

### Changed

**`@` takes a range; duration is derived** (`action_file_format.md`, `linting.md`, `ics_schedule_spec.md`, `ontology.md`, `schemas/actions.schema.json`, `schemas/app.shapes.ttl`, the mapping; platform Decision 51). `@` is a planned start or an ISO 8601 `start/end` block, half-open, read as a calendar reads one. A date covers its day and a time is an instant, in `@` and `:` alike: written precision no longer matters for times, so `:…T17:00` is late from 17:00, not 17:01. Duration is the block's length, never written: `D` is read for migration and formatted as a block, `durationMinutes` leaves the JSON schema, a transaction's `scheduled_at` takes `@`'s value and its `duration` is gone, and `app:durationMinutes` is derived. The application graph renames `app:start` to `app:plannedStart` and adds `app:plannedEnd`. E001 is retired, E008 also catches an empty block, and W015 compares the block with the window. Calendar sync carries the block and nothing else: a VEVENT's `DTSTART`/`DTEND`, a VTODO's `DTSTART`/`DURATION`. The window is not synchronized, and a VTODO's `DUE` is no longer written or read.

**The CCO graph** (`ontology.md`, `schemas/graph.shapes.ttl`, the graph fixture). Helper nodes are blank nodes; entities keep their IRIs (Decision 49). A window bound's condition carries the text `not before` or `late from` with its effective instant, so the two are told apart by structure rather than by IRI. `@` is intent: a Prescriptive ICE that is part of the action, its planned time on a bearer, not a condition and not an act. A metric's description is carried as `dcterms:description`.

### Removed

**A metric's `review_date`** (`objectives.md`, `schemas/app.shapes.ttl`, `ontology.md`). Reviewing a metric is work: an action, recurring or with a due date, in a charter that serves the objective.

## 2026-10-02

### Changed

**`:` is the window; `@` is intent** (`action_file_format.md`, `process.md`, `ontology.md`, `linting.md`, `schemas/actions.schema.json`, `schemas/app.shapes.ttl`; platform Decision 48). `:` takes a deadline or an ISO 8601 interval `start/end`, a lower bound and a deadline; `@` is when the Action is planned and no longer bounds anything or is inherited. A bound covers its written precision, so `:…T17:00` is late from 17:01, and the window is half-open. The application graph gains `app:availableFrom`, the written lower bound; `app:notBefore` now derives from it instead of `app:start`. New lints: E008 Empty Window, W015 Planned Outside the Window. Files that used `@` to mean "not before" should move that date into `:`.

## v0.1.0 — 2026-09-30

The first release: the specifications as of this entry, including every dated entry below. Releases are described in the README.

### Changed

**Schema identity names a release, not a branch** (`schemas/*.json`, `README.md`). Every schema's `$id` is now `https://raw.githubusercontent.com/ClearHeadToDo-Devs/specifications/v0.1.0/schemas/<name>.schema.json`. Six ids named the `master` branch, so a schema's identity moved with every commit; `actions` and `charters` used `github.com/.../schemas/...` URLs that did not resolve. Documents that declared a `master` URL as their `$schema` should declare the release they follow.

## 2026-09-26

### Changed

**The root `next.actions` is the default capture target** (`workspace.md`, `configuration.md`, `process.md`, `schemas/config.schema.json`). `default_file` now defaults to `next.actions`, resolved relative to the workspace's `charters/` directory; the old text said `data_dir`, which no implementation followed. `charters/inbox.actions` loses its special status and, where it still exists, is an ordinary child charter named `inbox`. This finishes the unified workspace root: the root already owned `next.actions` as its action anchor, but capture still defaulted to the inbox, so choosing between the two files was a decision users had to make on every capture.

## 2026-09-25

### Changed

**Charters without a declared state are always `New`** (`charters.md`, `workspace.md`). A Charter with no document, the root without `charters/README.md` included, is `New` like every newly created Charter; the root no longer loads as `Active` when its README is missing. `New` is the planning state: activation is always an explicit, requested transition, and no operation that creates or edits a Charter's document may change its state as a side effect. `clearhead init` writes the root as `New`. Because engagement requires every ancestor to be `Active`, a workspace is not engaged until its root is activated, so implementations should report a `New` Charter that owns open actions.

## 2026-07-18

### Removed

**Query Output Specification** (`query_output.md`) — relocated out of the shared spec set. Query output has a single producer (`clearhead-graphd`), so its contract is that tool's public interface, not cross-implementation law that this repo exists to hold. The move:
- Semantic principles (identity, query-form-follows-shape, ordering, the stateless-producer seam, aggregates) → `clearhead-graphd/docs/query_contract.md`, alongside the existing field-level export contract.
- CLI presentation (shape×destination; `read`→native, `query`→structured) → `clearhead-cli/docs/UI.md`.

The core reframe carried across: "one payload, every consumer" became "one **semantic** payload" — graphd never forks its bytes; lighter presentations are downstream projections a client derives, not the engine serving different masters.

## 2026-07-05

### Added

**Query Output Specification v1.0.0** (`query_output.md`)
- Defines the single JSON-LD output contract for query/view results: one payload for all consumers (clients and integration partners); simple clients read `@graph` and ignore `@context`. No per-consumer serialization.
- Canonical identity is semantic `@id`, exported to simple clients as compacted `id`; that identity is what mutation verbs target.
- Query form follows data shape — `SELECT` for ordered lists/trees, `CONSTRUCT` for networks — while serialization stays JSON-LD either way.
- Ordering carried both as `@graph` array position and as sort-key node properties.
- Establishes the stateless-producer + verbs-by-identity seam; client widgets (quickfix, DOT) are explicitly client concerns.

## 2026-01-24
### Refactor: move older specifications to archive
Moved a few specifications to `Archive` folder as we move to an RDF-centric approach:
- sql_schema: no need as RDF does more work 
- json_schema: superseded by ontology 
- event logging specification as this is now handled by the sync specification

## 2026-01-18

### Changed

**Formatting Specification v2.1.0** (`formatting.md`)
- **Breaking:** Reduced scope to vertical spacing only (newlines between actions)
- Removed horizontal spacing enforcement - format is whitespace-insensitive by design
- Removed indentation enforcement - depth markers define hierarchy, not whitespace
- Formatter now implemented as Topiary query in `tree-sitter-actions/.topiary/`
- No configuration options - formatter does one thing (newlines)
- Dramatically simplified specification

**Formatting Specification v2.0.0** (`formatting.md`)
- Removed list style - single format only
- Removed metadata ordering from formatter scope

### Rationale

The `.actions` format was designed to be whitespace-insensitive: `[x]Task$Desc` and `[x] Task $ Desc` are semantically equivalent. Fighting against this with a formatter that enforces specific spacing was adding complexity without clear benefit.

Similarly, hierarchy is defined by depth markers (`>`, `>>`, etc.), not by indentation. Enforcing indentation is cosmetic, not semantic.

By reducing the formatter to just "ensure newlines between actions," we:
1. Embrace the format's whitespace-insensitive design
2. Enable simple Topiary implementation (50 lines of queries)
3. Move formatting upstream to tree-sitter-actions where it belongs
4. Eliminate ~200 lines of Rust formatter code from clearhead-cli

### Removed

- `specifications/examples/formatting/list/` - List style test examples removed
- Horizontal spacing rules from formatter scope
- Indentation enforcement from formatter scope
- `indent_width` and `indent_style` configuration options

---

## 2026-01-03

### Changed

**Formatting Specification v1.1.0** (`formatting_specification.md`)
- **Expanded scope:** Formatter now enforces ALL spacing (horizontal + vertical)
- Removed caveats about "recommends but doesn't enforce horizontal spacing"
- Clarified that spec defines target behavior; implementations work toward conformance
- Updated philosophy to emphasize zero-configuration automatic formatting
- Design principle #5 changed from "Pragmatic scope" to "Zero-configuration"

**Linting Specification v1.1.0** (`linting_specification.md`)
- **Breaking change:** Removed spacing rules (S001-S004)
- Spacing is now handled entirely by the formatter
- Linter focuses exclusively on semantic correctness, temporal logic, and style preferences
- Reduced from 32 rules to 28 rules (11 errors, 4 warnings, 13 info)
- Updated philosophy section to clarify formatter vs linter boundary
- Renumbered categories: Semantic (1) → Temporal (2) → Style (3) → Content (4)

### Rationale

The original design had formatters handling vertical spacing and linters handling horizontal spacing due to tree-sitter grammar limitations. This created an awkward separation where:
- Formatter: vertical layout only
- Linter: horizontal spacing + semantics

New design has clean separation based on user intent:
- **Formatter** (automatic, opinionated): ALL presentation (horizontal + vertical spacing)
- **Linter** (configurable, optional): Semantic correctness only

This means formatters must work around grammar limitations (e.g., by serializing from IR with proper spacing rather than trying to edit AST).

### Implementation Status (as of 2026-01-03)

**clearhead-cli** (Rust implementation):
- ✅ Horizontal spacing implemented in `format_as_actions_basic()`
- ✅ Spec-compliant formatter working
- ⚠️ Topiary disabled (was stripping spacing)
- ⚠️ LSP still using old Topiary path

See `clearhead-cli/CHANGELOG.md` for detailed implementation notes.
