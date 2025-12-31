# Naming Conventions for repositories
to one aspect that is orthogonal, but important to consider is the naming conventions and repo conventions when it comes to collections of action files.

In particular, we want to make it ergonomic to manage multiple "containers" whether you call them stories or projects, by leveraging the filesystem. 

## Workspace Structure
All action files/folders should be organized into a directory that conforms with the standards of the given operating system.

For example, in linux, this should be in `XDG_DATA_HOME` for data files (the action files themselves)
and `XDG_CONFIG_HOME` for configuration files (the settings for the action files).

### User Workspace Name
For the workspace name itself, we will look for `clearhead` at the root of the data/config directories. and all other directories will be subdirectories of this.

## Recurrence Logging (Optional)

For actions with recurrence rules, there are two complementary approaches to tracking completion:

### Template-Only Approach (Simplest)

The recurring action remains as a template in the main `.actions` file. The template defines the pattern but does not track individual occurrences.

**Example:**
```actions
[ ] Take out trash @2025-01-21T19:00 R:FREQ=WEEKLY;BYDAY=TU #trash-001
```

**Use case:** Simple reminders where historical tracking is not needed. The action serves as a reference that this needs to happen weekly.

### Template + Log Approach (For Analytics)

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
tasks/
├── inbox.actions              # Active recurring templates
├── projects.actions           # Project-specific templates
└── logs/
    ├── 2025-01.actions       # January completions
    ├── 2025-02.actions       # February completions
    └── ...
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

# Examples
As we have laid out above, we have quite an array of options when it comes to how much or how little information to give.

To give the most minimal example possible, we can see below:
`[ ] Test Action`

This hopefully serves to show that these should be able to be short, with the ability to read for a human without structured editing able to go through

## Robust Example
As we saw, many optional pieces of context can be added so here is an example of an action that has much more of these optional parameters:

```actions
[x] Go to the store for chicken
    $ Make sure you get the stuff from the butcher directly
    !1
    *Run Errands
+Driving,Store,Market
@2025-01-19T08:30D30
%2025-01-19T10:30
#214342414342413424
```

The succinct way to read this is that one had an action to go to the store on January 19th, 2025 as a part of their running errands project.
The action was expected to take 30 minutes but was completed in about two hours as we can see by the completion time.
Finally, it was part of the Driving, Store, and Market contexts and contains extra instructions on where to get the chicken

## Example with Links
Actions can include links to related resources:

```actions
[ ] Review pull request [[PR #456|https://github.com/org/repo/pull/456]]
    $ Check the implementation against [[API docs|https://api.example.com/v2/docs]]
    !2
    *Code Review
    +Work,Development
    @2025-01-26T14:00D45
    #a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

This action links to both a GitHub PR and API documentation within the description, making it easy to access relevant resources while keeping the file readable in plaintext


## Recurring Example
Here's an example of a recurring action with full metadata:

```actions
[ ] Weekly team meeting
    $ Discuss progress, blockers, and next steps
    !2
    *Team Coordination
    +Work,Meeting
    @2025-01-20T14:00 D60 R:FREQ=WEEKLY;BYDAY=MO
    #team-meeting-uuid
```

This defines a recurring weekly team meeting every Monday at 2pm for 60 minutes, with priority 2, associated with the "Team Coordination" project and tagged with Work and Meeting contexts.

When this template is expanded by an application, it generates occurrence instances. When occurrences are completed, they can be logged:

```actions
[x] Weekly team meeting @2025-01-20T14:00 %2025-01-20T14:05 #team-meeting-uuid-20250120
[x] Weekly team meeting @2025-01-27T14:00 %2025-01-27T14:10 #team-meeting-uuid-20250127
```

## Adding Children
Finally, we will do a showcase of the format for those actions with child actions:
```actions
[ ] Parent Action >[ ] Child Action
```

