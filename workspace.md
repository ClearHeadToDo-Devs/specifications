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
├── archive/           ← closed history, as plaintext; mirrors charters/ layout
├── charters/          ← acts (.actions), markdown (.md), json sidecars
├── plans/             ← vdir calendars; one subdirectory per charter
├── objectives/        ← objectives live here
└── templates/         ← act templates live here
```

This scoping makes discovery trivial: implementors scan `charters/` for charter content and `plans/` for schedule data, without needing exclusion lists. The `archive/` region is a sibling of `charters/`, so it falls outside the default read for free, while staying plaintext and parseable when something needs to look into it.

By default, everyone should have a `charters/inbox.actions` file within that workspace. This file serves as the default location for uncategorized acts.

### Mutation durability and locking

Every ClearHead operation that writes more than one workspace file follows one concurrency policy:

1. acquire the workspace's exclusive OS lock at `<data_root>/.clearhead.lock`; fail on contention rather than continuing unlocked
2. while holding the lock, recover any journaled `.pending` batch before reading mutation inputs
3. stage every resulting file and commit the batch through the durability journal
4. release the lock only after commit completes

The lock file is persistent and contains the current owner's PID for diagnostics, but ownership is an OS file lock rather than the file's existence. The kernel releases ownership when a process exits or is killed, so stale PID text never blocks a later writer. Implementations must not delete the lock file on release because unlinking can allow two processes to lock different inodes for the same workspace.

Single-file writes use atomic temp-file replacement and do not require the multi-file journal. Readers that expose raw diagnostic state may report a pending journal without replaying it; mutation entry points must always recover it before planning from workspace state.

### Recovered source is quarantined from semantics

A relaxed parser may return a document containing recovery diagnostics so doctor, the linter, and editor tooling can explain malformed input. Such a document is not eligible for semantic workspace lowering: generic parser recovery can attach a later field or UUID to the wrong action. The affected action file is omitted from the domain model until it parses with clean integrity, while a structured finding remains visible. Formatting and mutation likewise require the clean source capability; they must never reserialize recovered actions. Sidecar orphan cleanup is also deferred while any action source is quarantined, because absence from the semantic model is not proof that its provenance is stale.

### Example

So if we go over the structure of the work we can see this as an example with a global and project workspace at the [examples directory][examples].

this shows both the project and user scope for examples of mixed layouts that would be representative of real world usage

### Objectives

Objectives are all located in an `objectives` directory within the workspace where all objectives of the file format: `<objective-alias>.md` - a markdown file containing the description of the objective, its purpose, and any other relevant information as per [the objective spec][objectives]

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

all closed charters are moved into the `archive/` region along with their children to keep a complete record — as their original plaintext files, not a serialized form

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

The configured `plans/` path is a charter-scoped iCalendar vdir containing recurring Plan masters and standalone Action projections.

Every constructed charter owns one calculated collection path even when its directory does not exist. This relative path is derived from the charter's canonical workspace anchor and is not written into charter Markdown or sidecars. A configured `plan_path` replaces only the physical vdir root. Calendar resources attach to charters by exact collection ownership, never by mutable alias or title matching.

Each `.ics` file contains a single `VCALENDAR` with one primary VTODO component: RRULE-bearing VTODOs are Plans and non-recurring VTODOs are Actions. Other iCalendar component types are outside the ClearHead projection. ClearHead-created files use the component UID as filename, while readers identify resources by UID because transport tooling may choose another filename.

This one-component-per-file vdir layout is directly compatible with tools such as vdirsyncer and does not assume a particular CalDAV server or any transport at all.

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

Multi-component `.ics` files are an import format, not a storage format. Implementations should provide an import path that splits them into individual resources within the target charter's `plans/` directory.

An immediate collection directory with no charter owner is invalid workspace state, not an alternate way to create a charter. Its resources are quarantined and mutations must not silently adopt them. Doctor should report the collection and may offer an explicit fix that removes it while warning that transport tools such as vdirsyncer can propagate the deletion.

Be sure to review [the reference syntax][reference-syntax] for guidance on working with sub charters and sub plans.

For recurring Plan, standalone Action, identity, and synchronization semantics, see the [ICS Schedule Spec][ics-schedule-spec].

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

When a charter is archived, its known files (`charters/<charter>.actions`, `.completed.actions`, `.upcoming.actions`, the charter `.md`, and its `.json` sidecar) and every other charter-local supporting file in a directory-form charter (notes, inventories, and future formats) are moved verbatim into the `archive/` region, at the path they held under `charters/`. Nothing is serialized: the archived form is the same plaintext, just relocated out of the default read set.

Charter stem derivation follows the same rules as plan name inference: `next.actions` uses the parent directory name; all other `.actions` files use the file stem. Unlike plan name inference, `inbox` is NOT skipped — `charters/inbox.actions` is valid.

## Concept Identity

Every concept in a workspace — the workspace itself, its charters, its plans, and its actions — carries a durable identity that survives renames, moves, and edits. Identity belongs to the *concept*, never to its file path or title, so a reference resolves to the same thing after the target is renamed, reordered, or moved (including into an archive).

One lifecycle governs all four:

> **mint or derive once → persist to the concept's anchor → read from persistence → `doctor` reconciles drift**

They differ only in *where* the identity is persisted:

| Concept   | Anchor                                             | Specified in |
|-----------|----------------------------------------------------|--------------|
| Workspace | `workspace_id` in `.clearhead/workspace.json`      | [Workspace Identity](#workspace-identity) |
| Charter   | frontmatter `id`, mirrored in the sidecar          | [Charters] |
| Plan      | recurring VTODO `UID` (canonical `.ics` filename)  | [ICS Schedule Spec] |
| Action    | inline id; standalone VTODO UID maps deterministically | [Action File Format], [ICS Schedule Spec] |

Two rules keep this honest:

- **Tool-managed, not typed.** Humans never write a UUID; `init`, the CLI, and the LSP mint and maintain them. "Invisible" means unobtrusive, not absent — a mutable action line carries its id quietly rather than re-deriving one on every read.
- **Derivation is a bootstrap, never a live recompute.** An identity may be *derived once* to fill a gap and then persisted as truth. Recomputing an id from mutable content — from a title, from a path — is forbidden: change the content and you silently change the identity, orphaning every reference to it. A broken reference must fail *loudly*, into a dangling id that `doctor` can report, rather than rebinding silently to a different concept.

### Actions carry their charter

An action may record its charter's id alongside its own, denormalizing the action→charter link so it survives independently of which file the action currently sits in. The embedded charter id is authoritative when present; the file's location is the fallback when it is absent. `doctor` reconciles the two on conflict.

## Named Graph Isolation

Each workspace maps 1-1 to an RDF named graph. This enables querying a single workspace in isolation or spanning multiple configured workspaces without data coalescing into a single undifferentiated graph. See [Decision 28][decision-28] for the rationale.

### Workspace Identity

A workspace's identity is its `workspace_id`, stored in its own `.clearhead/workspace.json` **manifest** — deliberately separate from `config.json`:

```json
{
  "workspace_id": "019e43e4-...",
  "workspace_name": "platform",
  "created_at": "2026-05-31"
}
```

The manifest and `config.json` are split because they are different in kind. `config.json` holds *behavior* — human-authored preferences that **layer** through the precedence chain (global → project → project.local → env → args). Identity is a tool-managed *fact* about one workspace that must **not** layer: a `workspace_id` in a global config, or a `CLEARHEAD_WORKSPACE_ID` env override, is meaningless. Keeping identity in a non-layered manifest keeps the config precedence rules honest. The manifest is near-static — it changes on `init` and rename, essentially never otherwise — and carries workspace-level facts only; per-charter, per-action, and per-plan metadata live in their co-located [sidecars](#sidecar-for-data), never here. See the [manifest schema][workspace-manifest-schema].

The named graph URI is derived from it as `urn:clearhead:workspace:<workspace_id>`.

`workspace_id` is assigned once by `clearhead init` and remains stable for the life of the workspace — it is the durable handle for the workspace's named graph, so any consumer that names the graph URI resolves it to the same workspace across sessions. It is never regenerated in normal operation.

That stability is a convenience, not a correctness requirement. A workspace without a `workspace_id` is fully queryable: the read side mints an **ephemeral** graph identity per load — distinct per workspace, never persisted, and never derived from the root path. Such a workspace answers queries correctly; its graph URI simply is not stable across sessions. `init` is how a workspace earns a durable URI — offered, never forced.

`workspace_name` is the display name used in multi-workspace output and cross-workspace reference syntax (`name:charter/action`). Inferred from the project directory name by `init`; can be overridden manually.

`created_at` records when the workspace was initialized. Informational only.

### Query Scope

Query scope is determined by the `additional_workspaces` configuration:

- **Single workspace (default):** Only the current workspace's named graph is loaded and queried.
- **Multi-workspace:** When `additional_workspaces` lists additional workspace paths, all of them are loaded into the same store alongside the current workspace — each in its own named graph. Queries span all loaded named graphs.

The scope is declared in config, not per-command. A user who configures additional workspaces intends cross-workspace visibility by default. This means the platform repository, which lists all submodule workspaces as `additional_workspaces`, queries across all of them without any additional flags.

### Initialization

`clearhead init` bootstraps a workspace:

1. Generates a UUIDv7 and writes `workspace_id`, `workspace_name`, `created_at` to `.clearhead/workspace.json` (skipped if `workspace_id` already present). If an older workspace still carries these fields in `.clearhead/config.json`, `init` and `doctor` migrate them into the manifest and drop them from `config.json`.
2. Creates the `charters/` directory structure and, for a project workspace, bootstraps the root charter as `charters/next.actions` with its identity in `charters/.next.json` (each skipped if already present). The root file is structural: it is the signal that lets flat named charters resolve as children of the project charter and keeps their plan-vdir slugs routable.

`init` is idempotent — rerunning it on an already-initialized workspace is safe and never overwrites existing data or identity. It may restore a missing root-charter scaffold. Pass `--force` to regenerate identity fields. This assigns a new graph URI, so any consumer that referenced the old one no longer resolves to this workspace; the workspace's plaintext data is untouched.

## Workflows

Now, its one thing to speak on the concrete file formats for each record type but the other piece to cover is the workflow that actually handled these various structures and dictates what happens when and where. for this, we are going to go a little more over the workflows that allow this format to be updated automatically or manually based on what people prefer

### Templates

Templates are a list of actions in the form of `<name>.actions` files that are stored in a `templates/` directory at the root of the workspace. these are meant to be used as templates for generating actions either through schedules or on demand.

it is assumed that the filename will be the reference for the template, so if we have a `weekly-review.actions` file in the `templates/` directory, then the reference for that template will be `weekly-review` and this is what will be used in the recurring VTODO DESCRIPTION field as `template: weekly-review` (first line of the task notes in a compatible calendar app)

this will also allow for on demand generation of actions either as a side-effect to charter creation or through a command like `apply template` which will allow users to generate actions from templates on demand without needing to wait for the schedule to trigger them

### Archival

One concept that is very important to the workspace format is the process of "archiving" things. weve covered the names above but its working from a reference point lets go from the beginning

1. At the lowest level, we have the actions that are implementations of their optional parent plans.
1. at first, these are all open, then as the user is closing the actions, they move from `<charter>.actions` to `<charter>.completed.actions` in order to remove clutter and make the process of tracking closed actions easier for both humans and databases to comprehend, this way open act queries can be fast, but full history searches are still possible
1. If we move a level up, we have the plans in `plans/<charter-name>/`, again, all plans start open but schedules simply "are no longer scheduled" they have no state explicitly however they are still logged as an example of a schedule
1. Finally, like plans, the charters themselves at `charters/<charter>.md` can be archived after they are closed. Archival is a **move, not a translation**: the archived form is data, not a projection, so no Turtle or JSON-LD is written. Any RDF view of archived data is regenerated on read by the graph binary, exactly like live data.
1. archiving a parent charter archives its whole subtree as one unit; the open-actions precondition is recursive too — it refuses if *any* descendant still holds open actions
1. the subtree's known files (`.actions`, `.completed.actions`, `.upcoming.actions`, the charter `.md`, and its `.json` sidecar) plus all supporting files owned by directory-form charters are moved **all-or-none** into the `archive/` region, preserving their path under `charters/` so the subtree's internal structure survives. The sidecar moves *with* the files rather than folding its `created_at` / `external_schedule_id` into the lines; atomicity (via the batch transaction, journalled in `charters/`) is what makes that safe — there is no half-archived state that orphans metadata
1. any charter subdirectory left empty by the move is collapsed

Because `archive/` is a sibling of `charters/`, the moved files leave the default read set automatically, but reference resolution can still look into them: an archived `<` target resolves to one of three states — **satisfied** (target Completed), **abandoned** (target Cancelled), or **dangling** (resolves nowhere). Keeping archives as readable plaintext is the whole reason that three-way signal is possible.

The `.ics` files in `plans/<charter-name>/` are **not** touched by archival. Per [decision 31][decisions], the configured vdir is a shared projection boundary and archival must not infer that its resources should be deleted. Archived Action records retain history while the vdir remains independently manageable through calendar tooling. A collection left without a live charter owner is quarantined and reported by doctor; it is never silently adopted as an implicit charter.

REMEMBER, per the [process spec][process] it is assumed that all child plans are completed/cancelled which is why the open files above are expected to be empty or atleast emptyable before being moved into `archive/`

this is how we maintain a format that is able to evolve gracefully

## See Also

- [Action File Format] — DSL syntax
- [Charters] — Charter structure and frontmatter
- [Configuration] — XDG paths and config settings
- [ICS Schedule Spec] — VTODO projection, synchronization, and schedule semantics
- [Ontology] — Domain model and RDF contract
- [Process] — Workflow including recurring action behavior
- [Reference Syntax] — Sub-charter and sub-plan references

[action-file-format]: ./action_file_format.md [charter-sidecar-schema]: ./schemas/charter_metadata.schema.json [charters]: ./charters.md [configuration]: ./configuration.md [decision-28]: ../DECISIONS.md [decisions]: ../DECISIONS.md [examples]: ./examples/workspaces/ [ics-schedule-spec]: ./ics_schedule_spec.md [objectives]: ./objectives.md [ontology]: ./ontology.md [process]: ./process.md [reference-syntax]: ./reference_syntax.md [workspace-manifest-schema]: ./schemas/workspace.schema.json
