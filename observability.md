# Observability Specification

**Version:** 1.0.0
**Status:** Draft

## Purpose

This specification defines observability conventions for ClearHead tooling. It covers semantic events, structured logging, and debugging telemetry.

**Observability is for:**

- Debugging system behavior ("why is this action in this state?")
- Property change history ("when did priority change from 2 to 1?")
- Operational analytics (completion velocity, patterns over time)
- Distributed tracing (sync operations, cross-device coordination)

**Observability is NOT for:**

- Current state (that's the domain data)
- Action instances (that's `.recurring.actions` files)
- Sync coordination (that's git)

## Relationship to Other Concerns

```
Git                       → Sync, version history, conflict resolution
Domain Model              → Current semantic state (charters, actions, plans)
DSL Files (.actions, .md) → Human-readable projections, queryable
Observability (this)      → Debugging, analytics, audit trail
```

These are complementary. Git tracks *file-level* history. Observability tracks *semantic* history (what those file changes meant in domain terms).

## Framework

ClearHead uses [OpenTelemetry](https://opentelemetry.io/) for observability:

- **Standard format** — Wide ecosystem support (Jaeger, Prometheus, Grafana)
- **Structured logs** — Semantic events with typed fields
- **Offline-first** — Local file export, aggregate later

## Storage Location

Telemetry is stored in XDG state directory (machine-specific, not synced):

- **Linux/macOS:** `~/.local/state/clearhead/telemetry/` (or `$XDG_STATE_HOME/clearhead/telemetry/`)
- **Windows:** `%LOCALAPPDATA%\clearhead\state\telemetry\`

### File Format

Logs are stored as newline-delimited JSON (NDJSON) for easy parsing with DuckDB, jq, or standard tools:

```
telemetry/
├── events-2026-01.ndjson
├── events-2026-02.ndjson
└── ...
```

Files rotate monthly by default. Configurable via settings.

## Semantic Events

Events are domain-specific and use consistent field naming.

### Common Fields

All events include:

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | ISO 8601 | When the event occurred |
| `event` | string | Event type identifier |
| `tool` | string | Emitting tool (cli, lsp, sync) |
| `action_uuid` | string | Related action UUID (if applicable) |

### Action Lifecycle Events

| Event | When Emitted | Additional Fields |
|-------|--------------|-------------------|
| `action_created` | New plan added | `name`, `file_path` |
| `action_completed` | State → completed | `name`, `completed_at` |
| `action_cancelled` | State → cancelled | `name`, `reason` (optional) |
| `action_started` | State → in_progress | `name` |
| `action_blocked` | State → blocked | `name`, `reason` (optional) |
| `action_restarted` | State → new   | `name`, `reason` (optional) |
| `action_archived` | Action moved to archive | `name`, `archive_file` |
| `action_deleted` | Action removed from file | `name` |

### Property Change Events

| Event | When Emitted | Additional Fields |
|-------|--------------|-------------------|
| `priority_changed` | Priority modified | `old_priority`, `new_priority` |
| `due_date_changed` | Do date modified | `old_date`, `new_date` |
| `name_changed` | Name modified | `old_name`, `new_name` |
| `context_added` | Context tag added | `context` |
| `context_removed` | Context tag removed | `context` |

### Recurring Action Events

| Event | When Emitted | Additional Fields |
|-------|--------------|-------------------|
| `instance_generated` | New Action created | `template_uuid`, `occurrence_date` |
| `instance_completed` | Recurring instance completed | `template_uuid`, `scheduled_date`, `completed_date` |
| `instance_skipped` | User skips occurrence | `template_uuid`, `occurrence_date`, `reason` |
| `template_edited` | Recurring template modified | `template_uuid`, `fields_changed` |
| `template_archived` | Recurring template + instances archived | `template_uuid`, `instance_count`, `archive_file` |

### Sync Events

> Sync events are deferred to the future sync server implementation. Git is the current sync
> mechanism; file-level history is available via `git log`. These event types are reserved for
> when a distributed sync server is introduced.

### Semantic Patch / Projection Events

These events trace how a named semantic operation becomes a domain model change and how that change is projected to files. They are especially useful for debugging why a file ended up in a particular state.

| Event | When Emitted | Additional Fields |
|-------|--------------|-------------------|
| `patch_derived` | A semantic change set is produced by a named operation with resolved targets | `operation`, `patch_id`, `operation_count` |
| `patch_applied` | A semantic change set is applied to the domain model | `patch_id`, `applied_count`, `skipped_count`, `reason` (optional) |
| `projection_written` | A projected DSL file is written from domain model state | `file_path`, `bytes_written`, `reason` (e.g., on_save, manual_apply) |

**Correlation:** Implementations SHOULD correlate `patch_*` events using tracing identifiers (e.g., OpenTelemetry trace/span IDs) so operators can answer: "what operation was requested, what change set was derived, what was applied, what was projected".

### System Events

| Event | When Emitted | Additional Fields |
|-------|--------------|-------------------|
| `workspace_opened` | Workspace loaded | `path`, `action_count` |
| `file_parsed` | Actions file parsed | `file_path`, `action_count`, `parse_time_ms` |
| `lsp_started` | LSP server started | `port` (if applicable) |

## Retention

Default retention: 1 year. Older files can be:

- Deleted automatically (if configured)
- Archived to cold storage
- Aggregated into summary statistics

Telemetry settings can be aggregated via a sync server but that is not required and up to implementors and configuration

## See Also

- [Process](./process.md) — Workflow and action lifecycle
- [Configuration](./configuration.md) — Settings including telemetry options
