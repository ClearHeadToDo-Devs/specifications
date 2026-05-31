# Workspace

One aspect that is orthogonal, but important to consider is how workspaces are structured, discovered, and identified when it comes to collections of action files.

In particular, we want it to be ergonomic to manage multiple "containers" whether you call them stories or projects, by leveraging the filesystem.

While the [file specification][action-file-format] defines how individual action files are structured, this specification defines how those files should be organized and named within a workspace.

They are separate, because different implementors may choose to work with the format, but choose to avoid these conventions which is fine, this way implementors can absorb specifications a-la-carte and take on the complexity they want to consider.

## Scoping

For our work we generally have 3 scopes to consider:
- Machine-Wide Scope: Config
- User Scope: Data + Config
- Project Scope: Data + Config

As is standard, each level is less prioritized than the next, so project scope overrides user scope which overrides machine-wide scope.

The user-scope data is for data that belongs to the user of that actual machine but is not generally attached to a given project and its location is configured via the `XDG_DATA_HOME` environment variable, with a default of `~/.local/share/` for unix systems and `%APPDATA%` for windows systems.

This defined by the presence of a `.clearhead` directory. This may be empty as to only express a desire for this to be designated a project-local scope
- while the default will be that this is in the root of the git directory, the algorithm itself will simply look for the nearest `.clearhead` directory and designate that as the project root, this way we can have multiple projects within a single git repository if desired, or even have a project that is not attached to a git repository at all

## Workspace Structure

All action files/folders should be organized into a directory that conforms with the standards of the given operating system.

Please see [Configuration][configuration] for details on locating the global workspace location and how to configure it.

In general the data should reside in `XDG_DATA_HOME/clearhead/`. The workspace root is a container for parallel top-level concepts — not a dump of mixed files:

```
<workspace>/
├── archive.ttl        ← the only TTL file; holds all closed history
├── charters/          ← acts (.actions), markdown (.md), json sidecars
├── plans/             ← vdir calendars; one subdirectory per charter
├── objectives/        ← objectives live here
└── templates/         ← act templates live here
```

This scoping makes discovery trivial: implementors scan `charters/` for charter content and `plans/` for schedule data, without needing exclusion lists.

By default, everyone should have a `charters/inbox.actions` file within that workspace. This file serves as the default location for uncategorized acts.

### Example
So if we go over the structure of the work we can see this as an example with a global and project workspace at the [examples directory][examples].

this shows both the project and user scope for examples of mixed layouts that would be representative of real world usage

### Objectives
Objectives are all located in an `objectives` directory within the workspace where all objectives of the file format:
`<objective-alias>.md` - a markdown file containing the description of the objective, its purpose, and any other relevant information as per [the objective spec][objectives]

in a project-local scope, this should reside within `<project-root>/.clearhead/objectives/` while in a user-wide scope, this should reside within `objectives/` folder within the user workspace

#### Sub Objectives
objective files within the `objectives` directory are assumed to be a group of objectives,

with:
- `<objective-alias>/README.md` - a markdown file containing the description of the objective group, its purpose, and any other relevant information as per [the objective spec][objectives]
- `<objective-alias>/<subobjective-alias>.md` - a markdown file containing the description of the subobjective, its purpose, and any other relevant information as per [the objective spec][objectives]

this allows implementors to organize subobjectives within the directories without worrying about namespace colisions as the alias is scoped within the parent objective alias

### Charters

charters belong in the dedicated `charters` directory within the workspace, where each charter is represented as a markdown file or a directory containing a `README.md` file.

While the action specification allows for charters to be defined within the files themselves, it can often feel natural to break these files into separate files/folders for organization.

To this end, we support the following conventions, with the assumption implementors will leverage these structures to provide better user experiences.
- we can also designate `<charter>.md` files for charters that are primarily prose and not action-focused, but still want to be linked to actions within the platform
  - please see [the charter spec][charters] for more details on how to structure these files
  - This allows for sub-projects through the combination of directories and files.
- `$workspace/charters/<charter-name>/README.md` - A file containing a description of the charter, its purpose, and any other relevant information as per [the charter spec][charters]

all closed charters are stored in the `archive.ttl` file along with their children to keep a complete record

All charters and subcharters live within the `charters/` directory. Users are free to symlink README files from the project root into `.clearhead/charters/` if desired, but the canonical location is always within `charters/`.

Unless a specific `README.md` is present, the alias of the root charter is inferred from the project directory name. Users can override this by creating a `charters/README.md` with an explicit alias in the frontmatter.

#### Hierarchy
While actions express hierarchy through the file format, charters express hierarchy through placement.

Specifically, while we do support parent as front matter, the primary way that lineage is created is by placing subcharters and their plans in the directory of its parent.

In this way, we can structure charters and subcharters

#### On Scoping

For project-scoped structures, the root charter is the project directory itself. Its files live at:
- `<project>/.clearhead/charters/next.actions` — root charter acts
- `<project>/.clearhead/plans/next/` — root plans (vdir directory)
- `<project>/.clearhead/charters/README.md` — root charter description (optional)

The charter name is inferred from the project directory name. `next.actions` at the root of `charters/` are the signal that this is the root charter rather than a named sub-charter.

#### Sidecar for data

we can also add the `.<charter-name>.json` sidecar file that allows users to place data that is relevant to the charter but not something that should be kept in the files themselves.

This will cover all the pieces we will be going over and has various properties to link different objects together at a data level without cluttering the core files themselves

please review the [charter sidecar schema][charter-sidecar-schema] for more details on how to use this file and its properties.

Note: we use the hidden file convention here to indicate that this is a sidecar file meant to be read and written by tools as a companion to the charter, but should not be directly interacted with by users.


#### Plans

Plans are stored as individual `.ics` files within the `plans/` directory with a directory per charter.

Each `.ics` file contains a single `VCALENDAR` with a single `VEVENT`, and is named by its VEVENT `UID` (e.g., `a1b2c3d4.ics`).

This one-event-per-file layout (commonly known as "vdir" format) is directly compatible with calendar tools like khal and CalDAV sync tools like vdirsyncer, enabling calendar applications to read and write plans in-place without format conversion.

Any charter with plans requires directory form. The `plans/` directory itself signals that a workspace has schedule data.

All paths are relative to `<data_root>/plans/`. An example:

  - `inbox/<uid>.ics`
  - `work/<uid>.ics`
  - `work-feature/<uid>.ics`
  - `subproject/<uid>.ics`

  which maps to charters:
  - `inbox` charter
  - `work` charter
  - `work/feature` sub-charter (hierarchy encoded with `-`)
  - `subproject` charter

Multi-event `.ics` files (e.g., bulk exports from Google Calendar) are an import format, not a storage format. Implementations should provide an import path that splits multi-event files into individual files within the target charter's `plans/` directory.

Be sure to review [the reference syntax][reference-syntax] for guidance on working with sub charters and sub plans.

For schedule semantics and VEVENT mapping, see the [ICS Schedule Spec][ics-schedule-spec].

#### Actions
Per the [Ontology][ontology] specification, actions are the actual executable work items in the system, whether they are generated from plans or created directly.

Actions are stored in the `.actions` files within the workspace and represent the lowest atomic unit of work within the system.

`.actions` files do not define recurrence rules. Recurrence and schedule timing are represented in `.ics` files and materialized into actions through expansion workflows.

All paths are relative to `charters/`:

- `charters/<charter>.actions` — active acts for that charter (capped at `expansion_primary_instances` per schedule)
- `charters/<charter>.upcoming.actions` — future generated instances beyond the primary cap, not yet in the active set
- `charters/next.actions` — root charter acts (project or user workspace root)
- `charters/inbox.actions` — inbox charter acts
- `charters/<charter>.completed.actions` — completed and cancelled acts for that charter
- `charters/<charter>/next.actions` — root acts for a folder-form charter

When a charter is closed, all closed actions within `charters/<charter>.completed.actions` are swept into `archive.ttl` at the workspace root (`.clearhead/archive.ttl`). Any remaining open or cancelled actions in `charters/<charter>.upcoming.actions` are also cancelled and swept into `archive.ttl` at this time. This is the only TTL file in the workspace — everything else is either in `charters/`, `objectives/`, or `templates/`.

Charter stem derivation follows the same rules as plan name inference: `next.actions` uses the parent directory name; all other `.actions` files use the file stem. Unlike plan name inference, `inbox` is NOT skipped — `charters/inbox.actions` is valid.

## Named Graph Isolation

Each workspace maps 1-1 to an RDF named graph. This enables querying a single workspace in isolation or spanning multiple configured workspaces without data coalescing into a single undifferentiated graph. See [Decision 28][decision-28] for the rationale.

### Workspace Identity

Every workspace has a stable identity stored in `.clearhead/config.json` alongside other workspace-level config:

```json
{
  "workspace_id": "019e43e4-...",
  "workspace_name": "platform",
  "created_at": "2026-05-31"
}
```

`workspace_id` is generated once by `clearhead init` and must never be regenerated — it is the durable identity of the workspace's named graph. Regenerating it would silently break named graph identity for any archived or shared data derived from that workspace.

`workspace_name` is the display name used in multi-workspace output and cross-workspace reference syntax (`name:charter/action`). Inferred from the project directory name by `init`; can be overridden manually.

`created_at` records when the workspace was initialized. Informational only.

The named graph URI is derived as: `urn:clearhead:workspace:<workspace_id>`

For workspaces without a `config.json` or `workspace_id`, implementations should fall back to a deterministic UUIDv5 derived from the root path rather than failing. This ensures uninitialized workspaces remain functional while making explicit initialization the recommended path.

### Query Scope

Query scope is determined by the `additional_workspaces` configuration:

- **Single workspace (default):** Only the current workspace's named graph is loaded and queried.
- **Multi-workspace:** When `additional_workspaces` lists additional workspace paths, all of them are loaded into the same store alongside the current workspace — each in its own named graph. Queries span all loaded named graphs.

The scope is declared in config, not per-command. A user who configures additional workspaces intends cross-workspace visibility by default. This means the platform repository, which lists all submodule workspaces as `additional_workspaces`, queries across all of them without any additional flags.

### Initialization

`clearhead init` bootstraps a workspace:

1. Generates a UUIDv7 and writes `workspace_id`, `workspace_name`, `created_at` to `.clearhead/config.json` (skipped if `workspace_id` already present)
2. Creates the `charters/` directory structure (skipped if already present)

`init` is idempotent — rerunning it on an already-initialized workspace is safe and makes no changes. Pass `--force` to regenerate identity fields (destructive — breaks named graph continuity).

## Workflows

Now, its one thing to speak on the concrete file formats for each record type but the other piece to cover is the workflow that actually handled these various structures and dictates what happens when and where. for this, we are going to go a little more over the workflows that allow this format to be updated automatically or manually based on what people prefer

### Templates
Templates are a list of actions in the form of `<name>.actions` files that are stored in a `templates/` directory at the root of the workspace. these are meant to be used as templates for generating actions either through schedules or on demand.

it is assumed that the filename will be the reference for the template, so if we have a `weekly-review.actions` file in the `templates/` directory, then the reference for that template will be `weekly-review` and this is what will be used in the VEVENT DESCRIPTION field as `template: weekly-review` (first line of the event notes in any standard calendar app)

this will also allow for on demand generation of actions either as a side-effect to charter creation or through a command like `apply template` which will allow users to generate actions from templates on demand without needing to wait for the schedule to trigger them

### Archival

One concept that is very important to the workspace format is the process of "archiving" things. weve covered the names above but its working from a reference point lets go from the beginning

1. At the lowest level, we have the actions that are implementations of their optional parent plans.
  1. at first, these are all open, then as the user is closing the actions, they move from `<charter>.actions` to `<charter>.completed.actions` in order to remove clutter and make the process of tracking closed actions easier for both humans and databases to comprehend, this way open act queries can be fast, but full history searches are still possible
2. If we move a level up, we have the plans in `plans/<charter-name>/`, again, all plans start open but schedules simply "are no longer scheduled" they have no state explicitly however they are still logged as an example of a schedule
3. Finally, like plans, the charters themselves at `charters/<charter>.md` can be archived after they are closed. at this point the most complex process happens.
  1. the contents of `charters/<charter>.completed.actions` are moved to `archive.ttl` at the workspace root
  2. the individual `.ics` files in `plans/<charter-name>/` are converted to turtle and moved to `archive.ttl`
  3. the charter contents itself are converted to turtle and moved to `archive.ttl` for later review
  4. the (now empty) `charters/<charter>.actions`, `charters/<charter>.completed.actions`, `plans/<charter-name>/` are removed from the workspace

REMEMBER, per the [process spec][process] it is assumed that all child plans are completed/cancelled which is why the open files above are expected to be empty or atleast emptyable before being moved to the central `archive.ttl`

this is how we maintain a format that is able to evolve gracefully

## See Also

- [Action File Format] — DSL syntax
- [Charters] — Charter structure and frontmatter
- [Configuration] — XDG paths and config settings
- [ICS Schedule Spec] — VEVENT mapping and schedule semantics
- [Ontology] — Domain model and RDF contract
- [Process] — Workflow including recurring action behavior
- [Reference Syntax] — Sub-charter and sub-plan references
- [Sync] — CRDT sync and state management

[action-file-format]: ./action_file_format.md
[charter-sidecar-schema]: ./schemas/charter_metadata.schema.json
[charters]: ./charters.md
[configuration]: ./configuration.md
[decision-28]: ../DECISIONS.md
[examples]: ./examples/workspaces/
[ics-schedule-spec]: ./ics_schedule_spec.md
[objectives]: ./objectives.md
[ontology]: ./ontology.md
[process]: ./process.md
[reference-syntax]: ./reference_syntax.md
[sync]: ./sync.md
