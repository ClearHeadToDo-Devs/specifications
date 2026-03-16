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

From a data perspective, _unless otherwise specificied within the action itself_, any actions within this file are assumed to have the story/project of the directory name.

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

planned acts are stored in either:
- `$workspace/inbox.acts.ttl` - for planned acts connected to open plans
- `$workspace/archive.ttl` - contains all closed objectives, charters, plans, AND planned acts
  - this is the ultimate fate of all items once even the charter is closed

this is because planned acts are intended to be thought of more as data than a human-readable file and as such, most of the acts are there for review, but also for the system to be able to query the planned acts for recurring and upcoming recurrances of a plan

## See Also

- [Configuration](./configuration.md) - XDG paths and config settings
- [Process](./process.md) - Workflow including recurring action behavior
- [Sync Architecture](./sync_architecture.md) - CRDT sync and state management
- [Action File Format](./action_file_format.md) - DSL syntax

