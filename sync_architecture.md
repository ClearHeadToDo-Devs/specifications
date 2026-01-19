# Sync Architecture Specification

## Overview

This specification defines the CRDT-centered synchronization architecture for the ClearHead platform. The core principle is that **the CRDT document is the source of truth**, with DSL text files being projected views that can be edited via standard text editors.

**Key principles:**
- CRDT (Automerge) document is the authoritative state
- DSL files are projections, not the source of truth
- Sync operates on CRDTs, not files
- Editors use native file-change detection
- Conflict resolution leverages standard diff tooling
- One CRDT document per user workspace (global)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SYNC LAYER                                     │
│                                                                         │
│   ┌─────────┐         automerge-repo          ┌─────────┐              │
│   │ Device A│◄──────────protocol─────────────►│ Relay   │              │
│   │ (laptop)│                                 │ Server  │              │
│   └────┬────┘                                 │(always  │              │
│        │                                      │  on)    │              │
│        │                                      └────┬────┘              │
│   ┌────▼────┐                                      │                   │
│   │ Device B│◄─────────────────────────────────────┘                   │
│   │ (phone) │                                                          │
│   └─────────┘                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                          LOCAL DEVICE                                   │
│                                                                         │
│   ~/.local/state/clearhead/                                            │
│   ├── workspace.crdt      ◄── source of truth (plans + processes)      │
│   └── oxigraph/           ◄── query cache (ephemeral, rebuildable)     │
│                                                                         │
│   /tmp/clearhead-shadow/  ◄── ephemeral shadow files for 3-way merge   │
│                                                                         │
│   ~/.local/share/clearhead/                                            │
│   ├── inbox.actions       ◄── projected plans (what editor sees)       │
│   └── inbox.log.actions   ◄── projected processes (on-demand review)   │
│                                                                         │
│   ┌──────────────┐     ┌──────────────┐     ┌──────────────┐           │
│   │  clearhead   │     │     LSP      │     │    Editor    │           │
│   │     sync     │     │   Server     │     │  (neovim)    │           │
│   └──────┬───────┘     └──────┬───────┘     └──────┬───────┘           │
│          │                    │                    │                   │
│          │ writes files       │ on-save: parse     │ native file       │
│          │ when CRDT changes  │ diff, update CRDT  │ change detection  │
│          │ updates Oxigraph   │ materialize to     │                   │
│          │                    │ Oxigraph           │                   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Storage Locations

Base XDG paths are defined in [Configuration Specification](./configuration.md). This section covers sync-specific storage details.

**Sync-relevant locations:**

| Location | Sync Role |
|----------|-----------|
| `$XDG_STATE_HOME/clearhead/workspace.crdt` | CRDT source of truth |
| `$XDG_DATA_HOME/clearhead/*.actions` | Projected DSL files |
| `/tmp/clearhead-shadow/` | Ephemeral shadow files for 3-way merge |

### State Directory Structure

```
~/.local/state/clearhead/
├── workspace.crdt          # Automerge document (binary) - global workspace
└── events.db               # SQLite event log (see event_logging_specification.md)
```

**Why STATE_HOME for CRDT:**
- Machine-specific runtime state
- Should not be synced via file-sync tools (Dropbox, etc.)
- CRDT sync handles cross-device synchronization
- Separates "truth" (CRDT) from "view" (DSL files)

### Data Directory Structure

```
~/.local/share/clearhead/
├── inbox.actions           # Default inbox (projected from CRDT)
├── work.actions            # Additional action file (projected from CRDT)
└── personal/
    └── goals.actions       # Organized in subdirectories (projected from CRDT)
```

These files are **projections** - they can be regenerated from the CRDT at any time.

## Data Flow

### Flow 1: Local Edit (No Sync)

```
User edits inbox.actions in editor
         │
         ▼
    [User saves file]
         │
         ▼
LSP Server receives textDocument/didSave
         │
         ▼
LSP parses file → builds AST → converts to struct
         │
         ▼
LSP loads workspace.crdt, diffs current state vs struct
         │
         ▼
LSP applies changes to CRDT document
         │
         ▼
LSP saves workspace.crdt
         │
         ▼
(Optional) LSP re-projects file (usually no-op if edit was clean)
         │
         ▼
Done - CRDT is updated, file unchanged
```

### Flow 2: Remote Sync (Editor Idle)

```
clearhead sync receives CRDT changes from remote
         │
         ▼
Merges into local workspace.crdt (automerge handles conflicts)
         │
         ▼
Copies current inbox.actions → /tmp/clearhead-shadow/inbox.actions.base
         │
         ▼
Projects new CRDT state → inbox.actions
         │
         ▼
Editor detects file change (autoread, FileChangedShell, etc.)
         │
         ▼
Editor reloads file automatically
         │
         ▼
Done - user sees updated content
```

### Flow 3: Remote Sync (Editor Has Unsaved Changes)

```
clearhead sync receives CRDT changes from remote
         │
         ▼
Merges into local workspace.crdt
         │
         ▼
Copies current inbox.actions → /tmp/clearhead-shadow/inbox.actions.base
         │
         ▼
Projects new CRDT state → inbox.actions
         │
         ▼
Editor detects file change, but buffer is dirty
         │
         ▼
Editor prompts: "File changed on disk. [r]eload [k]eep [m]erge"
         │
         ├─► [r]eload: discard buffer, load new file
         │
         ├─► [k]eep: keep buffer, overwrite file on next save
         │
         └─► [m]erge: launch 3-way diff (see Conflict Resolution)
```

## Sync Protocol

### Transport

Uses **automerge-repo** built-in sync protocol over WebSocket.

**Rationale:**
- Battle-tested sync semantics
- Handles partial sync, reconnection
- No need to reinvent CRDT synchronization

### Topology

Peer-to-peer with optional relay server:

```
┌──────────┐                    ┌──────────┐
│ Device A │◄──── direct ──────►│ Device B │
│ (laptop) │     (LAN/mesh)     │ (desktop)│
└────┬─────┘                    └────┬─────┘
     │                               │
     │    ┌──────────────────┐       │
     └───►│   Relay Server   │◄──────┘
          │  (always-on hub) │
          └──────────────────┘
                  ▲
                  │
          ┌───────┴───────┐
          │   Device C    │
          │   (phone)     │
          └───────────────┘
```

**Relay Server:**
- Simple always-on node that participates in the mesh
- Acts as bridge when devices can't connect directly (NAT, firewalls)
- Does NOT have special authority - just another peer
- Can run as systemd service on a home server or VPS

### Sync Server (`clearhead-sync`)

This is not implementation specific but should:

run in two modes:

**On-demand:**
```bash
# Manual sync
clearhead sync once

# Sync and watch for changes
clearhead sync watch --interval 30s
```

**Daemon (systemd):**
```ini
# ~/.config/systemd/user/clearhead-sync.service
[Unit]
Description=ClearHead Sync Service

[Service]
ExecStart=/usr/bin/clearhead-sync daemon
Restart=on-failure

[Install]
WantedBy=default.target
```

### Configuration

Sync is configured via `sync_*` settings in `config.json`. See [Configuration Specification - Sync Settings](./configuration.md#sync-settings-sync_) for all options including `sync_enabled`, `sync_relay_url`, `sync_peers`, and `sync_interval_seconds`.

## Conflict Resolution

### Philosophy

**Keep it simple.** Don't build custom merge UI. Leverage existing diff tools that users already know.

### Three-Way Merge

When buffer and file diverge significantly, we have three versions:

| Version | Location | Description |
|---------|----------|-------------|
| **Base** | `/tmp/clearhead-shadow/inbox.actions.base` | Last common state before divergence |
| **Theirs** | `inbox.actions` | New projection from CRDT (remote changes) |
| **Ours** | Editor buffer | User's unsaved local changes |

Shadow files are ephemeral - they live in `/tmp` and are overwritten on each sync. The OS handles cleanup; we don't need to manage their lifecycle.

### Using Standard Tools

**Vim/Neovim native:**
```bash
vimdiff \
  /tmp/clearhead-shadow/inbox.actions.base \
  ~/.local/share/clearhead/inbox.actions \
  /tmp/clearhead-buffer.actions
```

**From within Neovim:**
```vim
:diffsplit /tmp/clearhead-shadow/inbox.actions.base
```

**GUI tools:**
```bash
meld base.actions theirs.actions ours.actions
kdiff3 base.actions theirs.actions ours.actions -o merged.actions
```

### Editor Integration (Optional)

The Neovim plugin MAY offer a convenience command:

```vim
:ClearheadMerge
```

Which would:
1. Save buffer to temp file
2. Launch configured merge tool with base/theirs/ours
3. Load result back into buffer

But the default flow is simply editor's native "file changed" handling.

## CRDT Schema

The CRDT document structure mirrors the DSL structure (lossless bidirectional):

```
workspace.crdt
├── actions: Map<UUID, Action>
│   ├── {uuid}
│   │   ├── title: String
│   │   ├── status: "open" | "completed" | "cancelled"
│   │   ├── priority: Option<1-4>
│   │   ├── due: Option<DateTime>
│   │   ├── completed_at: Option<DateTime>
│   │   ├── recurrence: Option<RRule>
│   │   ├── tags: List<String>
│   │   ├── context: Option<String>
│   │   ├── project: Option<String>
│   │   ├── children: List<UUID>
│   │   └── notes: Option<String>
│   └── ...
├── projects: Map<String, Project>
│   └── ...
└── metadata
    ├── version: u32
    └── last_modified: DateTime
```

**Key constraint:** Valid CRDT ↔ Valid DSL. No information loss in either direction.

### Autosurgeon Derivation

Using `autosurgeon` crate for Rust struct ↔ Automerge mapping:

```rust
use autosurgeon::{Hydrate, Reconcile};

#[derive(Hydrate, Reconcile)]
struct Action {
    title: String,
    status: Status,
    priority: Option<u8>,
    due: Option<DateTime>,
    // ...
}
```

## Projection

### CRDT → DSL File

When the CRDT changes (from sync or local edit), project to DSL:

```rust
fn project_to_file(crdt: &AutoCommit, file_path: &Path) -> Result<()> {
    // 1. Copy current file to shadow (for 3-way merge if needed)
    let shadow_path = Path::new("/tmp/clearhead-shadow")
        .join(file_path.file_name().unwrap())
        .with_extension("actions.base");
    fs::create_dir_all(shadow_path.parent().unwrap())?;
    fs::copy(file_path, shadow_path)?;

    // 2. Hydrate CRDT to struct (nearly zero-cost via autosurgeon)
    let workspace: Workspace = hydrate(crdt)?;

    // 3. Format struct to DSL text
    let text = formatter::format(&workspace)?;

    // 4. Write to file
    fs::write(file_path, text)?;

    Ok(())
}
```

### DSL File → CRDT

When user saves file in editor, LSP updates CRDT:

```rust
fn update_from_file(file_path: &Path, crdt: &mut AutoCommit) -> Result<()> {
    // 1. Parse file to AST
    let text = fs::read_to_string(file_path)?;
    let ast = parser::parse(&text)?;

    // 2. Convert AST to struct
    let new_state: Workspace = ast.into();

    // 3. Reconcile changes into CRDT
    reconcile(crdt, &new_state)?;

    // 4. Save CRDT
    save_crdt(crdt)?;

    Ok(())
}
```

## Component Responsibilities

### clearhead-sync

- Load/save CRDT from global workspace location
- Connect to relay server and peers
- Sync CRDT changes via automerge-repo protocol
- Project CRDT to DSL files when changes received (shadow copy to /tmp happens automatically)

### LSP Server

- Parse DSL files on save
- Update CRDT with file changes
- Provide diagnostics (linter errors/warnings)
- Format on save
- Does NOT handle sync - that's clearhead-sync's job

### Editor (Neovim)

- Edit DSL files
- Detect file changes (autoread, FileChangedShell)
- Prompt user on conflict
- Launch diff tools for merge
- Call LSP for diagnostics and formatting

### Relay Server

- Always-on peer in the mesh
- Bridges devices that can't connect directly
- No special authority or logic
- Just runs clearhead-sync in daemon mode

## Recurrence Handling

See [DECISIONS.md](../DECISIONS.md) Decision 5.

Recurring actions only track upcoming instances (configurable, default ~3 months). The CRDT stores the template; `events.db` tracks instance completions.

```
CRDT: [ ] Weekly standup @2026-01-14 R:FREQ=WEEKLY #abc123
                    │
                    ▼
events.db: instance_completed(abc123, 2026-01-07)
           instance_completed(abc123, 2026-01-14)
           instance_due(abc123, 2026-01-21)
```

## Future Considerations

### Performance Optimization

If CRDT grows large:
- Split into multiple documents (per-project)
- Lazy loading of historical data
- Compaction of old CRDT history

### End-to-End Encryption

For sensitive data:
- Encrypt CRDT before sync
- Key exchange between devices
- Relay server sees only encrypted blobs

### Mobile/Web Clients

Same architecture applies:
- Load CRDT, present UI
- User edits update CRDT
- Sync propagates changes
- No DSL file projection needed (UI is the view)

## See Also

- [event_logging_specification.md](./event_logging_specification.md) - Events database
- [configuration.md](./configuration.md) - Config file format
- [naming_conventions.md](./naming_conventions.md) - Workspace structure
