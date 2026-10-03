# Changelog - Actions Specifications

## 2026-10-03

### Added

**The mapping from the application vocabulary to CCO** (`ontology/mapping/*.rq`, `ontology/unmapped.ttl`; platform Decisions 45, 49 and 50). One SPARQL CONSTRUCT per structure; mapping the fixture's `expected-app.ttl` yields `expected.ttl`, and every application term is read by a query or listed in `unmapped.ttl` with why. The mapping reads effective terms (`app:waitsOn`, `app:notBefore`, `app:lateFrom`), so an inherited wait or window bound is a condition of the child, and each fact is one condition.

### Changed

**`@` takes a range; duration is derived** (`action_file_format.md`, `linting.md`, `ics_schedule_spec.md`, `ontology.md`, `schemas/actions.schema.json`, `schemas/app.shapes.ttl`, the mapping; platform Decision 51). `@` is a planned start or an ISO 8601 `start/end` block, half-open, read as a calendar reads one. A date covers its day and a time is an instant, in `@` and `:` alike: written precision no longer matters for times, so `:…T17:00` is late from 17:00, not 17:01. Duration is the block's length, never written: `D` is read for migration and formatted as a block, `durationMinutes` leaves the JSON schema, and `app:durationMinutes` is derived. The application graph renames `app:start` to `app:plannedStart` and adds `app:plannedEnd`. E001 is retired, E008 also catches an empty block, and W015 compares the block with the window. Calendar sync carries the block and nothing else: a VEVENT's `DTSTART`/`DTEND`, a VTODO's `DTSTART`/`DURATION`. The window is not synchronized, and a VTODO's `DUE` is no longer written or read.

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
