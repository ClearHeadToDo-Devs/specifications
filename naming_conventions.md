# Naming Conventions for repositories

to one aspect that is orthogonal, but important to consider is the naming conventions and repo conventions when it comes to collections of action files.

In particular, we want to make it ergonomic to manage multiple "containers" whether you call them stories or projects, by leveraging the filesystem. 

while the [file specification](./action_specification.md) defines how individual action files are structured, this specification defines how those files should be organized and named within a workspace.

They are separate, because different implementors may choose to work with the format, but choose to avoid these conventions which is fine, this way implementors can absorb specifications a-la-carte and take on the complexity they want to consider

## Workspace Structure

All action files/folders should be organized into a directory that conforms with the standards of the given operating system.

For example, in linux, this should be in `XDG_DATA_HOME` for data files (the action files themselves)
    and `XDG_CONFIG_HOME` for configuration files (the settings for the action files).

### User Workspace Name
    For the workspace name itself, we will look for `clearhead` at the root of the data/config directories. and all other directories will be subdirectories of this.

    We shall hereafter refer to this as `$workspace` for the sake of file paths for structuring our work

#### Core Files

    We have a few key files that all implementors can look for:

    - `$workspace/inbox.actions` - The main inbox file for capturing new actions and should be, as the name implies, the default location for new actions to be added.
    - `<project>/next.actions` - The next actions file for a given project/story
    - placing the action file within the project/story directory allows for easy organization of related actions
    - this file IS intended to be seen! as it is intended to be the main working file for that project/story
    - `<project>/local.next.actions` - An optional, personal ovverride file for next actions within a project/story
    - this file is intended to be ignored by version control and allows for personal task management without affecting the shared project/story file
    - `$workspace/completed.actions` - A global completed actions log file
        - this file is intended to be an append-only log of all completed actions across all projects

### Project/Story Naming

    While the action specification allows for stories/projects to be defined within the files themselves, it can often feel natural to break these files into separate files/folders for organization.

    To this end, we support the following conventions, with the assumption implementors will leverage these structures to provide better user experiences.
    - `$workspace/<project-name>.actions` - A file containing actions for a specific project/story
        - Any actions within this file are assumed to have the story/project of the file name unless otherwise specified within the action itself.
    - `$workspace/<project-name>/next.actions` - A directory containing a project/story with its own next actions file
        - This allows for sub-projects through the combination of directories and files.

#### Sub-Projects
    To support sub-projects, we allow for directories within the workspace to represent projects/stories, with their own action files.

    For example:
    ```
    $workspace/
    ├── ProjectA/
    │   ├── next.actions
    |   |-- subProjectB.actions
    │   └── SubProjectA/
    │       └── next.actions
    └── ProjectB.actions
    ```

    In this structure:
    - `ProjectA` is a project with its own `next.actions` file.
    - `SubProjectA1` is a sub-project of `ProjectA`, also with its own `next.actions` file.
    - `ProjectB.actions` is a standalone project file.
    - `subProjectB.actions` is a file within `ProjectA` that can contain actions specific to that sub-project.

In this way, users can grow their actions workspace organically, organizing projects and sub-projects in a way that makes sense for their workflow, leaving room for implementors to build tools that can navigate and manage these structures effectively.

##### Project READMEs
    To further enhance organization, each project/story directory can optionally contain a `README.md` file that provides context about the project/story.

    This file can include:
    - Project/Story description
    - Goals and objectives
    - Key milestones
    - Links to related resources

    This allows users to have a quick reference for each project/story directly within the workspace structure.

    Tool implementors can leverage these README files to provide additional context in their interfaces, enhancing the user experience.
# Recurrence Logging (Optional)

    For actions with recurrence rules, there are two complementary approaches to tracking completion:

## Template-Only Approach (Simplest)

    The recurring action remains as a template in the main `.actions` file. The template defines the pattern but does not track individual occurrences.

    **Example:**
    ```actions
    [ ] Take out trash @2025-01-21T19:00 R:FREQ=WEEKLY;BYDAY=TU #trash-001
    ```

    **Use case:** Simple reminders where historical tracking is not needed. The action serves as a reference that this needs to happen weekly.

## Template + Log Approach (For Analytics)

    The template remains in the main `.actions` file unchanged, while completed occurrences are logged in separate files. This enables historical tracking, metrics, and analytics while keeping templates stable.

    **Template file (inbox.actions):**
        ```actions
           [ ] Take out trash @2025-01-21T19:00 R:FREQ=WEEKLY;BYDAY=TU #trash-001
           [ ] Daily standup @2025-01-20T09:00 R:FREQ=DAILY;BYDAY=MO,TU,WE,TH,FR #standup-001
           ```

           **Log file (logs/2025-01.actions):**
               ```actions
                  [x] Take out trash @2025-01-07T19:00 %2025-01-07T19:15 #trash-001-20250107
                  [x] Take out trash @2025-01-14T19:00 %2025-01-14T19:32 #trash-001-20250114
                  [x] Take out trash @2025-01-21T19:00 %2025-01-21T18:45 #trash-001-20250121
                  [x] Daily standup @2025-01-20T09:00 %2025-01-20T09:05 #standup-001-20250120
                  ```

    **Log Entry Format:**
    - State is typically `[x]` (completed) or `[_]` (cancelled)
- `@datetime` is the **scheduled** occurrence time (from the template expansion)
    - `%datetime` is the **actual** completion time
    - UUID links to template: `{template-uuid}-{occurrence-date-YYYYMMDD}`
- **No recurrence rule** in log entries (they are concrete instances, not templates)

    **File Organization Convention:**
    ```
    clearhead/
    ├── inbox.actions              # Active recurring templates
    └── logs/
    ├── 2025-01.actions       # January completions
    ├── 2025-02.actions       # February completions
    ```

    **Benefits:**
    - **Immutable templates** - Source of truth never changes due to completion
    - **Full history** - Complete record of what was done and when
    - **Metrics** - Track completion rates, timing variance, streaks, etc.
    - **Editor-friendly** - Manual users can append to log files by hand
    - **Application-friendly** - CLI/GUI tools can query logs for analytics
    - **No lock-in** - All data remains in plain text `.actions` format

    **Implementation Notes:**
    - Applications should expand templates to show upcoming occurrences
    - On completion, applications append to log file for that month
    - Log files use standard `.actions` format and can be queried with same tools
    - Manual users can maintain logs by copying template and adding completion date
    - Templates without UUIDs can generate them: `uuidgen` or application auto-assignment

