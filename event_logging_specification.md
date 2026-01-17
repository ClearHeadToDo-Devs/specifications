# Event Logging Specification

## Purpose

The event logging system provides persistent, append-only tracking of action lifecycle events for time-series analytics and historical analysis.

**This specification defines event sourcing for action files:**
- Events are the source of truth for "what happened when"
- Current state is derived by replaying events (no separate state database)
- Enables time-travel queries and cross-device analytics

**Use Cases:**
- **Time-series analytics** - "How many actions were open on 2026-01-15?"
- **Completion patterns** - Track streaks, completion rates, velocity over time
- **Recurring action instances** - Log each occurrence separately
- **Cross-device aggregation** - Combine event history from multiple devices
- **Audit trail** - Full history of changes to actions

## Relationship to Other Specifications

### vs. Action Files (Source of Truth for Current State)

`.actions` files define the current state - what actions exist right now and their properties. Event logging captures the history of how that state changed over time.

**Example:**
```actions
# inbox.actions (current state)
[x] Weekly standup @2026-01-14T09:00 R:FREQ=WEEKLY;BYDAY=TU #abc123
```

```sql
-- events.db (history of changes)
INSERT 2026-01-14 09:15:32 | instance_completed | abc123
INSERT 2026-01-14 09:15:33 | instance_due       | abc123 (next: 2026-01-21)
```

### vs. SQL Schema Specification (In-Memory Query Database)

**SQL Schema** (`sql_schema_specification.md`) - In-memory SQLite database for querying current state
- **Purpose:** Fast queries on current actions (filter by priority, context, due date)
- **Lifecycle:** Ephemeral, recreated from `.actions` files on demand
- **Updates:** Read-only, rebuilt when files change

**Event Logging** (this spec) - Persistent SQLite database for historical events
- **Purpose:** Time-series analytics, audit trail, completion history
- **Lifecycle:** Persistent, append-only, never deleted
- **Updates:** Write-only, events appended as actions change

### vs. Application Logs (Debugging/Operational)

**Application logs** (stdout → systemd/syslog) - Operational debugging
- "Parsed 47 actions from file"
- "LSP server started on port 9999"
- "Normalized UUID references in 23ms"

**Event logging** (this spec) - Semantic user actions
- "Action abc123 completed at 09:15:32"
- "Action xyz789 priority changed from 2 to 1"
- "Instance of recurring action became due"

Application logs are tool-specific and ephemeral. Events are platform-level and persistent.

## Design Principles

1. **Event Sourcing** - Events are source of truth, state is derived by replaying
2. **Append-Only** - Events are never modified or deleted, only appended
3. **Machine-Wide** - Single database per machine captures events across all projects
4. **Local-First** - Works offline without network connectivity
5. **Simple Schema** - No enum constraints, flexible JSON metadata, forward-compatible
6. **Platform-Agnostic** - Any tool (CLI, LSP, mobile app) can read and write

## Storage Location

### Default Location

Events are stored in the XDG state directory (machine-wide, machine-specific):

**Linux/macOS:** `~/.local/state/clearhead/events.db` (or `$XDG_STATE_HOME/clearhead/events.db`)
**Windows:** `%LOCALAPPDATA%\clearhead\state\events.db`

**Rationale for XDG_STATE_HOME:**
- Events are **machine-specific state**, not user data to be synced
- Avoids conflicts if user git-tracks `XDG_DATA_HOME`
- Semantically correct: logs/history vs user-created content
- Binary database files don't belong in version control

See [Configuration Specification](./configuration.md) for full XDG directory structure.

### Configuration

Custom path can be specified via:

**Config file** (`~/.config/clearhead/config.json`):
```json
{
  "events_db_path": "~/custom/path/events.db"
}
```

**Environment variable:**
```bash
export CLEARHEAD_EVENTS_DB_PATH=/path/to/events.db
```

### Machine-Wide Storage

Events are stored **machine-wide** in XDG_STATE_HOME. This enables:
- Cross-project analytics ("How many actions completed this week?")
- Unified history for aggregation server
- Simpler mental model (one events database per machine)
- No conflicts with user data directories

## Schema Definition

### Database Initialization

```sql
-- Enable WAL mode for concurrent writes
PRAGMA journal_mode=WAL;

-- Core events table
CREATE TABLE events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,  -- Local sequential ordering
    event_id TEXT UNIQUE NOT NULL,         -- UUIDv7 for global identity
    timestamp TEXT NOT NULL,               -- ISO 8601: when event occurred
    event_type TEXT NOT NULL,              -- Type of event (flexible, no enum)
    action_uuid TEXT NOT NULL,             -- UUID of action this event relates to
    file_path TEXT,                        -- Path to .actions file (relative or absolute)
    metadata TEXT NOT NULL DEFAULT '{}'    -- JSON object with event-specific data
);

-- Indexes for common query patterns
CREATE INDEX idx_events_timestamp ON events(timestamp);
CREATE INDEX idx_events_action_uuid ON events(action_uuid);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_type_timestamp ON events(event_type, timestamp);
CREATE INDEX idx_events_file_path ON events(file_path);
```

**Schema Design Rationale:**

- **`id` (autoincrement):** Guarantees local event ordering, fast inserts
- **`event_id` (UUIDv7):** Global unique identifier across devices for deduplication
- **No CHECK constraints:** Forward-compatible, tools ignore unknown event_type values
- **JSON metadata:** Flexible schema, add fields without migrations
- **WAL mode:** Multiple processes can write concurrently (CLI + LSP)

## Event Types

Event types are strings, not enums. This allows tools to add new event types without schema migrations. Tools should ignore event types they don't recognize.

### Core Lifecycle Events

| Event Type | When Emitted | Common Metadata Fields |
|------------|--------------|------------------------|
| `action_created` | New action added to file | `name`, `state`, `priority`, `do_date` |
| `action_completed` | State changed to `[x]` | `name`, `completed_at` |
| `action_cancelled` | State changed to `[_]` | `name`, `cancelled_at` |
| `action_started` | State changed to `[>]` | `name` |
| `action_blocked` | State changed to `[!]` | `name`, `reason` |
| `action_deleted` | Action removed from file | `name` |

### Recurring Action Events

| Event Type | When Emitted | Common Metadata Fields |
|------------|--------------|------------------------|
| `instance_due` | Instance becomes due (midnight on due date) | `template_uuid`, `occurrence_date`, `recurrence_rule` |
| `instance_completed` | Recurring action completed | `template_uuid`, `scheduled_date`, `completed_date`, `next_occurrence` |
| `instance_skipped` | User skips an occurrence | `template_uuid`, `occurrence_date`, `reason` |

### Property Change Events

| Event Type | When Emitted | Common Metadata Fields |
|------------|--------------|------------------------|
| `priority_changed` | Priority modified | `old_priority`, `new_priority` |
| `due_date_changed` | `@datetime` changed | `old_date`, `new_date` |
| `description_changed` | `$description` changed | `old_description`, `new_description` |
| `context_added` | `+context` added | `context` |
| `context_removed` | `+context` removed | `context` |

**Note:** Tools may emit only significant events. Minor edits (typo fixes, whitespace) need not generate events.

## Metadata Structure

The `metadata` field is a JSON object that varies by event type. Common fields:

```json
{
  "name": "Action name",
  "state": "completed",
  "priority": 1,
  "file": "inbox.actions"
}
```

### Example Metadata by Event Type

**`action_created`:**
```json
{
  "name": "Weekly standup",
  "state": "not_started",
  "priority": 2,
  "contexts": ["work", "meetings"],
  "do_date": "2026-01-14T09:00:00Z",
  "has_recurrence": true
}
```

**`action_completed`:**
```json
{
  "name": "Weekly standup",
  "previous_state": "not_started",
  "scheduled_date": "2026-01-14T09:00:00Z",
  "completed_date": "2026-01-14T09:15:00Z"
}
```

**`instance_completed`:**
```json
{
  "template_uuid": "019ba9dc-695c-71a2-9351-f561fea82e3b",
  "template_name": "Weekly standup",
  "scheduled_date": "2026-01-14T09:00:00Z",
  "completed_date": "2026-01-14T09:15:00Z",
  "next_occurrence": "2026-01-21T09:00:00Z"
}
```

**`priority_changed`:**
```json
{
  "name": "Fix critical bug",
  "old_priority": 3,
  "new_priority": 1
}
```

## Event Sourcing Architecture

The core architectural pattern: **derive state from events, not from separate state database**.

### Conceptual Flow

```
events.db (append-only log)
    ↓ replay events for file
current state (in-memory)
    ↓ compare with
parsed file (new state from disk)
    ↓ structural diff
new events → append to events.db
```

### When Events Are Emitted

Events are emitted when `.actions` files are saved, using structural diffing:

1. **Load last known state** - Replay events for this file to reconstruct last known state
2. **Parse current file** - Read file from disk, parse current state
3. **Structural diff** - Compare states to find what changed
4. **Emit events** - Append events for each change to events.db
5. **State is now current** - Next time, replay includes these events

### Who Emits Events

| Tool | Trigger | What's Diffed |
|------|---------|---------------|
| **CLI** | After any mutation command (`complete`, `add`, `archive`, etc.) | Modified file |
| **LSP Server** | On `textDocument/didSave` notification | Saved file |
| **Neovim** | `autocmd BufWritePost *.actions` | Saved file |
| **Web UI** | After saving changes to file | Modified file |

**Important:** Events are emitted on **save**, not on keystroke (avoids noisy events during editing).

### Deriving State from Events

To answer "what did action X look like at time T?", replay events up to timestamp T:

```rust
fn derive_state_at(file_path: &str, timestamp: &str) -> HashMap<String, Action> {
    let events = query_events(file_path, timestamp)?;
    let mut actions = HashMap::new();

    for event in events {
        match event.event_type {
            "action_created" => {
                let action = parse_metadata_as_action(event.metadata);
                actions.insert(event.action_uuid, action);
            }
            "action_completed" => {
                actions.get_mut(&event.action_uuid)?.state = "completed";
            }
            "action_deleted" => {
                actions.remove(&event.action_uuid);
            }
            "priority_changed" => {
                let new_priority = event.metadata["new_priority"];
                actions.get_mut(&event.action_uuid)?.priority = new_priority;
            }
            // ... handle other event types
        }
    }

    actions
}
```

### Performance: Snapshot Caching (Optional Optimization)

Replaying thousands of events can be slow. Implementations MAY periodically snapshot current state:

```sql
CREATE TABLE state_snapshots (
    file_path TEXT PRIMARY KEY,
    snapshot_timestamp TEXT NOT NULL,
    snapshot_data TEXT NOT NULL  -- JSON: full action state
);
```

**Replay becomes:**
1. Load latest snapshot for file (if exists)
2. Replay events since snapshot timestamp
3. Much faster than replaying from beginning

**Snapshot strategy:**
- Create snapshot every N events (e.g., 1000)
- Create snapshot daily for active files
- Snapshots are optimization, not source of truth (can always replay from events)

## Implementation Guidelines

### Emitting Events

```rust
fn emit_event(
    event_type: &str,
    action_uuid: &str,
    file_path: &str,
    metadata: serde_json::Value
) -> Result<()> {
    let conn = Connection::open(events_db_path())?;
    conn.execute(
        "INSERT INTO events (event_id, timestamp, event_type, action_uuid, file_path, metadata)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        params![
            uuid_v7(),
            Utc::now().to_rfc3339(),
            event_type,
            action_uuid,
            file_path,
            metadata.to_string()
        ]
    )?;
    Ok(())
}
```

### Structural Diffing

```rust
fn on_file_saved(file_path: &str) -> Result<()> {
    // 1. Derive last known state by replaying events
    let old_state = derive_current_state(file_path)?;

    // 2. Parse file to get new state
    let new_state = parse_file(file_path)?;

    // 3. Diff
    let events = diff_states(old_state, new_state, file_path)?;

    // 4. Append events in single transaction
    let conn = Connection::open(events_db_path())?;
    let tx = conn.transaction()?;
    for event in events {
        emit_event_in_tx(&tx, event)?;
    }
    tx.commit()?;

    Ok(())
}

fn diff_states(
    old: HashMap<String, Action>,
    new: HashMap<String, Action>,
    file_path: &str
) -> Vec<Event> {
    let mut events = vec![];

    // Detect new actions
    for (uuid, action) in &new {
        if !old.contains_key(uuid) {
            events.push(Event::created(uuid, action, file_path));
        }
    }

    // Detect deleted actions
    for (uuid, action) in &old {
        if !new.contains_key(uuid) {
            events.push(Event::deleted(uuid, action, file_path));
        }
    }

    // Detect changed actions
    for (uuid, new_action) in &new {
        if let Some(old_action) = old.get(uuid) {
            if old_action.state != new_action.state {
                events.push(Event::state_changed(uuid, old_action, new_action, file_path));
            }
            if old_action.priority != new_action.priority {
                events.push(Event::priority_changed(uuid, old_action, new_action, file_path));
            }
            // ... check other fields
        }
    }

    events
}
```

### Concurrent Writes (WAL Mode)

SQLite in WAL (Write-Ahead Logging) mode allows multiple processes to write simultaneously:

```rust
fn init_events_db() -> Result<Connection> {
    let conn = Connection::open(events_db_path())?;
    conn.execute("PRAGMA journal_mode=WAL", [])?;
    Ok(conn)
}
```

**Benefits:**
- CLI and LSP can both write events without blocking
- Readers don't block writers
- No need for separate daemon process

## Query Patterns

### Actions Open on Specific Date

```sql
-- Find all actions open on 2026-01-15
WITH action_states AS (
  SELECT
    action_uuid,
    event_type,
    timestamp,
    metadata
  FROM events
  WHERE timestamp <= '2026-01-15T23:59:59Z'
  ORDER BY id
)
SELECT DISTINCT action_uuid
FROM action_states
WHERE event_type = 'action_created'
  AND action_uuid NOT IN (
    SELECT action_uuid FROM action_states
    WHERE event_type IN ('action_completed', 'action_cancelled', 'action_deleted')
  );
```

### Completion Rate Over Time

```sql
SELECT
  DATE(timestamp) as date,
  COUNT(*) as completions
FROM events
WHERE event_type IN ('action_completed', 'instance_completed')
  AND timestamp >= '2026-01-01'
  AND timestamp < '2026-02-01'
GROUP BY DATE(timestamp)
ORDER BY date;
```

### Instance History for Recurring Action

```sql
SELECT
  timestamp,
  event_type,
  json_extract(metadata, '$.scheduled_date') as scheduled,
  json_extract(metadata, '$.completed_date') as completed
FROM events
WHERE json_extract(metadata, '$.template_uuid') = '019ba9dc-695c-71a2-9351-f561fea82e3b'
  AND event_type IN ('instance_due', 'instance_completed', 'instance_skipped')
ORDER BY timestamp DESC;
```

### Action Lifecycle Timeline

```sql
SELECT
  timestamp,
  event_type,
  metadata
FROM events
WHERE action_uuid = 'abc123-def456-789'
ORDER BY timestamp;
```

## Aggregation Server (Optional)

For cross-device analytics, events can be synced to a central aggregation server.

### Architecture

```
Device 1: ~/.local/state/clearhead/events.db ─┐
Device 2: ~/.local/state/clearhead/events.db ─┼→ DuckDB Server
Device 3: ~/.local/state/clearhead/events.db ─┘
                                                   ↓
                                             MotherDuck (optional)
```

### DuckDB for Aggregation

DuckDB can directly query SQLite files without import:

```sql
-- Attach SQLite databases from multiple devices
ATTACH 'device1/events.db' AS device1 (TYPE SQLITE);
ATTACH 'device2/events.db' AS device2 (TYPE SQLITE);
ATTACH 'device3/events.db' AS device3 (TYPE SQLITE);

-- Query across all devices
SELECT
  DATE(timestamp) as date,
  COUNT(*) as total_completions
FROM (
  SELECT * FROM device1.events
  UNION ALL
  SELECT * FROM device2.events
  UNION ALL
  SELECT * FROM device3.events
)
WHERE event_type = 'action_completed'
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

### Sync Protocol (Future Specification)

Details of sync protocol deferred to separate specification. Key requirements:
- **Offline-first:** Local events.db always works without server
- **Append-only sync:** Send new events since last sync (by event_id)
- **Idempotent:** UUIDv7 `event_id` prevents duplicates
- **Optional:** Server is for analytics, not required for core functionality

## Migration and Schema Evolution

### Adding New Event Types

No schema migration needed - just start emitting new event types:

```rust
// CLI v1.0.0 emits these
emit_event("action_completed", ...);

// CLI v1.1.0 adds new type (no migration)
emit_event("action_archived", ...);
```

Old tools ignore unknown event types when replaying.

### Adding New Metadata Fields

Just add fields to JSON metadata:

```json
// Old events
{"name": "Task", "priority": 1}

// New events (no migration needed)
{"name": "Task", "priority": 1, "estimated_duration": 30, "tags": ["urgent"]}
```

Old tools ignore unknown fields.

### Schema Versioning

Optional: Add version metadata table for future breaking changes:

```sql
CREATE TABLE schema_version (
  version INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL
);

INSERT INTO schema_version VALUES (1, datetime('now'));
```

## Examples

### Example 1: Completing a Recurring Action

**User completes recurring action:**
```bash
clearhead complete abc123
```

**File state before:**
```actions
[ ] Weekly standup @2026-01-14T09:00 R:FREQ=WEEKLY;BYDAY=TU #abc123
```

**File state after (unchanged - template persists):**
```actions
[ ] Weekly standup @2026-01-14T09:00 R:FREQ=WEEKLY;BYDAY=TU #abc123
```

**Events emitted:**
```sql
INSERT INTO events VALUES (
  1,
  '019baaec-1234-7991-be34-abc123',
  '2026-01-14T09:15:32Z',
  'instance_completed',
  'abc123',
  'inbox.actions',
  '{"template_uuid":"abc123","scheduled_date":"2026-01-14T09:00:00Z","completed_date":"2026-01-14T09:15:32Z","next_occurrence":"2026-01-21T09:00:00Z"}'
);

INSERT INTO events VALUES (
  2,
  '019baaec-5678-7991-be34-def456',
  '2026-01-14T09:15:33Z',
  'instance_due',
  'abc123',
  'inbox.actions',
  '{"template_uuid":"abc123","occurrence_date":"2026-01-21T09:00:00Z"}'
);
```

### Example 2: Hand-Editing a File

**User opens file in editor and changes priority:**

**Before:**
```actions
[ ] Fix bug !2 #xyz789
```

**After:**
```actions
[ ] Fix bug !1 #xyz789
```

**On save:**
1. Neovim autocmd triggers: `!clearhead sync-events %`
2. CLI replays events to derive last known state: priority=2
3. CLI parses file to get new state: priority=1
4. CLI detects change and emits event:

```sql
INSERT INTO events VALUES (
  3,
  '019baaed-abcd-7991-be34-123456',
  '2026-01-14T14:22:10Z',
  'priority_changed',
  'xyz789',
  'work.actions',
  '{"name":"Fix bug","old_priority":2,"new_priority":1}'
);
```

## Open Questions

Issues to resolve in future revisions:

1. **Event granularity** - Log all field changes or only significant ones? (Current: only significant)
2. **Snapshot strategy** - When/how often to snapshot for performance? (Current: optional, undefined frequency)
3. **Bulk operations** - How to represent "archived 50 actions"? 50 events or summary event? (Current: 50 events)
4. **Retention** - Should events ever be pruned? If so, when? (Current: never, append-only forever)
5. **Cross-file moves** - If action moves between files, delete+create or new event type? (Current: undefined)

## See Also

- [Configuration](./configuration.md) - XDG paths, `state_dir` setting
- [Sync Architecture](./sync_architecture.md) - How events.db fits in CRDT architecture
- [Naming Conventions](./naming_conventions.md) - Workspace structure
- [Action File Format](./action_file_format.md) - DSL syntax for actions

---

**Version:** 1.0.0
**Status:** Implemented
**Last updated:** 2026-01-10
