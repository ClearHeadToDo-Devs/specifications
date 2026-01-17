# ClearHead Configuration Specification

## Overview

This specification defines how ClearHead implementations handle configuration, including directory structure, file format, configuration layering, and extension mechanisms.

**Key principles:**
- XDG Base Directory compliance for portability
- JSON format for universal compatibility
- Layered configuration for flexibility
- Shared core settings with implementation-specific extensions

## Directory Structure

### XDG Base Directory Compliance

All implementations MUST follow the XDG Base Directory specification:

| Directory Type | Location | Default |
|---------------|----------|---------|
| Config | `$XDG_CONFIG_HOME/clearhead` | `~/.config/clearhead` |
| Data | `$XDG_DATA_HOME/clearhead` | `~/.local/share/clearhead` |
| State | `$XDG_STATE_HOME/clearhead` | `~/.local/state/clearhead` |
| Cache (optional) | `$XDG_CACHE_HOME/clearhead` | `~/.cache/clearhead` |

**Note:** State directory contains machine-specific runtime state (CRDT documents, events.db) that should NOT be synced via file-sync tools like Dropbox. See [Sync Architecture](./sync_architecture.md) for details.

### Default File Structure

```
~/.config/clearhead/
  └── config.json          # Primary configuration file

~/.local/share/clearhead/
  └── inbox.actions        # Default action file (projected from CRDT)

~/.local/state/clearhead/
  ├── workspace.crdt       # CRDT document (source of truth)
  └── events.db            # Event log for analytics/history
```

## Configuration File Format

### Format Choice

Configuration MUST be stored in JSON format at `$XDG_CONFIG_HOME/clearhead/config.json`.

**Rationale for JSON:**
- Universal support across all languages and platforms
- Native support in Neovim and most editors
- Simple, well-understood format
- Easy programmatic manipulation
- No additional parsing libraries required

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
| `state_dir` | string | `~/.local/state/clearhead` | Directory for machine-specific state (CRDT, events.db) |
| `default_file` | string | `inbox.actions` | Default action file name (relative to data_dir) |

**Requirements:**
- Core settings MUST support shell expansion (`~`, `$HOME`, environment variables)
- Relative paths in `default_file` MUST be resolved from `data_dir`
- Absolute paths MUST be used as-is

## Configuration Precedence

Implementations MUST follow this precedence order (lowest to highest priority):

1. **Built-in defaults** - Hardcoded in the application
2. **Global configuration** - `$XDG_CONFIG_HOME/clearhead/config.json`
3. **Environment variables** - `CLEARHEAD_*` prefix
4. **Command-line arguments** - Highest priority (CLI tools only)

Later sources override earlier ones. Missing values fall through to the next level.

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

### Sync Settings (`sync_*`)

The sync service (`clearhead sync`) uses the following settings. See [Sync Architecture](./sync_architecture.md) for full details.

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `sync_enabled` | boolean | `false` | Enable CRDT synchronization |
| `sync_relay_url` | string | `null` | WebSocket URL of relay server (e.g., `wss://sync.example.com`) |
| `sync_peers` | array[string] | `[]` | Direct peer URLs for LAN/mesh sync |
| `sync_interval_seconds` | integer | `30` | How often to poll for changes in watch mode |
| `sync_on_save` | boolean | `true` | Trigger sync immediately when LSP updates CRDT |

**Example:**
```json
{
  "sync_enabled": true,
  "sync_relay_url": "wss://sync.clearhead.io",
  "sync_peers": [
    "wss://192.168.1.100:8080",
    "wss://192.168.1.101:8080"
  ],
  "sync_interval_seconds": 30,
  "sync_on_save": true
}
```

**Environment variables:**
```bash
CLEARHEAD_SYNC_ENABLED=true
CLEARHEAD_SYNC_RELAY_URL="wss://sync.example.com"
CLEARHEAD_SYNC_PEERS='["wss://192.168.1.100:8080"]'
CLEARHEAD_SYNC_INTERVAL_SECONDS=60
CLEARHEAD_SYNC_ON_SAVE=false
```

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

A comprehensive configuration using multiple implementations:

```json
{
  "data_dir": "~/Dropbox/clearhead",
  "config_dir": "~/.config/clearhead",
  "state_dir": "~/.local/state/clearhead",
  "default_file": "inbox.actions",

  "cli_format": "table",
  "cli_indent_style": "tabs",
  "cli_indent_width": 2,

  "nvim_auto_normalize": true,
  "nvim_format_on_save": true,
  "nvim_inbox_file": "~/Dropbox/clearhead/inbox.actions",
  "nvim_lsp_enable": true,
  "nvim_lsp_binary_path": "/usr/local/bin/clearhead_cli",

  "sync_enabled": true,
  "sync_relay_url": "wss://sync.clearhead.io",
  "sync_interval_seconds": 30,
  "sync_on_save": true
}
```

**Note:** While `data_dir` can point to a file-sync service like Dropbox for the DSL files, `state_dir` should remain local. The CRDT handles cross-device sync; file-syncing the CRDT would cause conflicts.

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
4. Implements configuration precedence correctly (defaults → global config → env → args)
5. Uses `CLEARHEAD_*` prefix for environment variables
6. Handles missing/invalid configuration gracefully with defaults
7. Supports shell expansion in path values
8. Uses namespaced prefixes for implementation-specific settings (e.g., `cli_`, `nvim_`, `sync_`)

### Testing Conformance

To test an implementation's conformance:

```bash
# Test 1: Default behavior (no config)
rm -rf ~/.config/clearhead ~/.local/share/clearhead
<implementation_command>
# Should use built-in defaults without error

# Test 2: Config file override
mkdir -p ~/.config/clearhead
echo '{"default_file": "test.actions"}' > ~/.config/clearhead/config.json
<implementation_command>
# Should use test.actions as default

# Test 3: Environment override
export CLEARHEAD_DEFAULT_FILE="env.actions"
<implementation_command>
# Should use env.actions (env wins over config)

# Test 4: Invalid JSON handling
echo '{invalid json}' > ~/.config/clearhead/config.json
<implementation_command>
# Should warn and fall back to defaults, not crash
```

## See Also

- [Action File Format](./action_specification.md) - Core file format
- [Naming Conventions](./naming_conventions.md) - File and directory naming
- [JSON Schema](./json_schema_specification.md) - Action serialization format
- [Sync Architecture](./sync_architecture.md) - CRDT sync and state management
- [Event Logging](./event_logging_specification.md) - Events database for analytics

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for version history and updates to this specification.
