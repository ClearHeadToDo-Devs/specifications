# Reference Syntax for ClearHead Formats
Throughout this work we make liberal usage of id fields, whether that be within the DSL, orwithin the markdown files that are used for the higher order structures.

However, in order to support multiple formats for identifiers we support multiple formats for these identifies

## UUID
The first, and strongest reference is a full UUID. 

now, within our system we generally do:
- UUIDv7 as a default
- UUIDv5 for planned acts that can deterministically be namespaced to a particular plan.

For programmatic structures, it is generally recommended to use the full UUID format for clarity and to have the least option for collisions, especially by two indpendent applications.

### short UUID
However, for user-facing references, we support a short UUID format that is the first 8 characters of the UUID, as this is generally enough to avoid collisions within a single workspace, and is easy to read for humans when necessary.

## Alias
The second (and preferred) form of reference is by alias.

Aliases are short, human-readable identifiers. They are the primary way to
reference charters and plans in day-to-day use.

in formats where the filesystem is used, this is often the name of the file or directory itself, again namespaced within the domain its kept within.

in this way, we can have clean aliases that are still easy to reference based on the work of the structures inside

#### On Paths

Sub-entities can use `/` to denote a sub path.

this way we can easily refer to subcharters, subplans, and even both in tandem if necessary while remaining readable.

for example if we have the following plan:

inbox.actions
`[ ] something > [ ] sub`

we can refer to sub as `something/sub` and if this were to be referenced with the charter we could write: `inbox/something/sub` to make reference of aliases easier

this works because each element creates a new namespace so that two charters can have identical actions without being semantically different as their relationships distinguish them

## Prefix Disambiguation
In ambiguous cases or for tooling, you can prefix a reference to force the target type:

- `c:<ref>` for charter
- `p:<ref>` for plan
- `a:<ref>` for act

Prefixes are optional but recommended when a segment could resolve to multiple types.

## Matching Rules
- References match **aliases** or **UUIDs** only (full UUID or short UUID prefix).
- References are **case-insensitive** for aliases.
- **Titles are not used** for reference resolution.
- Acts are referenced by UUID/short UUID only (since they are namespaced IDs).
