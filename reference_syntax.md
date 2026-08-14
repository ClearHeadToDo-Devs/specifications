# Reference Syntax for ClearHead Formats

Throughout this work we make liberal usage of id fields, whether that be within the DSL or within the markdown files that are used for the higher order structures.

However, in order to support multiple forms of identifiers, we support multiple reference formats.

## UUID

The first, and strongest reference is a full UUID.

now, within our system we generally do:

- UUIDv7 as a default
- UUIDv5 for actions that can deterministically be namespaced to a particular plan.

For programmatic structures, it is generally recommended to use the full UUID format for clarity and to have the least option for collisions, especially by two independent applications.

### short UUID

However, for user-facing references, we support a short UUID format that is _at least_ the first 4 characters of the UUID, as this is generally enough to avoid collisions within a single workspace, and is easy to read for humans when necessary.

When multiple UUIDs share a short prefix, the reference must include _as many characters as are needed to disambiguate_. Clients MUST accept prefixes longer than eight characters; an ambiguous prefix does not resolve by collection or file order.

## Alias

The second (and preferred) form of reference is by alias.

Aliases are short, human-readable identifiers. They are the primary way to reference charters and actions in day-to-day use.

In formats where the filesystem is used, a charter alias is often reflected in the file or directory name, again namespaced within the domain where it is kept. Action aliases are authored explicitly in the action DSL.

Plans do not currently have aliases. RFC 5545 provides `UID` for stable identity and `SUMMARY` for a mutable display name, but no standard alias property. Plans therefore use their UUID for ClearHead references; `SUMMARY` is not a reference. A distinct Plan alias would require an explicit extension property and is not part of the current format.

in this way, we can have clean aliases that are still easy to reference based on the work of the structures inside

#### On Paths

Sub-entities can use `/` to denote a sub path.

this way we can easily refer to subcharters, subplans, and even both in tandem if necessary while remaining readable.

for example if we have the following plan:

inbox.actions `[ ] something > [ ] sub`

we can refer to sub as `something/sub` and if this were to be referenced with the charter we could write: `inbox/something/sub` to make reference of aliases easier

this works because each element creates a new namespace so that two charters can have identical actions without being semantically different as their relationships distinguish them

##### Alternate separators

while the `/` separator is the default for paths, alternate separators can be used if necessary to avoid conflicts with aliases that may contain `/`. For example, `.` or `-` could be used as separators in such cases.

## Prefix Disambiguation

In ambiguous cases or for tooling, you can prefix a reference to force the target type:

- `c:<ref>` for charter
- `p:<ref>` for plan
- `a:<ref>` for act

Prefixes are optional but recommended when a segment could resolve to multiple types.

## Resolution Outcomes

Resolution failures have stable semantic categories so callers do not need to classify human-readable diagnostics:

- **empty** — no reference text was supplied;
- **invalid syntax** — a prefix has no value or the path has no segments;
- **not found** — the reference is valid but no entity matches in scope;
- **ambiguous** — multiple entities match at the strongest available tier;
- **type mismatch** — a typed path resolves, but to a different entity type.

Diagnostics may add contextual names and remediation. Programmatic consumers should branch on the category rather than parsing that text.

## Matching Rules

- Charters and actions match **aliases** or **UUIDs** only (full UUID or short UUID prefix).
- Plans match **UUIDs** only (full UUID or short UUID prefix).
- Matching precedence is **full UUID**, then **short UUID**, then **alias**, across the complete candidate set.
- Multiple matches at the strongest tier within a workspace are ambiguous and MUST NOT resolve by collection or file order.
- References are **case-insensitive** for aliases.
- **Titles, names, and Plan `SUMMARY` values are not used** for reference resolution.
- Action aliases are scoped by their containing path; UUIDs remain the strongest unambiguous form.
