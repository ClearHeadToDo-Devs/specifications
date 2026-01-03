# Formatting Test Examples

This directory contains canonical formatting test cases for `.actions` files. These examples demonstrate the transformations that conformant formatters should produce.

## Purpose

These test cases serve as:
1. **Specification artifacts** - Executable demonstrations of formatting rules defined in [formatting_specification.md](../../formatting_specification.md)
2. **Implementation tests** - Used by formatter implementations (e.g., topiary.scm in tree-sitter-actions) to verify correctness
3. **Documentation** - Show developers what "before" and "after" formatting looks like

## Structure

Each test case is a directory containing two files:
- `input.actions` - Intentionally malformed but valid .actions file
- `expected.actions` - The correctly formatted output

```
formatting/
  compact/                    # Compact style tests
    01_ugly_spacing/
      input.actions           # [x]Task$Desc!1 (no spaces)
      expected.actions        # [x] Task $ Desc !1 (proper spacing)
    02_extra_spaces/
      ...
  list/                       # List style tests
    01_basic_split/
      input.actions           # [x] Task $ Desc !1 (compact)
      expected.actions        # Each metadata on own line, indented
    ...
  edge_cases/                 # Special cases
    01_empty_file/
    02_minimal_action/
    03_links/
```

## Test Categories

### Compact Style
Tests the default compact formatting style (all metadata on same line):
- **01_ugly_spacing** - No spaces between elements
- **02_extra_spaces** - Too many spaces
- **03_missing_description_space** - `$` icon missing space after it
- **04_child_marker_spacing** - Spaces before `>` markers
- **05_metadata_icons** - Spaces after metadata icons (only `$` should have one)
- **06_all_metadata** - Every metadata type combined
- **07_deep_nesting** - 3+ levels of hierarchy

### List Style
Tests the list formatting style (metadata on separate lines):
- **01_basic_split** - Basic compact → list transformation
- **02_indentation_depths** - Correct (depth+1)×4 indentation
- **03_child_metadata_indent** - Child actions and their metadata at different indents
- **04_all_metadata** - Every metadata type on own line

### Edge Cases
Tests special situations:
- **01_empty_file** - Empty file remains empty
- **02_minimal_action** - Already-formatted minimal action unchanged
- **03_links** - Link syntax `[[text|url]]` preserved atomically

## Usage

### For Formatter Implementors

Use these test cases to verify your formatter implementation:

```bash
# Example: Testing topiary.scm
for test in compact/*/; do
  topiary format "$test/input.actions" | diff "$test/expected.actions" -
done
```

### For the tree-sitter-actions Grammar

The tree-sitter-actions repository uses these via `npm run test:formatting`:

```bash
cd tree-sitter-actions
npm run test:formatting
```

This runs `test/formatting_test.js` which reads these examples from the specifications repo.

## Adding New Test Cases

When adding formatting test cases:

1. **Create a descriptive directory name** (e.g., `08_recurrence_spacing`)
2. **Add both files**:
   - `input.actions` - Intentionally malformed input that demonstrates the issue
   - `expected.actions` - The correctly formatted output per the spec
3. **Test one thing** - Each case should test a specific formatting rule
4. **Use realistic examples** - Prefer real-world scenarios over contrived cases

## Formatting Rules Reference

For the complete formatting specification, see:
- [formatting_specification.md](../../formatting_specification.md) - Canonical formatting rules
- [action_specification.md](../../action_specification.md) - File format syntax

## Version History

- **2026-01-03** - Initial test suite with compact, list, and edge case tests
