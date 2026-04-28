# Naming Conventions for repositories

to one aspect that is orthogonal, but important to consider is the naming conventions and repo conventions when it comes to collections of action files.

In particular, we want to make it ergonomic to manage multiple "containers" whether you call them stories or projects, by leveraging the filesystem. 

while the [file specification](./action_specification.md) defines how individual action files are structured, this specification defines how those files should be organized and named within a workspace.

They are separate, because different implementors may choose to work with the format, but choose to avoid these conventions which is fine, this way implementors can absorb specifications a-la-carte and take on the complexity they want to consider

## Scoping

For our work we generally have 3 scopes to consder:
- Machine-Wide Scope: Config
- User Scope: Data + Config
- Project Scope: Data + Config

As is standard, each level is less prioritized than the next, so project scope overrides user scope which overrides machine-wide scope.

The user-scope data is for data that belongs to the user of that actual machine but is not generally attached to a given project and its location is configured via the `XDG_DATA_HOME` environment variable, with a default of `~/.local/share/` for unix systems and `%APPDATA%` for windows systems.

This defined by the presence of a `.clearhead` directory. This may be empty as to only express a desire for this to be designated a project-local scope
- while the default will be that this is in the root of the git directory, the algorithm itself will simply look for the nearest `.clearhead` directory and designate that as the project root, this way we can have multiple projects within a single git repository if desired, or even have a project that is not attached to a git repository at all

## Workspace Structure

All action files/folders should be organized into a directory that conforms with the standards of the given operating system.

Please see [Configuration Specification](./configuration.md) for details on locating the global workspace location and how to configure it.

In general the data should reside in `XDG_DATA_HOME/clearhead/`. The workspace root is a container for parallel top-level concepts — not a dump of mixed files:

```
<workspace>/
├── archive.ttl        ← the only TTL file; holds all closed history
├── charters/          ← all charter content lives here (acts, plans, markdown, json sidecars)
├── objectives/        ← objectives live here
└── templates/         ← act templates live here
```

This scoping makes discovery trivial: implementors scan `charters/` for charter content and never need an exclusion list for other workspace concerns.

By default, everyone should have a `charters/inbox.actions` file within that workspace. This file serves as the default location for uncategorized acts.

### Example
So if we go over the structure of the work we can see this as an example with a global and project workspace at the [examples directory](./examples/workspaces/)

this shows both the project and user scope for examples of mixed layouts that would be representative of real world usage

### Objectives
Objectives are all located in an `objectives` directory within the workspace where all objectives of the file format:
`<objective-alias>.md` - a markdown file containing the description of the objective, its purpose, and any other relevant information as per [the objective spec](./objectives.md) 

in a project-local scope, this should reside within `<project-root>/.clearhead/objectives/` while in a user-wide scope, this should reside within `objectives/` folder within the user workspace

#### Sub Objectives
objective files within the `objectives` directory are assumed to be a group of objectives,

with:
- `<objective-alias>/README.md` - a markdown file containing the description of the objective group, its purpose, and any other relevant information as per [the objective spec](./objectives.md)
- `<objective-alias>/<subobjective-alias>.md` - a markdown file containing the description of the subobjective, its purpose, and any other relevant information as per [the objective spec](./objectives.md)

this allows implementors to organize subobjectives within the directories without worrying about namespace colisions as the alias is scoped within the parent objective alias

### Charters

charters belong in the dedicated `charters` directory within the workspace, where each charter is represented as a markdown file or a directory containing a `README.md` file.

While the action specification allows for charters to be defined within the files themselves, it can often feel natural to break these files into separate files/folders for organization.

To this end, we support the following conventions, with the assumption implementors will leverage these structures to provide better user experiences.
- we can also designate `<charter>.md` files for charters that are primarily prose and not action-focused, but still want to be linked to actions within the platform
  - please see [the charter spec](./charters.md) for more details on how to structure these files
  - This allows for sub-projects through the combination of directories and files.
- `$workspace/charters/<charter-name>/README.md` - A file containing a description of the charter, its purpose, and any other relevant information as per [the charter spec](./charters.md) 

all closed charters are stored in the `archive.ttl` file along with their children to keep a complete record

All charters and subcharters live within the `charters/` directory. Users are free to symlink README files from the project root into `.clearhead/charters/` if desired, but the canonical location is always within `charters/`.

Unless a specific `README.md` is present, the alias of the root charter is inferred from the project directory name. Users can override this by creating a `charters/README.md` with an explicit alias in the frontmatter.

#### Hierarchy
While plans express hierarchy through the file format, charters express hierarchy through placement.

Specifically, while we do support parent as front matter, the primary way that lineage is created is by placing subcharters and their plans in the directory of its parent.

In this way, we can structure charters and subcharters

#### On Scoping

For project-scoped structures, the root charter is the project directory itself. Its files live at:
- `<project>/.clearhead/charters/next.actions` — root charter acts
- `<project>/.clearhead/charters/plans/` — root charter plans (vdir directory)
- `<project>/.clearhead/charters/README.md` — root charter description (optional)

The charter name is inferred from the project directory name. `next.actions` at the root of `charters/` are the signal that this is the root charter rather than a named sub-charter.

#### Sidecar for data

we can also add the `.<charter-name>.json` sidecar file that allows users to place data that is relevant to the charter but not something that should be kept in the files themselves.

This will cover all the pieces we will be going over and has various properties to link different objects together at a data level without cluttering the core files themselves

please review the [charter sidecar schema](./schemas/charter_metadata.schema.json) for more details on how to use this file and its properties.

Note: we use the hidden file convention here to indicate that this is a sidecar file meant to be read and written by tools as a companion to the charter, but should not be directly interacted with by users.


#### Plans

Plans are stored as individual `.ics` files within a `plans/` directory per charter. Each `.ics` file contains a single `VCALENDAR` with a single `VEVENT`, and is named by its VEVENT `UID` (e.g., `a1b2c3d4.ics`).

This one-event-per-file layout (commonly known as "vdir" format) is directly compatible with calendar tools like khal and CalDAV sync tools like vdirsyncer, enabling calendar applications to read and write plans in-place without format conversion.

Any charter with plans requires directory form. The `plans/` directory itself signals that a charter has schedule data.

to make it so that plans dont necessarily only confer to folder-based subcharters the `<charer-name>.plans/` forlder can be created to serve the same purpose

All paths are relative to `charters/`. An example:

  - `charters/inbox/plans/<uid>.ics`
  - `charters/inbox/plans/<uid>.ics`
  - `charters/work/plans/<uid>.ics`
  - `charters/work/feature/plans/<uid>.ics`
  - `charters/subproject.plans/<uid>.ics`

  which has 3 charters with plans:
  - inbox
  - work
  - work/feature
  - subproject with some plans in a folder

Sub-charter inference follows from directory structure: any subdirectory with its own `plans/` directory or `next.actions` file is a sub-charter.

Multi-event `.ics` files (e.g., bulk exports from Google Calendar) are an import format, not a storage format. Implementations should provide an import path that splits multi-event files into individual files within the target charter's `plans/` directory.


Be sure to review [The reference syntax](./reference_syntax.md) for guidance on working with sub charters and sub plans.

For schedule semantics and VEVENT mapping, see [ics_schedule_spec.md](./ics_schedule_spec.md).

#### Planned Acts
Per the [Ontology](./ontology.md) specification, planned acts are the actual executions of plans. and 

planned acts are stored in the `.actions` files within the workspace and represent the lowest atomic unit of work within the system.

`.actions` files do not define recurrence rules. Recurrence and schedule timing are represented in `.ics` files and materialized into planned acts through expansion workflows.

All paths are relative to `charters/`:

- `charters/<charter>.actions` — upcoming and in-progress acts for that charter
- `charters/next.actions` — root charter acts (project or user workspace root)
- `charters/inbox.actions` — inbox charter acts
- `charters/<charter>.completed.actions` — completed and cancelled acts for that charter
- `charters/<charter>/next.actions` — root acts for a folder-form charter

When a charter is closed, all closed planned acts within `charters/<charter>.completed.actions` are swept into `archive.ttl` at the workspace root (`.clearhead/archive.ttl`). This is the only TTL file in the workspace — everything else is either in `charters/`, `objectives/`, or `templates/`.

Charter stem derivation follows the same rules as plan name inference: `next.actions` uses the parent directory name; all other `.actions` files use the file stem. Unlike plan name inference, `inbox` is NOT skipped — `charters/inbox.actions` is valid.

## Workflows

Now, its one thing to speak on the concrete file formats for each record type but the other piece to cover is the workflow that actually handled these various structures and dictates what happens when and where. for this, we are going to go a little more over the workflows that allow this format to be updated automatically or manually based on what people prefer

### Tempates
Templates are a list of planned acts in the form of `<name>.actions` files that are stored in a `templates/` directory at the root of the workspace. these are meant to be used as templates for generating planned acts either through schedules or on demand.

it is assumed that the filename will be the reference for the template, so if we have a `weekly-review.actions` file in the `templates/` directory, then the reference for that template will be `weekly-review` and this is what will be used in the VEVENT DESCRIPTION field as `template: weekly-review` (first line of the event notes in any standard calendar app)

this will also allow for on demand generation of planned acts either as a side-effect to charter creation or through a command like `apply template` which will allow users to generate planned acts from templates on demand without needing to wait for the schedule to trigger them

### Archival

One concept that is very important to the workspace format is the process of "archiving" things. weve covered the names above but its working from a reference point lets go from the beginning

1. At the lowest level, we have the planned acts that are implementations of their (optional) parent plans. 
  1. at first, these are all open, then as the user is closing the planned acts, the move from `<charter>.actions` to `<charter>.completed.actions` in order to remove the format of clutter and make the process of tracking closed planned acts easier for both humans to comprehend and for databases to ingest only the data they may need, this way open act queries can be fast, but full history searchs are still possible
2. If we move a level up, we have the plans in `<charter>/plans/`, again, all plans start open but schedules simply "are no longer scheduled" they have no state explicitly however they are still logged as an example of a schedule 
3. Finally, like plans, the charters themselves at `charters/<charter>.md` can be archived after they are closed. at this point the most complex process happens.
  1. the contents of `charters/<charter>.completed.actions` are moved to `archive.ttl` at the workspace root
  2. the individual `.ics` files in `charters/<charter>/plans/` are converted to turtle and moved to `archive.ttl`
  3. the charter contents itself are converted to turtle and moved to `archive.ttl` for later review
  4. the (now empty) `charters/<charter>.actions`, `charters/<charter>.completed.actions`, `charters/<charter>/plans/` are removed from the workspace

REMEMBER, per the [process specification](./process.md) it is assumed that all child plans are completed/cancelled which is why the open files above are expected to be empty or atleast emptyable before being moved to the central `archive.ttl`

this is how we maintain a format that is able to evolve gracefully

## See Also

- [Configuration](./configuration.md) - XDG paths and config settings
- [Process](./process.md) - Workflow including recurring action behavior
- [Sync Architecture](./sync_architecture.md) - CRDT sync and state management
- [Action File Format](./action_file_format.md) - DSL syntax
