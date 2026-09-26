# Charter Documentation

Charters are the primary way that we organize plans within the platform. they are prose markdown documents that leverage combination of frontmatter and content to give users a way to organize plans and actions around a particular domain of concern.

## Frontmatter

for the purposes of organization and reading, frontmatter allows charters to contain some important metadata, while still remaining largely a prose document for human consumption

in this structure, we are primarily concerned with what is needed to give this structure meaning within the platform and link it with other parsed works meaning we have:

- id: a unique UUIDv7 for the charter that can be linked (optional in the file: a document without one still loads with an ephemeral identity and `doctor` reports it; see Concept Identity in [workspace.md](workspace.md))

this is the only required field for now if a charter DOES exist within the platform that will be used

The workspace root charter is no exception: its frontmatter lives in `charters/README.md`. See [The Root Charter](./workspace.md#the-root-charter).

### Optional Frontmatter

- title: a human readable title for the charter, this is optional because it can be derived
- alias: an aptional-short name for the charter that can be used for reference
  - aliases are scoped within the namespace of their parent charter
- parent: the reference of the parent charter, this allows for nesting charters within charters, and is optional because not all charters need to be nested
  - parents must be denoted with either the reference syntax or through the UUID of the parent
    - however this model is SECONDARY to the model outlined in things like the naming conventions
  - **Note:** in a file-based workspace you almost never need this field — directory placement is the primary and preferred way to express charter hierarchy (see [workspace.md](./workspace.md)). This field exists for non-filesystem contexts or genuinely disconnected structures where placement cannot express the relationship.
- objectives: a list of references to objectives within the platform that this works in servie of
- state: the Charter's locally asserted lifecycle state:
  - `New` — defined but not admitted for engagement
  - `Active` — locally eligible for engagement
  - `Blocked` — unable to advance
  - `Closed` — finished and terminal
  - `Cancelled` — abandoned and terminal
- defaults: any settings that shoud be applied to all descendants of the charter. primarily good for controlling structure and making consistent actions more alike. primarily done by setting key value pairs within the defaults dictionary.

When `state` is omitted, semantic projections must expose it as `New`; omission
must not be interpreted as `Active`. Effective engagement also requires every
ancestor Charter to be `Active`. This inherited eligibility is derived and never
rewrites the local state.

A Charter known only through its actions, with no document, is likewise `New`,
and so is every newly created Charter. `New` is the planning state: creating a
Charter does not mean its work is ready, and it usually needs more planning
before it is. Activation is therefore always an explicit, requested transition.
No operation that creates or edits a Charter's document may change its state as
a side effect, and a document created for an existing Charter declares `New`
unless that transition was requested. Because a `New` Charter's open actions are
invisible to engagement, implementations should report a `New` Charter that owns
open actions.

Other states are permissible, but these are the minimum states Charter
implementations must support. State transitions do not implicitly cascade to
descendant Charters or Actions. The normative admission, readiness, transition,
and contradiction rules are defined in [Process Overview](./process.md#charters).

`Closed` and `Cancelled` are both terminal states: either makes a Charter
eligible for archival (see [Archive](./Archive)).

## Content

For the purpose of the content, charters only need a single header and content below it

```md
# Example Charter Title
with some description text
```

in this way, the first header serves as the title and the content serves as the description

even the description is optional, as the title is the only required content for a charter to be valid, but the description can be used to give more context about the charter and its purpose

Another option is the use of the title property:

```md
---
title: charter example
---
here is a small charter description
```

This mirrors common linter conventions for markdown

### Extra Sections

All subsections are included in the description while sibling sections are meant to be seen as extra content that can represent whatever is needed but will be saved separately when archived

## charter logs

charters may also have a log section beneath the core section and this will be assumed to be a log of various events and changes that happened within the charter.

good for keeping a running log if semantic activity

### format

Each log entry is a single item of an unordered list that begins with an ISO 8601 date or date-time, followed by ` — ` and the entry text. The entry carries its own date so it keeps its meaning when it is moved, archived, or read on its own; entries are appended, so their order in the document is their order in time.

A date-time should carry its UTC offset (`2026-09-17T23:28-07:00`), since entries from different machines share one log and must order correctly; tools that write entries always include it. Editors may render the timestamp in a friendlier form, but the stored text stays ISO 8601.

An entry without a leading date is still valid and is read as undated text. Linters should report it, but implementations must not add a date to an existing entry: the time of that edit is not the time the entry was written.

example

```md
# test

test charter

## Log

- 2026-09-17 — log line 1
- 2026-09-17T23:28-07:00 — log line 2
```
