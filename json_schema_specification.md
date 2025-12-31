# JSON Serialization Format
This section defines the canonical JSON serialization format for `.actions` files. Implementations that parse `.actions` files and convert them to structured data should follow this specification to ensure interoperability.

## Purpose
While the `.actions` format is designed to be human-readable plaintext, many applications need to:
- Convert parsed actions into structured data (JSON, databases, etc.)
- Validate serialized data programmatically
- Exchange action data between different tools
- Store actions in systems that require structured formats

This specification ensures all implementations serialize to the same JSON structure.

## Schema Location
The canonical JSON Schema is maintained in this repository at `schema/actions.schema.json` and is generated from the same source patterns used by the tree-sitter grammar to ensure consistency.

## Structure

### Root Document
The root JSON document is an object containing a flat array of all actions:

```json
{
  "actions": [
    // flat array of all action objects (hierarchy via parent_id)
  ]
}
```

### Action Object
Each action object has the following structure:

```json
{
  "state": "not_started",
  "name": "Action name",
  "description": "Optional description",
  "priority": 1,
  "story": "Project name",
  "contexts": ["context1", "context2"],
  "doDate": {
    "datetime": "2025-01-19T08:30",
    "duration": 30,
    "recurrence": {
      "frequency": "weekly",
      "interval": 1,
      "byDay": ["Mon", "Wed"]
    }
  },
  "completedDate": "2025-01-19T10:30",
  "id": "214342414342413424",
  "parent_id": null,
  "depth": 0
}
```

**Hierarchical Structure**: Actions are stored in a flat array. Hierarchy is represented via `parent_id` references and `depth` levels. This design:
- Simplifies queries (no recursive traversal needed for filtering)
- Maps directly to SQL storage (relational foreign keys)
- Enables efficient mutations (moving actions = changing parent_id)
- Maintains all information needed to reconstruct the tree for display

## Field Specifications

### Required Fields

#### `state` (string, required)
The current state of the action. Must be one of:
- `"not_started"` - Corresponds to `[ ]` in plaintext
- `"completed"` - Corresponds to `[x]` in plaintext
- `"in_progress"` - Corresponds to `[-]` in plaintext
- `"blocked"` - Corresponds to `[=]` in plaintext
- `"cancelled"` - Corresponds to `[_]` in plaintext

**Type**: String enum
**Pattern**: `^(not_started|completed|in_progress|blocked|cancelled)$`

#### `name` (string, required)
The name/title of the action. This serves as a secondary key (after ID) for human readability.

**Type**: String
**Min Length**: 1
**Pattern**: Must not contain unescaped metadata marker characters (`$!*+@%#>`)

### Optional Fields

#### `description` (string, optional)
Long-form description of the action. Corresponds to `$` metadata in plaintext.

**Type**: String
**Omit if**: Not present in source

#### `priority` (integer, optional)
Numeric priority level. Corresponds to `!` metadata in plaintext.

**Type**: Integer
**Minimum**: 0
**Omit if**: Not present in source

#### `story` (string, optional)
Parent project/story name. Corresponds to `*` metadata in plaintext.
Only valid for root-level actions.

**Type**: String
**Pattern**: Must not contain unescaped metadata marker characters
**Omit if**: Not present in source

#### `contexts` (array, optional)
Array of context tags. Corresponds to `+` metadata in plaintext.
The plaintext comma-separated list is split into array elements.

**Type**: Array of strings
**Pattern (each element)**: Must not contain unescaped metadata marker characters or commas
**Omit if**: Not present in source

#### `doDate` (object, optional)
Scheduled date/time for the action. Corresponds to `@` metadata in plaintext.

**Type**: Object with the following fields:
- `datetime` (string, required): ISO 8601 formatted date/time
- `duration` (integer, optional): Duration in minutes
- `recurrence` (object, optional): Recurrence rule (see Recurrence Object below)

**Omit if**: Not present in source

##### Recurrence Object
When present within `doDate`, defines how the action repeats:

```json
{
  "frequency": "daily",
  "interval": 1,
  "count": 10,
  "until": "2025-12-31",
  "byMinute": [0, 15, 30, 45],
  "byHour": [9, 17],
  "byDay": ["Mon", "Wed", "Fri"],
  "byMonthDay": [1, 15],
  "byMonth": [1, 6, 12]
}
```

**Fields**:
- `frequency` (string, required): One of `"minutely"`, `"hourly"`, `"daily"`, `"weekly"`, `"monthly"`, `"yearly"`
- `interval` (integer, optional): Interval between recurrences (default: 1)
- `count` (integer, optional): Maximum number of occurrences
- `until` (string, optional): End date in ISO 8601 format
- `byMinute` (array of integers, optional): Minutes within the hour [0-60]
- `byHour` (array of integers, optional): Hours within the day [0-23]
- `byDay` (array of strings, optional): Days of the week ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
- `byMonthDay` (array of integers, optional): Days of the month (negative values count from end)
- `byMonth` (array of integers, optional): Months [1-12]

#### `completedDate` (string, optional)
ISO 8601 formatted date/time when the action was completed. Corresponds to `%` metadata in plaintext.
Typically added automatically by tooling when state changes to `completed`.

**Type**: String (ISO 8601)
**Omit if**: Not present in source

#### `id` (string, optional)
UUIDv7 identifier for the action. Corresponds to `#` metadata in plaintext.

**Type**: String
**Pattern**: `^[0-9a-fA-F-]+$` (UUID format)
**Omit if**: Not present in source

#### `parent_id` (string or null, optional)
UUID of the parent action. Null (or omitted) for root-level actions. Corresponds to the hierarchy level indicated by `>` prefixes in plaintext.

**Type**: String (UUID format) or null
**Pattern**: `^[0-9a-fA-F-]+$` (when not null)
**Default**: null (root action)
**Omit if**: Root action (depth = 0)

#### `depth` (integer, optional)
Nesting level of the action. Root actions have depth 0, their children have depth 1, etc. Matches the number of `>` prefixes in plaintext format.

**Type**: Integer
**Range**: 0-5 (matching plaintext depth limit)
**Default**: 0
**Omit if**: Root action (depth = 0)

**Note**: The `depth` field can be computed from `parent_id` by walking up the parent chain, but including it explicitly enables efficient queries without joins.

## Type Mappings

| Plaintext | JSON Type | Notes |
|-----------|-----------|-------|
| State marker `[x]` | String enum | Mapped to readable names |
| Priority `!1` | Integer | Numeric value only |
| Contexts `+a,b,c` | Array of strings | Split on comma |
| Do-date `@2025-01-19` | String (ISO 8601) | Within `doDate.datetime` |
| Duration `D30` | Integer | Minutes, within `doDate.duration` |
| Completed `%2025-01-19` | String (ISO 8601) | Direct mapping |
| UUID `#abc-123` | String | Direct mapping |
| Children `>` | String (UUID) | Parent's UUID in `parent_id` field |
| Depth level `>>`| Integer | Count of `>` markers in `depth` field |

## Optional Field Handling

Implementations should **omit** optional fields from JSON when they are not present in the source `.actions` file, rather than including them with `null` values. This keeps the JSON clean and minimal.

**Example**:
```json
// Good - minimal action
{
  "state": "not_started",
  "name": "Simple task"
}

// Avoid - unnecessary nulls
{
  "state": "not_started",
  "name": "Simple task",
  "description": null,
  "priority": null,
  "contexts": null
}
```

## Complete Example

Given this plaintext `.actions` file:
```actions
[x] Go to the store for chicken
    $ Make sure you get the stuff from the butcher directly
    !1
    *Run Errands
+Driving,Store,Market
@2025-01-19T08:30D30
%2025-01-19T10:30
#214342414342413424
>[ ] Get chicken from butcher
>>[-] Ask for organic options
```

The canonical JSON serialization is:
```json
{
  "actions": [
    {
      "state": "completed",
      "name": "Go to the store for chicken",
      "description": "Make sure you get the stuff from the butcher directly",
      "priority": 1,
      "story": "Run Errands",
      "contexts": ["Driving", "Store", "Market"],
      "doDate": {
        "datetime": "2025-01-19T08:30",
        "duration": 30
      },
      "completedDate": "2025-01-19T10:30",
      "id": "214342414342413424",
      "parent_id": null,
      "depth": 0
    },
    {
      "state": "not_started",
      "name": "Get chicken from butcher",
      "id": "018e3c2a-1234-7890-abcd-ef1234567890",
      "parent_id": "214342414342413424",
      "depth": 1
    },
    {
      "state": "in_progress",
      "name": "Ask for organic options",
      "id": "018e3c2b-5678-7890-abcd-ef1234567890",
      "parent_id": "018e3c2a-1234-7890-abcd-ef1234567890",
      "depth": 2
    }
  ]
}
```

**Note**: Actions are stored in a flat array. The parent-child relationships are expressed through `parent_id` references. To reconstruct the tree for display:
1. Filter actions where `parent_id` is null to get root actions
2. For each action, find children where `parent_id` matches the action's `id`
3. Use `depth` field for efficient indentation without recursive counting

## Validation

All JSON output should validate against the JSON Schema provided at `schema/actions.schema.json` in this repository. The schema is generated from the same regex patterns used by the tree-sitter grammar to ensure parsing and validation are consistent.

---
