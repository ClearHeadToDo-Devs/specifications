-- Canonical SQL Schema for .actions File Format
-- Version: 1.0.0
-- Database: SQLite (adaptable to PostgreSQL, MySQL, etc.)
--
-- This schema provides a normalized relational representation of the .actions
-- file format. It is designed for applications that need:
-- - Persistent storage with complex queries
-- - Multi-user concurrent access
-- - Performance at scale with indexes
-- - Integration with existing database systems
--
-- For the complete specification, see docs/action_specification.md
-- For query examples, see examples/queries/sql/

-- =============================================================================
-- Core Tables
-- =============================================================================

-- Main actions table
-- Stores one row per action with hierarchical structure via parent_id
CREATE TABLE actions (
    -- Identity
    id TEXT PRIMARY KEY,                 -- UUIDv7 (generated if not provided)
    parent_id TEXT REFERENCES actions(id) ON DELETE CASCADE,
    depth INTEGER NOT NULL DEFAULT 0 CHECK(depth >= 0 AND depth <= 5),

    -- Required fields
    state TEXT NOT NULL CHECK(state IN (
        'not_started',
        'completed',
        'in_progress',
        'blocked',
        'cancelled'
    )),
    name TEXT NOT NULL,

    -- Optional metadata
    description TEXT,
    priority INTEGER CHECK(priority >= 0),
    story TEXT,                          -- Only for root actions (depth = 0)

    -- Scheduling
    do_datetime TEXT,                    -- ISO 8601 format: YYYY-MM-DDTHH:MM
    do_duration INTEGER,                 -- Duration in minutes

    -- Completion tracking
    completed_datetime TEXT              -- ISO 8601 format: YYYY-MM-DDTHH:MM
);

-- Normalized contexts table
-- Stores multi-valued context tags for efficient querying
CREATE TABLE action_contexts (
    action_id TEXT NOT NULL REFERENCES actions(id) ON DELETE CASCADE,
    context TEXT NOT NULL,
    PRIMARY KEY (action_id, context)
);

-- Recurrence rules table
-- Stores recurrence information for recurring actions per RFC 5545 RRULE syntax
-- Maps from RRULE format (R:FREQ=WEEKLY;BYDAY=MO,WE,FR) to normalized DB fields
CREATE TABLE action_recurrence (
    action_id TEXT PRIMARY KEY REFERENCES actions(id) ON DELETE CASCADE,

    -- Required (FREQ in RRULE)
    frequency TEXT NOT NULL CHECK(frequency IN (
        'secondly',  -- SECONDLY (rarely used)
        'minutely',  -- MINUTELY
        'hourly',    -- HOURLY
        'daily',     -- DAILY
        'weekly',    -- WEEKLY
        'monthly',   -- MONTHLY
        'yearly'     -- YEARLY
    )),

    -- Optional bounds
    interval INTEGER DEFAULT 1 CHECK(interval >= 1),  -- INTERVAL (default 1)
    count INTEGER CHECK(count >= 1),                  -- COUNT (max occurrences)
    until_date TEXT,                                  -- UNTIL (ISO 8601 format)

    -- Note: count and until_date are mutually exclusive per RFC 5545

    -- Semantic bounds (stored as JSON arrays for multi-value fields)
    -- Maps from RRULE comma-separated values to JSON arrays
    by_second TEXT,      -- BYSECOND: JSON [0, 15, 30, 45]
    by_minute TEXT,      -- BYMINUTE: JSON [0, 15, 30, 45]
    by_hour TEXT,        -- BYHOUR: JSON [9, 12, 17]
    by_day TEXT,         -- BYDAY: JSON ["MO", "WE", "FR"] or ["1MO", "-1FR"] with modifiers
    by_month_day TEXT,   -- BYMONTHDAY: JSON [1, 15, -1] (negative = from end)
    by_year_day TEXT,    -- BYYEARDAY: JSON [1, 100, -1] (day of year)
    by_week_no TEXT,     -- BYWEEKNO: JSON [1, 20, -1] (week of year)
    by_month TEXT,       -- BYMONTH: JSON [1, 6, 12] (1=Jan, 12=Dec)
    by_set_pos TEXT,     -- BYSETPOS: JSON [1, -1] (limits to nth occurrence)
    week_start TEXT DEFAULT 'MO' CHECK(week_start IN (
        'MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'
    ))                   -- WKST: Week start day (default Monday per RFC 5545)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Actions table indexes for common query patterns
CREATE INDEX idx_actions_state ON actions(state);
CREATE INDEX idx_actions_priority ON actions(priority);
CREATE INDEX idx_actions_story ON actions(story);
CREATE INDEX idx_actions_do_datetime ON actions(do_datetime);
CREATE INDEX idx_actions_parent ON actions(parent_id);
CREATE INDEX idx_actions_depth ON actions(depth);
CREATE INDEX idx_actions_completed ON actions(completed_datetime);

-- Context index for filtering by context
CREATE INDEX idx_action_contexts_context ON action_contexts(context);

-- =============================================================================
-- Views
-- =============================================================================

-- Convenience view: actions with contexts as comma-separated list
CREATE VIEW actions_with_contexts AS
SELECT
    a.*,
    GROUP_CONCAT(c.context, ',') as contexts
FROM actions a
LEFT JOIN action_contexts c ON a.id = c.action_id
GROUP BY a.id;

-- Convenience view: root actions only
CREATE VIEW root_actions AS
SELECT * FROM actions WHERE depth = 0;

-- Convenience view: actions with children
CREATE VIEW parent_actions AS
SELECT DISTINCT p.*
FROM actions p
JOIN actions c ON c.parent_id = p.id;

-- =============================================================================
-- Notes
-- =============================================================================

-- Database-specific adaptations:
--
-- PostgreSQL:
--   - Use VARCHAR(n) instead of TEXT for better performance
--   - Use native ARRAY types for contexts: contexts TEXT[]
--   - Use JSONB for recurrence fields
--   - Use TIMESTAMP WITH TIME ZONE for date fields
--
-- MySQL:
--   - Add VARCHAR lengths: VARCHAR(500)
--   - Use DATETIME for date fields
--   - Use ENUM for state field (optional)
--   - Use JSON type for recurrence fields
--
-- Data integrity:
--   - Foreign keys ensure parent_id references valid actions
--   - CHECK constraints enforce valid states and priorities
--   - Indexes improve query performance
--   - CASCADE deletes maintain referential integrity
--
-- Hierarchical queries:
--   - Use recursive CTEs for tree traversal:
--     WITH RECURSIVE descendants AS (
--       SELECT * FROM actions WHERE id = ?
--       UNION ALL
--       SELECT a.* FROM actions a
--       JOIN descendants d ON a.parent_id = d.id
--     )
--     SELECT * FROM descendants;
--
-- For more information:
--   - See docs/action_specification.md for complete documentation
--   - See examples/queries/sql/ for query examples
