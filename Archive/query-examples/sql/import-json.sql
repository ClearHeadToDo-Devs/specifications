-- Import JSON to SQL Schema
-- This script shows how to load JSON data into the canonical SQL schema
-- Assumes SQLite with JSON support

-- =============================================================================
-- Setup: Create a temporary table to hold JSON data
-- =============================================================================

CREATE TEMP TABLE json_import (
    json_data TEXT
);

-- Load your JSON file (this is database-specific)
-- For SQLite CLI:
-- .mode line
-- INSERT INTO json_import VALUES(readfile('examples/sample.json'));

-- =============================================================================
-- Import Root Actions
-- =============================================================================

INSERT INTO actions (
    id,
    parent_id,
    depth,
    state,
    name,
    description,
    priority,
    story,
    do_datetime,
    do_duration,
    completed_datetime
)
SELECT
    COALESCE(
        json_extract(value, '$.id'),
        lower(hex(randomblob(16)))  -- Generate UUID if not present
    ) as id,
    NULL as parent_id,  -- Root actions have no parent
    0 as depth,         -- Root actions are depth 0
    json_extract(value, '$.state'),
    json_extract(value, '$.name'),
    json_extract(value, '$.description'),
    CAST(json_extract(value, '$.priority') AS INTEGER),
    json_extract(value, '$.charter'),
    json_extract(value, '$.scheduledDateTime'),
    CAST(json_extract(value, '$.durationMinutes') AS INTEGER),
    json_extract(value, '$.completedDateTime')
FROM json_import,
     json_each(json_import.json_data, '$.actions');

-- =============================================================================
-- Import Contexts
-- =============================================================================

INSERT INTO action_contexts (action_id, context)
SELECT
    COALESCE(
        json_extract(action.value, '$.id'),
        lower(hex(randomblob(16)))
    ) as action_id,
    context.value as context
FROM json_import,
     json_each(json_import.json_data, '$.actions') as action,
     json_each(json_extract(action.value, '$.contexts')) as context
WHERE json_extract(action.value, '$.contexts') IS NOT NULL;

-- =============================================================================
-- Import Child Actions (Depth 1)
-- =============================================================================

INSERT INTO actions (
    id,
    parent_id,
    depth,
    state,
    name,
    description,
    priority,
    do_datetime,
    do_duration,
    completed_datetime
)
SELECT
    COALESCE(
        json_extract(child.value, '$.id'),
        lower(hex(randomblob(16)))
    ) as id,
    COALESCE(
        json_extract(parent.value, '$.id'),
        lower(hex(randomblob(16)))
    ) as parent_id,
    1 as depth,
    json_extract(child.value, '$.state'),
    json_extract(child.value, '$.name'),
    json_extract(child.value, '$.description'),
    CAST(json_extract(child.value, '$.priority') AS INTEGER),
    json_extract(child.value, '$.scheduledDateTime'),
    CAST(json_extract(child.value, '$.durationMinutes') AS INTEGER),
    json_extract(child.value, '$.completedDateTime')
FROM json_import,
     json_each(json_import.json_data, '$.actions') as parent,
     json_each(json_extract(parent.value, '$.children')) as child
WHERE json_extract(parent.value, '$.children') IS NOT NULL;

-- Import contexts for child actions
INSERT INTO action_contexts (action_id, context)
SELECT
    COALESCE(
        json_extract(child.value, '$.id'),
        lower(hex(randomblob(16)))
    ) as action_id,
    context.value as context
FROM json_import,
     json_each(json_import.json_data, '$.actions') as parent,
     json_each(json_extract(parent.value, '$.children')) as child,
     json_each(json_extract(child.value, '$.contexts')) as context
WHERE json_extract(child.value, '$.contexts') IS NOT NULL;

-- NOTE: For deeper nesting levels (depth 2-5), repeat the pattern above
-- with additional levels of json_each() nesting

-- =============================================================================
-- Validation
-- =============================================================================

-- Verify import counts
SELECT 'Root actions imported:' as description, COUNT(*) as count FROM actions WHERE depth = 0
UNION ALL
SELECT 'Child actions imported:', COUNT(*) FROM actions WHERE depth > 0
UNION ALL
SELECT 'Total contexts:', COUNT(*) FROM action_contexts
UNION ALL
SELECT 'Actions with schedule datetime:', COUNT(*) FROM actions WHERE do_datetime IS NOT NULL;

-- Check for orphaned children (should be 0)
SELECT 'Orphaned children (should be 0):' as description, COUNT(*) as count
FROM actions a
WHERE a.parent_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM actions p WHERE p.id = a.parent_id);

-- =============================================================================
-- Cleanup
-- =============================================================================

DROP TABLE json_import;
