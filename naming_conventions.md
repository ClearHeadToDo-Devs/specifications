# Naming Conventions for repositories

to one aspect that is orthogonal, but important to consider is the naming conventions and repo conventions when it comes to collections of action files.

In particular, we want to make it ergonomic to manage multiple "containers" whether you call them stories or projects, by leveraging the filesystem. 

while the [file specification](./action_specification.md) defines how individual action files are structured, this specification defines how those files should be organized and named within a workspace.

They are separate, because different implementors may choose to work with the format, but choose to avoid these conventions which is fine, this way implementors can absorb specifications a-la-carte and take on the complexity they want to consider

## Workspace Structure

All action files/folders should be organized into a directory that conforms with the standards of the given operating system 

Please see [Configuration Specification](./configuration.md) for details on locating the global workspace location and how to configure it.

but in general the data should reside in `XDG_DATA_HOME/clearhead/`

By default, everyone should have an `inbox.actions` file within that workspace. This file serves as the default location for uncategorized actions.

### Objectives
Objectives are all located in an `objectives` directory within the workspace where all objectives of the file format:
`<objective-alias>.md` - a markdown file containing the description of the objective, its purpose, and any other relevant information as per [the objective spec](./objectives.md) 

#### subobjectives
objective files within the `objectives` directory are assumed to be a group of objectives,

with:
- `<objective-alias>/README.md` - a markdown file containing the description of the objective group, its purpose, and any other relevant information as per [the objective spec](./objectives.md)
- `<objective-alias>/<subobjective-alias>.md` - a markdown file containing the description of the subobjective, its purpose, and any other relevant information as per [the objective spec

this allows implementors to organize subobjectives within the directories without worrying about namespace colisions as the alias is scoped within the parent objective alias

### Charter Naming

While the action specification allows for charters to be defined within the files themselves, it can often feel natural to break these files into separate files/folders for organization.

To this end, we support the following conventions, with the assumption implementors will leverage these structures to provide better user experiences.
- we can also designate `<charter>.md` files for charters that are primarily prose and not action-focused, but still want to be linked to actions within the platform
  - please see [the charter spec](./charters.md) for more details on how to structure these files
  - This allows for sub-projects through the combination of directories and files.
- `$workspace/<charter-name>/README.md` - A file containing a description of the charter, its purpose, and any other relevant information as per [the charter spec](./charters.md) 

all closed charters are stored in the `archive.ttl` file along with their children to keep a complete record

### Plans
Plans can have their charter defined from within the structure

now, by default we have a few naming conventions
- `<charter>`.actions for plans that are attached to a specific charter
- `<charter>.completed.actions` represent completed actions attached to an open charter
- `<charter>/next.actions` for charters that are in the form of folders, we can use the `next.actions` file to designate the primary actions file
  - do note, this accounts for sub-charters as well if people want to nest the structure
  - specifically, anything NOT named `next.actions` is assumed to be a subcharter of the charter for which the folder is the name, this way we can easily create nested charter structures

  so an example would be the following format:

  - `inbox.actions`
  - `other.actions`
  - `new/next.actions`
  - `new/subcharter.actions`

  which has 4 charters:
  - inbox
  - other
  - new
  - new/subcharter

be sure to review [The reference syntax](./reference_syntax.md) for guidance on working with sub charters and sub plans

### Planned Acts
Per the [Ontology](./ontology.md) specification, planned acts are the actual executions of plans.

Planned acts are stored per-charter in two sibling Turtle files next to the `.actions` file:

- `<charter>.open.ttl` — upcoming and in-progress acts (e.g. `health.open.ttl`, `build_clearhead/build_clearhead.open.ttl`)
- `<charter>.closed.ttl` — completed and cancelled acts for that charter

When the plans that dictate those planned acts are completed, future planned acts in `<charter>.open.ttl` are removed and all closed planned acts within `<charter>.closed.ttl` are moved to `archive.ttl` at the root of the data directory:

Charter stem derivation follows the same rules as plan name inference: `next.actions` uses the parent directory name; all other `.actions` files use the file stem. Unlike plan name inference, `inbox` is NOT skipped — `inbox.open.ttl` is valid.

Planned acts are treated as data rather than human-readable files; they exist primarily so the system can query recurring and upcoming occurrences of a plan.

## Workflows

Now, its one thing to speak on the concrete file formats for each record type but the other piece to cover is the workflow that actually handled these various structures and dictates what happens when and where. for this, we are going to go a little more over the workflows that allow this format to be updated automatically or manually based on what people prefer

### Archival

One concept that is very important to the workspace format is the process of "archiving" things. weve covered the names above but its working from a reference point lets go from the beginning

1. At the lowest level, we have the planned acts that are implementations of their parent plans. 
  1. at first, these are all open, then as the user is closing the planned acts, the move from `<charter>.open.ttl` to `<charter>.closed.ttl` in order to remove the format of clutter and make the process of tracking closed planned acts easier for both humans to comprehend and for databases to ingest only the data they may need, this way open act queries can be fast, but full history searchs are still possible
2. If we move a level up, we have the plans in `<charter>.actions`, again, all plans start open, and as plans are closed, users can choose to "archive" them by sending them to `<charter>.completed.actions`
3. Finally, like plans, the charters themselves at `<charter>.md` can be archived themselves after they are closed. at this point the most complex process happens.
  1. the contents of `<charter>.closed.ttl` are moved to the root `archive.ttl` file
  2. the contents of `<charter>.completed.actions` are converted to turtle and moved to `archive.ttl`
  3. the charter contents itself are converted to turtle and moved to `archive.ttl` for later review
  4. the (now empty) `<charter>.actions`, `<charter>.completed.actions`, `<charter>.closed.ttl` and `<charter>.open.ttl` are removed from the workspace

REMEMBER, per the [process specification](./process.md) it is assumed that all child plans are completed/cancelled which is why the open files above are expected to be empty or atleast emptyable before being moved to the central `archive.ttl`

this is how we maintain a format that is able to evolve gracefully

## See Also

- [Configuration](./configuration.md) - XDG paths and config settings
- [Process](./process.md) - Workflow including recurring action behavior
- [Sync Architecture](./sync_architecture.md) - CRDT sync and state management
- [Action File Format](./action_file_format.md) - DSL syntax

