# Formatting Test Examples

This directory contains canonical formatting test cases for `.actions` files. These examples demonstrate the transformations that conformant formatters should produce.

## Purpose

These test cases serve as:
1. **Specification artifacts** - Executable demonstrations of formatting rules defined in [formatting.md](../../formatting.md)
2. **Implementation tests** - Used by formatter implementations (Topiary query in tree-sitter-actions) to verify correctness
3. **Documentation** - Show developers what "before" and "after" formatting looks like

## Formatter Scope

The formatter enforces **vertical spacing only**:
- Each action must be on its own line

The formatter does **not** enforce:
- Horizontal spacing (whitespace-insensitive by design)
- Indentation (depth markers define hierarchy, not whitespace)

## Structure

Each test case is a directory containing two files:
- `input.actions` - Input file (may have multiple actions on one line)
- `expected.actions` - The correctly formatted output

```
formatting/
  newlines/                    # Vertical spacing tests
    01_multiple_on_one_line/
      input.actions            # [ ] Task 1[ ] Task 2
      expected.actions         # Each on separate line
    02_preserve_spacing/
      input.actions            # [x]Task$Desc!1 (no spaces)
      expected.actions         # Same (spacing preserved)
    ...
```

## Test Cases

### Newlines
Tests the only formatting rule: each action on its own line.

- **01_multiple_on_one_line** - Multiple root actions on one line get split
- **02_preserve_spacing** - Horizontal spacing is preserved unchanged
- **03_children_on_one_line** - Parent and children on one line get split
- **04_already_formatted** - Already-formatted files are unchanged (idempotence)

## Usage

### For Formatter Implementors

Use these test cases to verify your formatter implementation:

```bash
# Example: Testing with Topiary
for test in newlines/*/; do
  topiary format "$test/input.actions" | diff "$test/expected.actions" -
done
```

### For tree-sitter-actions

The tree-sitter-actions repository references these via symlink or copies them:

```bash
cd tree-sitter-actions
npm run test:formatting
```

## Adding New Test Cases

When adding formatting test cases:

1. **Create a descriptive directory name** (e.g., `05_nested_children`)
2. **Add both files**:
   - `input.actions` - Input that demonstrates the case
   - `expected.actions` - The correctly formatted output
3. **Test one thing** - Each case should test a specific aspect
4. **Remember the scope** - Formatter only adds newlines, doesn't change spacing

## Version History

- **2026-01-18** - Simplified to newlines-only tests (v2.1.0 spec)
- **2026-01-03** - Initial test suite with compact, list, and edge case tests
