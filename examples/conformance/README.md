# Conformance Corpus

Hand-authored fixtures that pin the semantics of the `.actions` DSL. This is
**oracle data, not a test runner** — the `specifications` repo executes nothing.
Implementations (Core, and any other parser/tooling) consume these fixtures and
prove *themselves* against the spec; conformance is a property of the
implementation, never a test the spec runs against it.

## Taxonomy

The directory **is** the assertion — a consumer branches on it, one scenario per
fixture:

| Directory | Assertion |
| --- | --- |
| `parse/` | the input parses into the expected domain structure |
| `diagnostics/` | linting the input emits the expected diagnostic (code + location) |
| `archive/` | archive-readiness is detected correctly |

The old monolithic `examples/actions/conformance_test.actions` mixed valid parses
with error cases in one file, so no single expected-output was expressible over
it. It has been split here, one scenario per file.

## Expected results

Verified against `clearhead lint file` (the reference implementation) on
2026-08-14:

| Fixture | Expectation |
| --- | --- |
| `parse/every_field.actions` | parses; every metadata field populated; no diagnostics |
| `parse/uuid_v7_derivation.actions` | no `^` field → created date derived from the v7 UUID timestamp; **no** `W004` (missing creation date) |
| `archive/completed_tree.actions` | completed parent with completed child; consistent; no diagnostics |
| `diagnostics/inconsistent_tree.actions` | closed parent with an open child → **`W002`** |
| `diagnostics/completed_subtasks.actions` | open parent with all children closed → **`W003`** |

Diagnostic expectations pin the **code and node location**, not the human-readable
message text (which is presentation and will churn).

## Machine oracles

The expected-output *files* (e.g. `*.expected.json` for structural comparison,
`*.expected.errors` for diagnostics) are intentionally **not** authored yet: their
format should be driven by the Core conformance harness that consumes them, so it
is co-designed with its first real reader rather than guessed here. Until then,
this README's tables are the human-readable oracle. Tracked by the platform
`spec-conformance-gate` charter.
