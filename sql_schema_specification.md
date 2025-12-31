# SQL Storage Schema

## Purpose

While the `.actions` format is designed as human-readable plaintext and JSON enables data interchange, many applications require persistent relational storage for:

- **Complex queries with indexes** - Efficiently find actions by priority, context, due date, etc.
- **Multi-user concurrent access** - Multiple clients querying and updating the same dataset
- **Transactional updates** - Ensure data consistency when modifying related actions
- **Integration with existing systems** - Work alongside other database-backed applications
- **Performance at scale** - Handle thousands of actions with indexed queries

This section defines the canonical SQL schema for storing `.actions` data in relational databases.

## Schema Location

The canonical SQL schema is maintained at `schema/actions.sql` in the repository. It is designed for SQLite for maximum portability, but can be adapted for PostgreSQL, MySQL, or other relational databases.

## Design Philosophy

The schema prioritizes:

1. **Normalization** - Separate tables for multi-valued fields (contexts, recurrence) to enable efficient querying
2. **Performance** - Indexes on commonly-queried fields (state, priority, due date, story)
3. **Data integrity** - Foreign keys, constraints, CHECK clauses enforce format rules
4. **Simplicity** - Standard SQL features, minimal database-specific functionality
5. **Interoperability** - Tools using this schema can share databases and exchange data

## Schema Definition

### Core Tables

#### `actions` Table

Stores the main action data with one row per action. Hierarchical structure is represented via self-referencing `parent_id`.

```sql
CREATE TABLE actions (
    id TEXT PRIMARY KEY,
    parent_id TEXT REFERENCES actions(id) ON DELETE CASCADE,
    state TEXT NOT NULL CHECK(state IN ('not_started', 'completed', 'in_progress', 'blocked', 'cancelled')),
    name TEXT NOT NULL,
    description TEXT,
    priority INTEGER CHECK(priority >= 0),
    story TEXT,
    do_datetime TEXT,          -- ISO 8601 format
    do_duration INTEGER,        -- Duration in minutes
    completed_datetime TEXT,    -- ISO 8601 format
    depth INTEGER NOT NULL DEFAULT 0 CHECK(depth >= 0 AND depth <= 5)
);

-- Indexes for common queries
CREATE INDEX idx_actions_state ON actions(state);
CREATE INDEX idx_actions_priority ON actions(priority);
CREATE INDEX idx_actions_story ON actions(story);
CREATE INDEX idx_actions_do_datetime ON actions(do_datetime);
CREATE INDEX idx_actions_parent ON actions(parent_id);
CREATE INDEX idx_actions_depth ON actions(depth);
```

**Fields:**
- `id` - UUIDv7 identifier (optional in plaintext, generated if not provided)
- `parent_id` - Self-reference for hierarchical actions. NULL for root actions
- `state` - Current state, constrained to valid values
- `name` - Action name/title (required)
- `description` - Optional long-form description
- `priority` - Numeric priority (NULL if not specified)
- `story` - Parent project/story name (only for root actions where depth=0)
- `do_datetime` - Scheduled date/time in ISO 8601 format
- `do_duration` - Duration in minutes (NULL if not specified)
- `completed_datetime` - Completion timestamp in ISO 8601 format
- `depth` - Nesting level (0=root, 1-5=child depths)

#### `action_contexts` Table

Normalized storage for the multi-valued contexts field. Allows efficient querying by context.

```sql
CREATE TABLE action_contexts (
    action_id TEXT NOT NULL REFERENCES actions(id) ON DELETE CASCADE,
    context TEXT NOT NULL,
    PRIMARY KEY (action_id, context)
);

CREATE INDEX idx_action_contexts_context ON action_contexts(context);
```

**Why normalized?**
Enables efficient queries like "all actions in the 'work' context" without string parsing:
```sql
SELECT a.* FROM actions a
JOIN action_contexts c ON a.id = c.action_id
WHERE c.context = 'work';
```

#### `action_recurrence` Table

Stores recurrence rules for recurring actions. One row per action with recurrence.

```sql
CREATE TABLE action_recurrence (
    action_id TEXT PRIMARY KEY REFERENCES actions(id) ON DELETE CASCADE,
    frequency TEXT NOT NULL CHECK(frequency IN ('minutely', 'hourly', 'daily', 'weekly', 'monthly', 'yearly')),
    interval INTEGER DEFAULT 1 CHECK(interval >= 1),
    count INTEGER CHECK(count >= 1),
    until_date TEXT,            -- ISO 8601 format
    by_minute TEXT,             -- JSON array: [0, 15, 30]
    by_hour TEXT,               -- JSON array: [9, 17]
    by_day TEXT,                -- JSON array: ["Mon", "Wed"]
    by_month_day TEXT,          -- JSON array: [1, 15, -1]
    by_month TEXT               -- JSON array: [1, 6, 12]
);
```

**Note on JSON fields:**
The `by_*` fields store JSON arrays for simplicity in SQLite. Databases with native array support (PostgreSQL) can use array types instead.

### Helper Views

#### `actions_with_contexts` View

Denormalized view joining actions with their contexts for convenient querying.

```sql
CREATE VIEW actions_with_contexts AS
SELECT
    a.*,
    GROUP_CONCAT(c.context, ',') as contexts
FROM actions a
LEFT JOIN action_contexts c ON a.id = c.action_id
GROUP BY a.id;
```

## Type Mappings

Translation between plaintext, JSON, and SQL representations:

| Plaintext | JSON Type | SQL Type | SQL Table | Notes |
|-----------|-----------|----------|-----------|-------|
| State `[x]` | String enum | `TEXT CHECK(...)` | `actions.state` | Enforced with CHECK constraint |
| Name | String | `TEXT NOT NULL` | `actions.name` | Required field |
| Description `$` | String | `TEXT` | `actions.description` | NULL if not present |
| Priority `!1` | Integer | `INTEGER CHECK(>= 0)` | `actions.priority` | NULL if not present |
| Story `*` | String | `TEXT` | `actions.story` | NULL if not present, only for root actions |
| Contexts `+a,b` | Array of strings | Separate table | `action_contexts` | Normalized for querying |
| Do-date `@` | String (ISO 8601) | `TEXT` | `actions.do_datetime` | Stored as ISO 8601 string |
| Duration `D30` | Integer (minutes) | `INTEGER` | `actions.do_duration` | NULL if not present |
| Recurrence `R` | Object | Separate table | `action_recurrence` | NULL if not recurring |
| Completed `%` | String (ISO 8601) | `TEXT` | `actions.completed_datetime` | NULL if not completed |
| UUID `#` | String | `TEXT PRIMARY KEY` | `actions.id` | Generated if not provided |
| Children `>` | Nested array | `parent_id` self-reference | `actions.parent_id` | Hierarchical via foreign key |

## Design Decisions

### Why normalize contexts into a separate table?

**Benefit:** Enables efficient filtering and aggregation
```sql
-- Find all actions in 'work' context
SELECT a.* FROM actions a
JOIN action_contexts c ON a.id = c.action_id
WHERE c.context = 'work';

-- Count actions by context
SELECT context, COUNT(*) FROM action_contexts GROUP BY context;
```

**Alternative:** Store as JSON array or comma-separated TEXT
**Trade-off:** Simpler schema, but requires string parsing or JSON functions for queries

### Why store dates as TEXT instead of DATE/TIMESTAMP?

**Benefit:** Preserves full ISO 8601 format including timezone information
**Benefit:** Portable across databases (SQLite has limited date types)
**Benefit:** Matches JSON format exactly

**Note:** SQL date functions can still operate on ISO 8601 TEXT:
```sql
-- SQLite
SELECT * FROM actions WHERE date(do_datetime) = date('now');

-- PostgreSQL
SELECT * FROM actions WHERE do_datetime::timestamp >= NOW();
```

### Why use parent_id instead of a closure table?

**Rationale:** The format limits nesting to 5 levels, making a simple parent_id sufficient

**Benefit:** Simple schema, easy to understand
**Trade-off:** Queries for "all descendants" require recursive CTEs

**For deep tree queries:**
```sql
-- Get all descendants of an action (SQLite/PostgreSQL)
WITH RECURSIVE descendants AS (
  SELECT * FROM actions WHERE id = ?
  UNION ALL
  SELECT a.* FROM actions a
  JOIN descendants d ON a.parent_id = d.id
)
SELECT * FROM descendants;
```

**Alternative:** Add a closure table for applications needing frequent tree traversal

### Why separate table for recurrence?

**Rationale:** Most actions don't recur - normalization saves space
**Benefit:** Clean separation of concerns
**Benefit:** Easy to query "all recurring actions"

## Example Queries

### Basic Filters

**All P1 actions:**
```sql
SELECT * FROM actions WHERE priority = 1;
```

**All completed actions:**
```sql
SELECT * FROM actions WHERE state = 'completed';
```

**Actions in 'work' context:**
```sql
SELECT a.* FROM actions a
JOIN action_contexts c ON a.id = c.action_id
WHERE c.context = 'work';
```

**Actions in 'work' OR 'urgent' context:**
```sql
SELECT DISTINCT a.* FROM actions a
JOIN action_contexts c ON a.id = c.action_id
WHERE c.context IN ('work', 'urgent');
```

### Date Queries

**Actions due today:**
```sql
SELECT * FROM actions
WHERE date(do_datetime) = date('now');
```

**Actions due this week:**
```sql
SELECT * FROM actions
WHERE do_datetime >= date('now', 'weekday 0', '-7 days')
  AND do_datetime < date('now', 'weekday 0');
```

**Overdue not-started actions:**
```sql
SELECT * FROM actions
WHERE state = 'not_started'
  AND do_datetime < datetime('now');
```

### Aggregate Queries

**Completion rate by project:**
```sql
SELECT
  story,
  COUNT(*) as total,
  SUM(CASE WHEN state = 'completed' THEN 1 ELSE 0 END) as completed,
  ROUND(100.0 * SUM(CASE WHEN state = 'completed' THEN 1 ELSE 0 END) / COUNT(*), 2) as completion_rate
FROM actions
WHERE story IS NOT NULL AND depth = 0
GROUP BY story;
```

**Action count by state:**
```sql
SELECT state, COUNT(*) as count
FROM actions
GROUP BY state
ORDER BY count DESC;
```

**Priority distribution:**
```sql
SELECT
  COALESCE(priority, 999) as priority,
  COUNT(*) as count
FROM actions
GROUP BY priority
ORDER BY priority;
```

### Hierarchical Queries

**Root actions only:**
```sql
SELECT * FROM actions WHERE parent_id IS NULL;
-- Or equivalently:
SELECT * FROM actions WHERE depth = 0;
```

**Actions with children:**
```sql
SELECT DISTINCT p.* FROM actions p
JOIN actions c ON c.parent_id = p.id;
```

**Immediate children of an action:**
```sql
SELECT * FROM actions WHERE parent_id = ?;
```

**All descendants (recursive):**
```sql
WITH RECURSIVE descendants AS (
  SELECT * FROM actions WHERE id = ?
  UNION ALL
  SELECT a.* FROM actions a
  JOIN descendants d ON a.parent_id = d.id
)
SELECT * FROM descendants WHERE id != ?;  -- Exclude the parent itself
```

### Complex Queries

**P1 actions in 'work' context due this week:**
```sql
SELECT a.* FROM actions a
JOIN action_contexts c ON a.id = c.action_id
WHERE a.priority = 1
  AND c.context = 'work'
  AND a.do_datetime >= date('now', 'weekday 0', '-7 days')
  AND a.do_datetime < date('now', 'weekday 0');
```

**Blocked actions with no children:**
```sql
SELECT a.* FROM actions a
LEFT JOIN actions c ON c.parent_id = a.id
WHERE a.state = 'blocked'
  AND c.id IS NULL;
```

**Actions with multiple contexts:**
```sql
SELECT action_id, COUNT(*) as context_count
FROM action_contexts
GROUP BY action_id
HAVING COUNT(*) > 1;
```

## Importing from JSON

Example of loading JSON data into the SQL schema:

```sql
-- Using SQLite JSON functions
-- Assuming you have a 'json_data' column with the full JSON

-- Insert root actions
INSERT INTO actions (id, state, name, description, priority, story, do_datetime, do_duration, completed_datetime, depth)
SELECT
  json_extract(value, '$.id'),
  json_extract(value, '$.state'),
  json_extract(value, '$.name'),
  json_extract(value, '$.description'),
  json_extract(value, '$.priority'),
  json_extract(value, '$.story'),
  json_extract(value, '$.doDate.datetime'),
  json_extract(value, '$.doDate.duration'),
  json_extract(value, '$.completedDate'),
  0  -- Root actions have depth 0
FROM json_each((SELECT json_data FROM import_table), '$.actions');

-- Insert contexts
INSERT INTO action_contexts (action_id, context)
SELECT
  json_extract(action.value, '$.id'),
  context.value
FROM json_each((SELECT json_data FROM import_table), '$.actions') as action,
     json_each(json_extract(action.value, '$.contexts')) as context;
```

For more examples, see `examples/queries/sql/` in the repository.

## Database-Specific Adaptations

### PostgreSQL

**Type changes:**
```sql
-- Use VARCHAR with lengths
name VARCHAR(500) NOT NULL

-- Native array types for contexts
CREATE TABLE actions (
  ...
  contexts TEXT[]  -- Instead of separate table
);

-- Or use JSONB for recurrence fields
by_day JSONB  -- Instead of TEXT
```

**Advantages:**
- Native array operations
- JSONB query capabilities
- Better full-text search (tsvector)

### MySQL

**Type changes:**
```sql
-- Add VARCHAR lengths
name VARCHAR(500) NOT NULL

-- Use DATETIME instead of TEXT for dates
do_datetime DATETIME

-- Use ENUM for state (optional)
state ENUM('not_started', 'completed', 'in_progress', 'blocked', 'cancelled')
```

### General Adaptations

**Add timestamps:**
```sql
ALTER TABLE actions ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE actions ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
```

**Add soft deletes:**
```sql
ALTER TABLE actions ADD COLUMN deleted_at TIMESTAMP NULL;
CREATE INDEX idx_actions_deleted ON actions(deleted_at);
```

**Add user ownership:**
```sql
ALTER TABLE actions ADD COLUMN user_id INTEGER REFERENCES users(id);
CREATE INDEX idx_actions_user ON actions(user_id);
```

## Validation

Tools implementing this schema should:

1. Validate that imported JSON conforms to `schema/actions.schema.json`
2. Enforce foreign key constraints (ensure parent_id references valid actions)
3. Maintain depth consistency (parent depth + 1 = child depth)
4. Ensure story is only set for root actions (depth = 0)
5. Validate ISO 8601 format for date fields before insertion

## Further Reading

- See `schema/actions.sql` for the complete reference implementation
- See `examples/queries/sql/` for more query examples
- See `examples/queries/jq/` for JSON manipulation before SQL import
