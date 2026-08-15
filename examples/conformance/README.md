# Conformance Corpus

Hand-authored fixtures that pin the semantics and byte-level integrity boundaries
of the `.actions` DSL. This is **oracle data, not a test runner**: the
`specifications` repository executes nothing. Peer implementations pull these
sources into their own tests and prove conformance at the boundary they own.

## Taxonomy

| Directory | Assertion | Owning consumer |
| --- | --- | --- |
| `parse/` | valid input has the declared domain meaning | Core or another semantic implementation |
| `diagnostics/` | lint emits the declared code at the declared source node | Core or another linter |
| `archive/` | terminal structure is internally consistent and archive-ready | Core |
| `syntax/` | exact recovery/escaping bytes produce the reviewed CST | grammar |

The grammar retains expected S-expressions because concrete node shape is its
implementation detail. It reads the `.actions` sources here through
`CLEARHEAD_SPEC_DIR`; it does not copy or publish a second corpus. Core similarly
consumes the semantic families behind its opt-in `spec-conformance` feature.

## Expected results

| Fixture | Expectation |
| --- | --- |
| `parse/every_field.actions` | one action; every represented metadata field has the value written in the source; no diagnostics |
| `parse/uuid_v7_derivation.actions` | the UUIDv7 identity is preserved; no retired `W004` diagnostic is emitted; workspace provenance may derive a creation instant when hydrating persisted metadata |
| `archive/completed_tree.actions` | completed parent and child; no tree-consistency diagnostic; ready for archive |
| `diagnostics/inconsistent_tree.actions` | closed parent with an open child → exactly one **`W002`** at the parent node |
| `diagnostics/completed_subtasks.actions` | open parent with all children closed → exactly one **`W003`** at the parent node |
| `syntax/description_brackets.actions` | escaped prose brackets remain prose while a complete link remains a link |
| `syntax/description_unescaped_bracket.actions` | an unescaped opening bracket is a parser-integrity error; the following action remains separate |
| `syntax/incomplete_description_link.actions` | an incomplete link is recoverable without consuming the following action |
| `syntax/description_terminal_backslash.actions` | an escaped terminal backslash preserves the description delimiter |
| `syntax/terminal_bare_backslash.actions` | a terminal bare backslash remains lenient name prose |

Diagnostic expectations pin **code and complete node span**, not presentation
message text. This bounded corpus covers the `W002`/`W003` label drift that
motivated the gate; `examples/linting/` documents the wider optional rule set
without claiming every implementation supports every rule. Structural tests
assert typed domain values rather than a second serialized model. Formatting
conformance has two complementary oracles:

- exact input/expected bytes under `../formatting/`, consumed by the grammar's
  Topiary test;
- semantic round-trip and idempotence over this corpus, consumed by Core.

## Adding a fixture

Keep one scenario per source. Put byte/recovery cases in `syntax/`, semantic
mapping cases in `parse/`, and named lint behavior in `diagnostics/`. Add only the
smallest source needed to distinguish the contract; broad positive-space
coverage belongs in implementation-owned generators rather than a duplicated
fixture framework.
