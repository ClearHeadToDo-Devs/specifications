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

## Conceptual Model

The **Intermediate Representation (IR)** is the canonical in-memory form. Everything else is a serialization or projection. The IR aligns with the [Actions Ontology](https://clearhead.us/vocab/actions/v4) 

```
                              IR
                    (canonical in-memory form)
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
            ▼                  ▼                  ▼
          CRDT               DSL           Graph Query Layer
      (durable with      (text view        (RDF/SPARQL
       sync/merge)       for editors)       query cache))
```

- **CRDT** is durable storage with merge semantics. Stores both ActionPlans and ActionProcesses. This is the synced source of truth.
- **DSL** is text serialization for editor workflows. Plans: `*.actions`, Processes: `*.log.actions` (on-demand).
- **Graph Query Layer** is an ephemeral RDF graph store materialized from the IR. Enables SPARQL queries for complex analytics and validation. This allows implementations to leverage semantic reasoning, SHACL shapes, and RDF-based linting.

**Key constraint:** Valid CRDT ↔ Valid IR ↔ Valid DSL. No information loss in any direction for plans.

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
│   └── graph-store/         ◄── Graph query layer (ephemeral, rebuildable)      │
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
├── workspace.crdt          # CRDT document (binary) - global workspace
│                           # Contains both ActionPlans and ActionProcesses
└── graph-store/            # Graph query layer (ephemeral, rebuildable from CRDT)
                            # SPARQL-capable RDF store for analytics and validation
```

**Why STATE_HOME for CRDT:**
- Machine-specific runtime state
- Should not be synced via file-sync tools (Dropbox, etc.)
- CRDT sync handles cross-device synchronization
- Separates "truth" (CRDT) from "view" (DSL files)

### Data Directory Structure

```
~/.local/share/clearhead/
├── inbox.actions           # ActionPlans - default inbox (projected from CRDT)
├── inbox.log.actions       # ActionProcesses - completion history (on-demand projection)
├── work.actions            # Additional action file (projected from CRDT)
└── personal/
    └── goals.actions       # Organized in subdirectories (projected from CRDT)
```

These files are **projections** - they can be regenerated from the CRDT at any time.

**Note on process logs:** The `*.log.actions` files are generated on-demand for human review. They are not the authoritative source - processes live in the CRDT alongside plans. See [ActionProcess Specification](./action_process_specification.md) for semantics.

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

Sync is configured via `sync_*` settings in `config.json`. 

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


## Projection

### CRDT → DSL File

When the CRDT changes (from sync or local edit), project to DSL:

1. Copy current file to shadow location (for 3-way merge if needed)
2. Load CRDT and convert to IR
3. Filter IR to ActionPlans belonging to this file (by project/inbox assignment)
4. Format IR to DSL text
5. Write to file

### DSL File → CRDT

When user saves file in editor:

1. Parse DSL file to AST
2. Convert AST to IR (ActionPlans)
3. Diff against current CRDT state
4. Apply changes to CRDT
5. Save CRDT
6. Materialize changes to graph store (for queries)

### IR → Graph Query Layer

When CRDT changes (local or sync), materialize to graph query layer:

1. Load changed ActionPlans and ActionProcesses from CRDT
2. Convert to RDF representation using Actions Ontology
3. Update graph store
4. Graph store is now queryable via SPARQL

**Key benefits of graph query layer:**
- **Complex queries:** SPARQL enables powerful graph queries over action data
- **Reasoning:** Can leverage SHACL shapes and ontology reasoning for linting
- **Integration:** RDF entities are first-class citizens for system integration
- **Performance:** Efficient query cache built on top of CRDT

**Note:** Graph store can be fully rebuilt from CRDT at any time. It is a query cache, not authoritative.

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

See [DECISIONS.md](https://github.com/ClearHeadToDo-Devs/platform/blob/main/DECISIONS.md) Decision 5.

Recurring actions use the ActionPlan/ActionProcess model:
- **ActionPlan** stores the recurrence rule (RFC 5545 RRule)
- **ActionProcess** records are created for each completed instance

```
CRDT plans:     [ ] Weekly standup @2026-01-14 R:FREQ=WEEKLY #abc123
                              │
                              │ prescribed_by
                              ▼
CRDT processes: ActionProcess(prescribed_by=abc123, completed_at=2026-01-07)
                ActionProcess(prescribed_by=abc123, completed_at=2026-01-14)
                ActionProcess(prescribed_by=abc123, scheduled_for=2026-01-21) [pending]
```

The ActionPlan remains `active` as long as the recurrence continues. Each completion creates a new ActionProcess linked back to the plan.

**Querying recurrence history:** Use SPARQL queries on graph store to query all processes where `prescribed_by` = plan UUID, ordered by `completed_at`.

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

- [Actions Ontology](https://clearhead.us/vocab/actions/v3) - ActionPlan/ActionProcess semantics from BFO/CCO
- [ActionProcess Specification](./action_process_specification.md) - Process state semantics
- [configuration.md](./configuration.md) - Config file format
- [naming_conventions.md](./naming_conventions.md) - Workspace structure
- [DECISIONS.md - Oxigraph](https://github.com/ClearHeadToDo-Devs/platform/blob/main/DECISIONS.md#oxigraph-as-query-layer-and-cache) - Graph store decision
