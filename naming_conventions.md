# Naming Conventions for repositories

to one aspect that is orthogonal, but important to consider is the naming conventions and repo conventions when it comes to collections of action files.

In particular, we want to make it ergonomic to manage multiple "containers" whether you call them stories or projects, by leveraging the filesystem. 

while the [file specification](./action_specification.md) defines how individual action files are structured, this specification defines how those files should be organized and named within a workspace.

They are separate, because different implementors may choose to work with the format, but choose to avoid these conventions which is fine, this way implementors can absorb specifications a-la-carte and take on the complexity they want to consider

## Workspace Structure

All action files/folders should be organized into a directory that conforms with the standards of the given operating system or follows a project-local structure.

### Global Workspace
For global management, action files reside in standard system locations (e.g., `XDG_DATA_HOME/clearhead` on Linux).

### Project-Local Workspace
For project-specific management, a directory may be designated as a workspace by the presence of a `.clearhead/` directory or a `next.actions` file at its root.

#### The `.clearhead/` Directory
Similar to `.git/`, a `.clearhead/` directory at the project root signals that the project is managed by the ClearHead system.
- `.clearhead/inbox.actions` - Project-specific inbox.
- `.clearhead/config.json` - Project-specific configuration (overrides global).
- `.clearhead/logs/` - Project-specific completion logs.

#### The `next.actions` File
A `next.actions` file at the root of a directory is a "first-class" project entry point. It allows for lightweight task management without the overhead of a full `.clearhead/` folder.

## Discovery Protocol

Implementors (CLI, LSP, etc.) should resolve the active workspace and default action file using the following precedence:

1.  **Explicit File**: Path provided via command-line argument (e.g., `clearhead_cli read my_tasks.actions`).
2.  **Project Root File**: Search upwards from the current directory for a `next.actions` file.
3.  **Project Data Directory**: Search upwards from the current directory for a `.clearhead/` directory. If found, the default file is `.clearhead/inbox.actions`.
4.  **Global Workspace**: Fallback to the system-standard directory (e.g., `~/.local/share/clearhead_cli/inbox.actions`).

### Precedence Summary Table

| Input | Logic | Default File |
| :--- | :--- | :--- |
| `clearhead_cli read <file>` | Explicit | `<file>` |
| Current dir has `next.actions` | Local Root | `./next.actions` |
| Current dir has `.clearhead/` | Local Data | `./.clearhead/inbox.actions` |
| Parent dir has `next.actions` | Upward Root | `../next.actions` |
| None of the above | Global | `~/.local/share/clearhead_cli/inbox.actions` |

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

