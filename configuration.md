# ClearHead Configuration Specification

## Overview

This specification defines how ClearHead implementations handle configuration, including directory structure, file format, configuration layering, and extension mechanisms.

**Key principles:**

- XDG Base Directory compliance for portability
- JSON format for universal compatibility
- Layered configuration for flexibility
- Shared core settings with implementation-specific extensions

## Directory Structure

### On Scoping

The platform supports user-level data as well as project-specific data.

please see [Workspace](./workspace.md) for details on how to name project-specific files and directories. but for the configuration, we want to allow users to avoid this entire process with the `default_to_user_scope` setting that will bypass this searching algorithm entirely and ONLY show the domain model for the user scope.

#### Additional workspaces

If users want to have multiple repos pulled into the same domain model, they can update the `additional_workspaces` setting with a list of entries pointing to directories that follow the standard `.clearhead` workspace layout. Each workspace retains its own named graph in the RDF store so charters and actions can be attributed to their source when displaying multi-workspace results.

Entries support three formats, all through the same interface:

| Format | Example | Use case |
|--------|---------|----------|
| Relative path | `"../sibling-project"` | Sub-projects or sibling repos on the same machine |
| Absolute path | `"~/work/other-project"` | Workspaces elsewhere on the filesystem; `~` and environment variables are expanded |
| URL *(planned)* | `"https://example.com/team-workspace"` | Remote workspaces; not yet implemented |

Relative paths are resolved from the directory containing `config.json`. Shell expansion (`~`, `$HOME`, `$VAR`) applies to all path-based entries.

### XDG Base Directory Compliance

All implementations MUST follow the XDG Base Directory specification:

| Directory Type | Location | Default |
|---------------|----------|---------|
| Config | `$XDG_CONFIG_HOME/clearhead` | `~/.config/clearhead` |
| Data | `$XDG_DATA_HOME/clearhead` | `~/.local/share/clearhead` |
| State | `$XDG_STATE_HOME/clearhead` | `~/.local/state/clearhead` |
| Cache (optional) | `$XDG_CACHE_HOME/clearhead` | `~/.cache/clearhead` |

### Default File Structure

```
~/.config/clearhead/
  └── config.json          # Primary configuration file

~/.local/share/clearhead/charters/
  └── inbox.actions        # Default action file 
  |-- README.md             # Default Charter
```

#### On Project-Specific Config

Within the example of a specific project, these subdirectories all reside within the .clearhead directory:

```project_root/
  └── .clearhead/
      ├── workspace.json     # Workspace manifest: identity facts, committed (see below)
      ├── config.json        # Project configuration, committed and shared (optional)
      ├── config.local.json  # Personal override, git-ignored (optional)
      ├── .gitignore         # Ignores config.local.json (written by `clearhead init`)
      charters/
          |-- README.md         # Project Root Charter
          ├── next.actions      # Project-specific action file (optional)
          |__ other files...        # Any other project-specific files


```

`config.json` is committed so the whole team shares workspace *behavior* (`additional_workspaces`, `tag_hierarchies`, `plan_path`, …). `config.local.json` sits beside it as a git-ignored personal override: a single developer can set their own values (e.g. their own `plan_path`) without touching the shared file. The local file wins over the committed one. `clearhead init` writes a scoped `.clearhead/.gitignore` so the personal override stays out of version control.

Workspace *identity* — `workspace_id`, `workspace_name`, `created_at` — does **not** live in `config.json`. It lives in a separate `.clearhead/workspace.json` **manifest**. The two are split because they behave differently: `config.json` is human-authored behavior that layers through the precedence chain below, while the manifest is a tool-managed fact about one workspace that must not layer (a `workspace_id` in a *global* config, or a `CLEARHEAD_WORKSPACE_ID` env override, is meaningless). The manifest is committed and near-static — it changes on `init` and rename, essentially never otherwise — and holds workspace-level facts only; per-charter metadata stays in its co-located sidecar. See [Workspace Identity](./workspace.md#workspace-identity) and the [manifest schema](./schemas/workspace.schema.json).

## Configuration File Format

### Format Choice

Configuration MUST be stored in a Format that supports conversion to-and-from JSON format at `$XDG_CONFIG_HOME/clearhead/config.json`.

**Rationale for JSON:**

- Universal support across all languages and platforms
- Native support in most editors
- Simple, well-understood format

### Configuration Structure

The configuration file uses a flat structure with implementation-specific namespacing:

1. **Core settings** - Shared across all implementations (no prefix)
2. **Implementation settings** - Prefixed with implementation name (e.g., `cli_*`, `nvim_*`)

**Core configuration example:**

```json
{
  "data_dir": "~/.local/share/clearhead",
  "config_dir": "~/.config/clearhead",
  "default_file": "inbox.actions"
}
```

**With implementation-specific settings:**

```json
{
  "data_dir": "~/.local/share/clearhead",
  "default_file": "inbox.actions",

  "cli_format": "table",
  "cli_indent_style": "spaces",
  "cli_indent_width": 4,

  "nvim_auto_normalize": true,
  "nvim_format_on_save": true,
  "nvim_lsp_enable": true
}
```

## Core Settings

All implementations MUST recognize these core settings:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `data_dir` | string | `~/.local/share/clearhead` | Global directory for user data and action files |
| `config_dir` | string | `~/.config/clearhead` | Global directory for configuration files |
| `state_dir` | string | `~/.local/state/clearhead` | Directory for machine-specific runtime state and event logs |
| `default_file` | string | `inbox.actions` | Default action file name (relative to data_dir) |
| `tag_hierarchies` | object | `{}` | Tag parent-child relationships for implicit inheritance |
| `default_to_user_scope` | boolean | `false` | If true, only shows user-scoped actions (ignores project scope) |
| `additional_workspaces` | array | `[]` | Additional workspaces to merge into the domain model. Entries may be relative paths, absolute paths (with `~` / env-var expansion), or URLs (planned). See [Additional workspaces](#additional-workspaces). |
| `plan_path` | string | *(unset → `<data_root>/plans`)* | Configured iCalendar vdir at `<plan_path>/<charter>/<resource>.ics`. ClearHead assumes only the filesystem boundary; any CalDAV/file-sync transport is external. |
| `plan_component` | string | `vevent` | iCalendar component used to encode Plans: `vevent` for ordinary calendar scheduling or `vtodo` for task-oriented calendar clients. This changes the integration surface, not Plan or Action domain semantics. |
| `expansion_total_instances` | integer | `2` | Bounded number of recurring Plan occurrences exposed by planning projections. Materialized current instances and read-only future projections may apply different view policies. |

**Requirements:**

- Core settings MUST support shell expansion (`~`, `$HOME`, environment variables)
- Relative paths in `default_file` MUST be resolved from `data_dir`
- Absolute paths MUST be used as-is

## Workspace Resolution

Which workspace an invocation operates on is resolved by most-local context first, independent of configuration precedence below:

1. **Project workspace** — walk up from the working directory to the first ancestor containing a `.clearhead/` directory ([Workspace](./workspace.md)).
2. **Configured user workspace** — the `data_dir` setting, when set.
3. **Default user workspace** — `$XDG_DATA_HOME/clearhead`.

`data_dir` relocates the *fallback* user workspace only; it MUST NOT override a detected project workspace. Bypassing project detection is an explicit choice via `default_to_user_scope`, never a side effect of other settings.

## Configuration Precedence

Implementations MUST follow this precedence order (highest to lowest):

1. **Command-line arguments** - Highest priority (CLI tools only)
2. **Environment variables** - `CLEARHEAD_*` prefix
3. **Project-local configuration** - `<project-root>/.clearhead/config.local.json` (git-ignored, personal)
4. **Project configuration** - `<project-root>/.clearhead/config.json` (committed, shared)
5. **Global configuration** - `$XDG_CONFIG_HOME/clearhead/config.json`
6. **Built-in defaults** - Hardcoded in the application

The two project layers let a committed `config.json` carry the shared workspace settings while each developer keeps personal overrides in a git-ignored `config.local.json` beside it — the local file wins. Both are optional and only apply when the invocation resolves to a project workspace.

### Layering Example

```
Built-in default:    cli_format = "actions"
Global config:       cli_format = "json"
Environment:         CLEARHEAD_CLI_FORMAT=xml
CLI flag:            --format compact

Result: compact (CLI flag wins)
```

## Environment Variables

### Naming Convention

Environment variables MUST use the `CLEARHEAD_` prefix followed by setting names in uppercase with underscores.

**Core settings:**

```bash
CLEARHEAD_DATA_DIR=/custom/path
CLEARHEAD_CONFIG_DIR=/custom/config
CLEARHEAD_DEFAULT_FILE=work.actions
```

**Implementation-specific settings** use the same prefix pattern with implementation namespace:

```bash
# CLI settings (maps to cli_* in JSON)
CLEARHEAD_CLI_FORMAT=json
CLEARHEAD_CLI_INDENT_STYLE=tabs
CLEARHEAD_CLI_INDENT_WIDTH=2

# Neovim settings (maps to nvim_* in JSON)
CLEARHEAD_NVIM_AUTO_NORMALIZE=false
CLEARHEAD_NVIM_FORMAT_ON_SAVE=true
CLEARHEAD_NVIM_LSP_ENABLE=true
```

### Value Parsing

Implementations MUST parse environment variable values as follows:

- `"true"` / `"false"` → boolean
- Numeric strings → numbers
- JSON arrays (e.g., `'["a", "b"]'`) → arrays
- All other values → strings
- Empty values are treated as not set (fall through to next precedence level)

## Implementation-Specific Settings

### Extension Mechanism

Implementations MAY add their own settings to the configuration file using a namespaced prefix (typically the tool name in lowercase followed by an underscore).

**Example for multiple implementations:**

```json
{
  "data_dir": "~/.local/share/clearhead",
  "default_file": "inbox.actions",

  "cli_format": "table",
  "cli_indent_style": "spaces",
  "cli_indent_width": 4,

  "nvim_auto_normalize": true,
  "nvim_format_on_save": true,
  "nvim_lsp_enable": true,

  "sync_enabled": true,
  "sync_relay_url": "wss://sync.example.com",
  "sync_interval_seconds": 30,

  "web_port": 8080,
  "web_auto_sync": true,
  "web_theme": "dark"
}
```

**Requirements:**

- Implementations MUST prefix their settings with a unique namespace (e.g., `cli_`, `nvim_`, `sync_`, `web_`)
- Implementations MUST ignore settings from other namespaces
- Implementations SHOULD NOT depend on settings from other namespaces
- Namespace prefixes MUST be unique identifiers (no conflicts)
- Core settings (no prefix) MUST be respected by all implementations

### Tag Hierarchies (`tag_hierarchies`)

Tag hierarchies define parent-child relationships between context tags. When an action is tagged with a child tag, it implicitly inherits all ancestor tags.

**Structure:**

```json
{
  "tag_hierarchies": {
    "parent_tag": ["child_tag_1", "child_tag_2"],
    "another_parent": ["child_tag_3"]
  }
}
```

Each key is a parent tag, and its value is an array of child tags that should inherit from it.

**Example:**

```json
{
  "tag_hierarchies": {
    "computer": ["terminal", "browser", "ide"],
    "terminal": ["neovim", "tmux", "shell"],
    "driving": ["grocery_store", "gas_station", "pharmacy"],
    "work": {"project_a": ["design", "development", "testing"]},
    "low_energy": ["email", "reading", "filing"]
  }
}
```

**Semantics:**

- **Transitive inheritance**: If `terminal` is a child of `computer`, and `neovim` is a child of `terminal`, then `+neovim` implicitly includes both `+terminal` and `+computer`.
- **Query expansion**: Searching for `+computer` will match actions tagged with `+neovim`, `+terminal`, `+browser`, etc.
- **Linting**: Actions tagged with both a child and its ancestor receive an info-level warning (I013) about redundancy.
- **Case-insensitive**: Tag matching is case-insensitive.

**Use cases:**

- GTD contexts: `@errands` → `@grocery`, `@pharmacy`, `@bank`
- Energy levels: `@low_energy` → `@email`, `@reading`
- Tools: `@computer` → `@terminal` → `@neovim`
- Locations: `@office` → `@desk`, `@meeting_room`

### Schema Extension

Implementations SHOULD provide their own JSON schema that extends the core schema:

**Core schema** (`config.schema.json` in this spec repository):

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "data_dir": { "type": "string" },
    "config_dir": { "type": "string" },
    "default_file": { "type": "string" }
  },
  "additionalProperties": true
}
```

**CLI extension** (in clearhead-cli repository):

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "allOf": [
    { "$ref": "https://raw.githubusercontent.com/.../config.schema.json" }
  ],
  "properties": {
    "cli_format": { "type": "string", "enum": ["actions", "json", "xml", "table"] },
    "cli_indent_style": { "type": "string", "enum": ["spaces", "tabs"] },
    "cli_indent_width": { "type": "integer", "minimum": 1, "maximum": 8 }
  }
}
```

This allows:

- Validation tools to check configuration correctness
- Editors to provide autocomplete and documentation
- Forward compatibility as new implementations are added

## Implementation Guidelines

### Path Resolution

Implementations MUST handle paths as follows:

1. **Absolute paths** (starting with `/` or `~/`): Use as-is after shell expansion
2. **Relative paths**: Resolve from `data_dir`
3. **Shell expansion**: Support `~`, `$HOME`, and other environment variables
4. **Platform normalization**: Handle path separators appropriately

**Example:**

```json
{
  "data_dir": "~/Documents/clearhead",
  "default_file": "inbox.actions"
}
```

Resolves to: `~/Documents/clearhead/inbox.actions`

### Error Handling

Implementations SHOULD:

- **Missing config**: Gracefully degrade to defaults (don't error)
- **Invalid JSON**: Provide clear error with line number
- **Unknown fields**: Warn but don't fail (forward compatibility)
- **Missing directories**: Create automatically with appropriate permissions
- **Invalid values**: Use defaults and warn

**Example error message:**

```
Warning: Invalid JSON in ~/.config/clearhead/config.json:12
  Unexpected token '}' at line 12, column 3

Falling back to default configuration.
```

### Performance

Implementations SHOULD:

- Cache resolved configuration in memory
- Re-read only when file modification time changes
- Avoid file I/O on every operation
- Validate configuration once at startup

### Directory Initialization

On first run, implementations SHOULD:

1. Create config directory if missing
2. Create data directory if missing
3. Optionally create example `config.json` with commented defaults
4. Create `inbox.actions` if it doesn't exist

## Examples

### Minimal Configuration

The simplest valid configuration overrides just one setting:

```json
{
  "default_file": "work.actions"
}
```

All other settings use defaults.

### Full Configuration

```json
{
  "data_dir": "~/Dropbox/clearhead",
  "config_dir": "~/.config/clearhead",
  "state_dir": "~/.local/state/clearhead",
  "default_file": "inbox.actions",
}
```

### Environment Variable Overrides

Environment variables can override configuration file settings:

```bash
# Use different data directory for this session
export CLEARHEAD_DATA_DIR="~/work-projects/clearhead"

# Override CLI format preference
export CLEARHEAD_CLI_FORMAT="json"

# Disable format-on-save in Neovim
export CLEARHEAD_NVIM_FORMAT_ON_SAVE="false"

# Run commands - they'll use overridden values
clearhead_cli read
nvim inbox.actions
```

## Conformance

An implementation is conformant with this specification if it:

1. Follows XDG Base Directory specification for config, data, and state locations
2. Reads configuration from `config.json` in JSON format
3. Respects all core settings (`data_dir`, `config_dir`, `state_dir`, `default_file`)
4. Implements configuration precedence correctly (defaults → global config → project config → project.local config → env → args)
5. Uses `CLEARHEAD_*` prefix for environment variables
6. Handles missing/invalid configuration gracefully with defaults
7. Supports shell expansion in path values
8. Uses namespaced prefixes for implementation-specific settings (e.g., `cli_`, `nvim_`, `sync_`)
9. care should be taken to avoid conflicts remember this is a global namespace

## See Also

- [Action File Format](./action_file_format.md) - Core file format
- [Workspace](./workspace.md) - File and directory naming

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for version history and updates to this specification.
