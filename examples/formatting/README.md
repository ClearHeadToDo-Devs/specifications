# Formatting Examples

Canonical input/expected byte pairs for the rules in
[`formatting.md`](../../formatting.md). The specification owns these inert
artifacts; formatter implementations discover and execute them in their own
repositories.

## Covered rules

- `newlines/` — every action begins on its own line;
- `indentation/` — child depth is represented by two-space indentation while
  explicit `>` depth markers remain present;
- `spacing/` — exactly one space separates state, name, and metadata fields;
  spaces inside prose and around links normalize without separating a field
  sigil from its value.

Each leaf directory contains `input.actions` and `expected.actions`. Cases are
small and orthogonal so a byte mismatch names one formatting contract.

```text
formatting/
├── indentation/01_nested_actions/
├── newlines/01_multiple_on_one_line/
├── spacing/01_field_boundaries/
└── spacing/02_description_links/
```

The grammar's Topiary test reads every category through `CLEARHEAD_SPEC_DIR`;
there is no symlink or copied formatter corpus in the implementation repository.
Core separately proves semantic round-trip and idempotence over the semantic
conformance fixtures.

## Adding a case

1. Choose the rule category and a descriptive numbered directory.
2. Add both exact source files, including their final newline.
3. Isolate one discriminating transformation.
4. Run the consuming formatter and review the expected bytes; do not generate an
   expectation and accept it without comparison to `formatting.md`.
