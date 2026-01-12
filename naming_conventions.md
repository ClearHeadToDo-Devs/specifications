# Naming Conventions for repositories

to one aspect that is orthogonal, but important to consider is the naming conventions and repo conventions when it comes to collections of action files.

In particular, we want to make it ergonomic to manage multiple "containers" whether you call them stories or projects, by leveraging the filesystem. 

while the [file specification](./action_specification.md) defines how individual action files are structured, this specification defines how those files should be organized and named within a workspace.

They are separate, because different implementors may choose to work with the format, but choose to avoid these conventions which is fine, this way implementors can absorb specifications a-la-carte and take on the complexity they want to consider

## Workspace Structure

All action files/folders should be organized into a directory that conforms with the standards of the given operating system or follows a project-local structure.

### Global Workspace
For global management, action files reside in standard system locations (e.g., `XDG_DATA_HOME/clearhead` on Linux).

### Project-Local Workspace
For project-specific management, a directory may be designated as a workspace by the presence of a `.clearhead/` directory or a `next.actions` file at its root.

#### The `.clearhead/` Directory
Similar to `.git/`, a `.clearhead/` directory at the project root signals that the project is managed by the ClearHead system.
- `.clearhead/inbox.actions` - Project-specific inbox.
- `.clearhead/config.json` - Project-specific configuration (overrides global).
- `.clearhead/logs/` - Project-specific completion logs.

#### The `next.actions` File
A `next.actions` file at the root of a directory is a "first-class" project entry point. It allows for lightweight task management without the overhead of a full `.clearhead/` folder.

## Discovery Protocol

Implementors (CLI, LSP, etc.) should resolve the active workspace and default action file using the following precedence:

1.  **Explicit File**: Path provided via command-line argument (e.g., `clearhead_cli read my_tasks.actions`).
2.  **Project Root File**: Search upwards from the current directory for a `next.actions` file.
3.  **Project Data Directory**: Search upwards from the current directory for a `.clearhead/` directory. If found, the default file is `.clearhead/inbox.actions`.
4.  **Global Workspace**: Fallback to the system-standard directory (e.g., `~/.local/share/clearhead_cli/inbox.actions`).

### Precedence Summary Table

| Input | Logic | Default File |
| :--- | :--- | :--- |
| `clearhead_cli read <file>` | Explicit | `<file>` |
| Current dir has `next.actions` | Local Root | `./next.actions` |
| Current dir has `.clearhead/` | Local Data | `./.clearhead/inbox.actions` |
| Parent dir has `next.actions` | Upward Root | `../next.actions` |
| None of the above | Global | `~/.local/share/clearhead_cli/inbox.actions` |

### Project/Story Naming

    While the action specification allows for stories/projects to be defined within the files themselves, it can often feel natural to break these files into separate files/folders for organization.

    To this end, we support the following conventions, with the assumption implementors will leverage these structures to provide better user experiences.
    - `$workspace/<project-name>.actions` - A file containing actions for a specific project/story
        - Any actions within this file are assumed to have the story/project of the file name unless otherwise specified within the action itself.
    - `$workspace/<project-name>/next.actions` - A directory containing a project/story with its own next actions file
        - This allows for sub-projects through the combination of directories and files.

#### Sub-Projects
    To support sub-projects, we allow for directories within the workspace to represent projects/stories, with their own action files.

    For example:
    ```
    $workspace/
    ├── ProjectA/
    │   ├── next.actions
    |   |-- subProjectB.actions
    │   └── SubProjectA/
    │       └── next.actions
    └── ProjectB.actions
    ```

    In this structure:
    - `ProjectA` is a project with its own `next.actions` file.
    - `SubProjectA1` is a sub-project of `ProjectA`, also with its own `next.actions` file.
    - `ProjectB.actions` is a standalone project file.
    - `subProjectB.actions` is a file within `ProjectA` that can contain actions specific to that sub-project.

In this way, users can grow their actions workspace organically, organizing projects and sub-projects in a way that makes sense for their workflow, leaving room for implementors to build tools that can navigate and manage these structures effectively.

##### Project READMEs
    To further enhance organization, each project/story directory can optionally contain a `README.md` file that provides context about the project/story.

    This file can include:
    - Project/Story description
    - Goals and objectives
    - Key milestones
    - Links to related resources

    This allows users to have a quick reference for each project/story directly within the workspace structure.

    Tool implementors can leverage these README files to provide additional context in their interfaces, enhancing the user experience.
# Action History and Completion Tracking

For tracking action completion history and analytics, the ClearHead platform uses **event sourcing** via a persistent event log database. This section explains how history is managed and how it affects file organization.

## Event Sourcing (Recommended)

**History is tracked in `events.db`, not in plaintext log files.**

The event logging system (see [Event Logging Specification](./event_logging_specification.md)) provides persistent tracking of action lifecycle events in a SQLite database. This enables time-series analytics, completion history, and audit trails without duplicating data in plaintext files.

### Workflow with Event Sourcing

**Active files contain current state only:**
```
workspace/
├── inbox.actions           # Current active actions
├── project-a.actions       # Project A active actions
└── .clearhead/
    └── (no logs/ directory needed)
```

**History lives in events database:**
```
~/.local/state/clearhead/
└── events.db              # Machine-wide event log (all projects)
```

**Note:** Events are stored in `XDG_STATE_HOME` (not `XDG_DATA_HOME`) because they are machine-specific state that shouldn't be git-tracked or synced across devices via file sync.

**Example workflow for recurring actions:**

1. **Template stays active in file:**
   ```actions
   [ ] Weekly standup @2026-01-14T09:00 R:FREQ=WEEKLY;BYDAY=TU #abc123
   ```

2. **Complete the action** (CLI, LSP, or UI):
   ```bash
   clearhead complete abc123
   ```

3. **Events emitted to events.db:**
   - `instance_completed` event logged with timestamp
   - `instance_due` event logged for next occurrence

4. **Template remains unchanged in file** (recurring actions never complete):
   ```actions
   [ ] Weekly standup @2026-01-14T09:00 R:FREQ=WEEKLY;BYDAY=TU #abc123
   ```

5. **Query history from events database:**
   ```bash
   # Show completion history for this action
   clearhead history abc123

   # Show all completions in January
   clearhead history --since 2026-01-01 --until 2026-02-01

   # Export history to plaintext if needed
   clearhead export --completed --since 2026-01-01 > january.actions
   ```

### File Cleanup Workflow

With event sourcing, **completed actions can be deleted from files to save space** - their history is preserved in events.db.

**One-time actions:**
```actions
# Before completion
[ ] Fix bug in login form !1 #xyz789

# After completion - DELETE from file (history in events.db)
# (action removed)
```

**Recurring actions:**
```actions
# Template stays in file (never deleted)
[ ] Weekly standup @2026-01-14T09:00 R:FREQ=WEEKLY;BYDAY=TU #abc123
```

**Cleanup commands:**
```bash
# Remove all completed non-recurring actions from file
clearhead clean inbox.actions

# Remove completed actions older than 30 days
clearhead clean --completed --older-than 30d inbox.actions
```

### Benefits of Event Sourcing

- ✅ **Single source of truth** - History exists in exactly one place (events.db)
- ✅ **Time-travel queries** - "How many actions were open on 2026-01-15?"
- ✅ **Cross-project analytics** - Query completion rates across all projects
- ✅ **No file duplication** - Completed actions don't need to be moved to log files
- ✅ **Simpler LSP** - No file move operations to track
- ✅ **Space efficient** - Delete completed actions from files, query history from DB
- ✅ **Export on demand** - Generate plaintext history when needed

### Querying History

**CLI commands for common queries:**

```bash
# Show completion history for specific action
clearhead history abc123

# Show all completions this week
clearhead history --since monday

# Show recurring action instance history
clearhead history --recurring abc123

# Completion rate over time
clearhead stats completion-rate --since 2026-01-01

# Actions open on specific date (time-travel)
clearhead stats open-on --date 2026-01-15

# Export to plaintext
clearhead export --completed --since 2026-01-01 --format actions > log.actions
```

**Direct SQL queries (advanced):**

```bash
# Open the events database directly
sqlite3 ~/.local/state/clearhead/events.db

# Query completion history
SELECT timestamp, event_type, metadata
FROM events
WHERE action_uuid = 'abc123'
ORDER BY timestamp;
```

## Plaintext Logs (Legacy/Optional)

**Note:** Plaintext log files are no longer recommended with event sourcing. However, implementations MAY still support them for backwards compatibility or user preference.

If using plaintext logs instead of event sourcing:

**File Organization:**
```
workspace/
├── inbox.actions           # Active actions
└── .clearhead/
    └── logs/
        ├── 2025-01.actions    # January completions
        └── 2025-02.actions    # February completions
```

**Log Entry Format:**
```actions
[x] Take out trash @2025-01-07T19:00 %2025-01-07T19:15 #trash-001-20250107
[x] Daily standup @2025-01-20T09:00 %2025-01-20T09:05 #standup-001-20250120
```

**Tradeoffs:**
- ✅ Human-readable plaintext history
- ✅ Can `cat` or `grep` log files directly
- ❌ Duplicates data (same info in files and events.db if both used)
- ❌ Requires file move operations (complexity for LSP)
- ❌ Limited querying (no time-series analytics without parsing all files)

## Migration from Plaintext Logs to Event Sourcing

If migrating from plaintext logs to event sourcing:

1. **Import existing log files into events.db:**
   ```bash
   clearhead import-logs .clearhead/logs/*.actions
   ```

2. **Verify import:**
   ```bash
   clearhead history --all | wc -l  # Should match log entry count
   ```

3. **Remove log files (optional):**
   ```bash
   rm -rf .clearhead/logs/
   ```

4. **Update workflow to delete completed actions instead of archiving**

## See Also

- [Event Logging Specification](./event_logging_specification.md) - Complete event sourcing details
- [Configuration Specification](./configuration_specification.md) - Configure events.db path
- [Action File Format](./action_specification.md) - Core file format

