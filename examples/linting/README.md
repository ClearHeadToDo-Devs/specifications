# Linting Examples

Canonical `.actions` fixtures for the rules defined in
[`linting.md`](../../linting.md). The specification repository owns these source
examples but executes no linter. Implementations consume the fixtures and assert
behavior at their own test boundary.

Each active rule directory contains:

- `error.actions` — parseable source that plants the named condition;
- `fixed.actions` — the smallest corrected form.

The directory code and name must agree with the canonical rule heading in
`linting.md`. Current fixture coverage is:

| Severity | Active fixture codes |
| --- | --- |
| Error | `E001`, `E003`, `E004`, `E005`, `E006` |
| Warning | `W001`, `W002`, `W003`, `W005`, `W006`, `W010`, `W011`, `W012` |
| Information | `I001`, `I002`, `I003`, `I004`, `I006`, `I007`, `I008`, `I009`, `I010`, `I011`, `I012`, `I013`, `I014`, `I015` |

Not every specified rule needs a hand-authored pair. Implementations should use
the cheapest discriminating oracle: exact fixtures for named byte/location
contracts and generated planted conditions for combinatorial semantics.

## Tree-consistency codes

The canonical meanings are:

- **`W002`** — a closed parent has an open child;
- **`W003`** — an open parent has only closed children.

The retired `E012`/`E013` labels from the old monolithic conformance example are
not valid codes. Diagnostic conformance pins code and source-node span, not the
human-readable message.

## Retired fixtures

- `legacy_E002_recurrence_without_do_date/` documents the removed `R:` syntax;
  recurrence now lives in iCalendar Plans.
- `legacy_W004_missing_creation_date/` documents the former requirement to
  repeat creation provenance in plaintext; sidecar/UUIDv7 provenance makes a
  missing `^` field non-diagnostic.

Retired fixtures are historical context and must not be included in active
conformance sweeps.

## Adding a fixture

1. Confirm the rule and code in `linting.md`.
2. Add one directory named `<code>_<short_name>`.
3. Keep both files valid syntax and isolate one rule.
4. Prefer realistic, minimal source and avoid embedding implementation messages.
5. Have the consuming implementation assert the expected code and relevant node
   location; the specification itself remains inert.
