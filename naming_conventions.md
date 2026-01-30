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

### Project/Story Naming

While the action specification allows for stories/projects to be defined within the files themselves, it can often feel natural to break these files into separate files/folders for organization.

To this end, we support the following conventions, with the assumption implementors will leverage these structures to provide better user experiences.
- `$workspace/<project-name>.actions` - A file containing actions for a specific project/story
- Any actions within this file are assumed to have the story/project of the file name unless otherwise specified within the action itself.
- `$workspace/<project-name>/next.actions` - A directory containing a project/story with its own next actions file
- This allows for sub-projects through the combination of directories and files.

From a data perspective, _unless otherwise specificied within the action itself_, any actions within this file are assumed to have the story/project of the directory name.

#### Project READMEs

To further enhance organization, each project/story directory can optionally contain a `README.md` file that provides context about the project/story.

This file can include:
- Project/Story description
- Goals and objectives
- Key milestones
- Links to related resources

This allows users to have a quick reference for each project/story directly within the workspace structure.

Tool implementors can leverage these README files to provide additional context in their interfaces, enhancing the user experience.

## Recurring Action Instances

Recurring actions store their PlannedAct instances in dedicated files alongside their templates.

### File Convention

For each `*.actions` file containing recurring action templates, a corresponding `*.recurring.actions` file holds the instances:

- `$workspace/work.actions` → `$workspace/work.recurring.actions`
- `$workspace/personal/next.actions` → `$workspace/personal/next.recurring.actions`

### File Structure

Instance files contain PlannedActs that reference their parent Plan:

```actions
[x] Weekly standup *abc123 @2026-01-14 %2026-01-14T09:15 #act-004
[ ] Weekly standup *abc123 @2026-01-21 #act-007
[ ] Weekly standup *abc123 @2026-01-28 #act-010
```

- `*abc123` references the parent Plan's UUID
- Instances are ordered chronologically (oldest to newest)
- Each instance has its own state, timestamps, and UUID

### History and Analytics

Instance files serve as the historical record for recurring actions:
- Past instances (completed/cancelled) remain in the file
- Query history by parsing the `.recurring.actions` files
- Analytics via graph queries or file parsing

For workflow details (completion, generation, template edits), see [Process](./process.md#recurring-actions).

## See Also

- [Configuration](./configuration.md) - XDG paths and config settings
- [Process](./process.md) - Workflow including recurring action behavior
- [Sync Architecture](./sync_architecture.md) - CRDT sync and state management
- [Action File Format](./action_file_format.md) - DSL syntax

