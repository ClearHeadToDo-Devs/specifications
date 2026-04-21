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

All action files/folders should be organized into a directory that conforms with the standards of the given operating system 

Please see [Configuration Specification](./configuration.md) for details on locating the global workspace location and how to configure it.

but in general the data should reside in `XDG_DATA_HOME/clearhead/`

By default, everyone should have an `inbox.actions` file within that workspace. This file serves as the default location for uncategorized actions.

### Objectives
Objectives are all located in an `objectives` directory within the workspace where all objectives of the file format:
`<objective-alias>.md` - a markdown file containing the description of the objective, its purpose, and any other relevant information as per [the objective spec](./objectives.md) 

in a project-local scope, this should reside within `<project-root>/.clearhead/objectives/` while in a user-wide scope, this should reside within `objectives/` folder within the user workspace

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

All subcharters within the project should be located within the .clearhead directory, whether that comes from designating plans in that folder, or new markdown files, as to not interfere with the natural structure of the project and its files

While users are free to symlink the existing README files from the project root into the `.clearhead` directory, we want to avoid the situation where we have multiple README files in the project root as it can cause confusion and clutter, so we want to encourage users to keep these files within the `.clearhead` directory

Another point is that unless a specific README is made for that project root, the alias of the charter is assumed to be the project name itself using the directory name by default but users can always override this by creating a README file with a specific alias, but this way we can have a default charter for the project without needing to create a separate file for it, and if users want to create a separate file for it they can do so without worrying about namespace collisions as the alias is scoped within the project root

This makes searching for the workspace easy and scoped 

#### Hierarchy
While plans express hierarchy through the file format, charters express hierarchy through placement.

Specifically, while we do support parent as front matter, the primary way that lineage is created is by placing subcharters and their plans in the directory of its parent.

In this way, we can structure charters and subcharters

#### On Scoping

for project-scoped structures, we must remember that in the case of a project the format `<project-name>/.clearhead/next.actions` the charter is the name of the PROJECT folder
same goes for `<project-name>/.clearhead/README.md` will be the core charter NOT the traditional README.

users are free to symlink or do whatever else feels appropriate if they wish but this is not the default

### Plans

Plans are stored in `.ics` files so that scheduling is encapsulated within the calendar format

now, by default we have a few naming conventions
- `<charter>.ics` for plans that are attached to a specific charter
- `<charter>/next.ics` for charters that are in the form of folders, we can use the `next.ics` file to designate the primary calendar file
  - do note, this accounts for sub-charters as well if people want to nest the structure
  - specifically, anything NOT named `next.ics` is assumed to be a subcharter of the charter for which the folder is the name, this way we can easily create nested charter structures

  so an example would be the following format:

  - `inbox.ics`
  - `other.ics`
  - `new/next.ics`
  - `new/subcharter.ics`

  which has 4 charters:
  - inbox
  - other
  - new
  - new/subcharter

be sure to review [The reference syntax](./reference_syntax.md) for guidance on working with sub charters and sub plans

like above, project-local plans should be located within the `.clearhead` directory to avoid cluttering the project root, including the core `next.actions` file that are attached to the project as a charter while user-wide charters can be located at the root of the user workspace,

### Planned Acts
Per the [Ontology](./ontology.md) specification, planned acts are the actual executions of plans. and 

planned acts are stored in the `.actions` files within the workspace and represent the lowest atomic unit of work within the system.

- `<charter>.actions` — upcoming and in-progress acts for that charter
- `<workspace>/.clearhead/next.actions` — upcoming and in-progress acts for the project charter
- `<workspace>/inbox.actions` — upcoming and in-progress acts for the inbox charter in the user workspace
- `<charter>.completed.actions` — completed and cancelled acts for that charter
- `<charter>/next.actions` — upcoming and in-progress acts for that charter if the charter is a folder

When the plans that dictate those planned acts are completed, future planned acts in `<charter>.actions` are removed and all closed planned acts within `<charter>.completed.actions` are moved to `archive.ttl` at the root of the data directory:

Charter stem derivation follows the same rules as plan name inference: `next.actions` uses the parent directory name; all other `.actions` files use the file stem. Unlike plan name inference, `inbox` is NOT skipped — `inbox.actions` is valid.

And like above, project-local planned acts should be located within the `.clearhead` directory to avoid cluttering the project root, while user-wide planned acts can be located at the root of the user workspace

## Workflows

Now, its one thing to speak on the concrete file formats for each record type but the other piece to cover is the workflow that actually handled these various structures and dictates what happens when and where. for this, we are going to go a little more over the workflows that allow this format to be updated automatically or manually based on what people prefer

### Archival

One concept that is very important to the workspace format is the process of "archiving" things. weve covered the names above but its working from a reference point lets go from the beginning

1. At the lowest level, we have the planned acts that are implementations of their parent plans. 
  1. at first, these are all open, then as the user is closing the planned acts, the move from `<charter>.actions` to `<charter>.completed.actions` in order to remove the format of clutter and make the process of tracking closed planned acts easier for both humans to comprehend and for databases to ingest only the data they may need, this way open act queries can be fast, but full history searchs are still possible
2. If we move a level up, we have the plans in `<charter>.ics`, again, all plans start open
3. Finally, like plans, the charters themselves at `<charter>.md` can be archived themselves after they are closed. at this point the most complex process happens.
  1. the contents of `<charter>.completed.actions` are moved to the root `archive.ttl` file
  2. the contents of `<charcter>.ics` are converted to turtle and moved to `archive.ttl`
  3. the charter contents itself are converted to turtle and moved to `archive.ttl` for later review
  4. the (now empty) `<charter>.actions`, `<charter>.completed.actions`, `<charter>.ics` are removed from the workspace

REMEMBER, per the [process specification](./process.md) it is assumed that all child plans are completed/cancelled which is why the open files above are expected to be empty or atleast emptyable before being moved to the central `archive.ttl`

this is how we maintain a format that is able to evolve gracefully

## See Also

- [Configuration](./configuration.md) - XDG paths and config settings
- [Process](./process.md) - Workflow including recurring action behavior
- [Sync Architecture](./sync_architecture.md) - CRDT sync and state management
- [Action File Format](./action_file_format.md) - DSL syntax

