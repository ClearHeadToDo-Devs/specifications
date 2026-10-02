# Objective File specification
Objectives, like [charters](./charters.md), are a core domain object that represent the desired outcomes that plans and actions serve. They are the "why" behind the "what" of plans and actions.

Like charters, they use frontmatter to determine data, and content to give a prose explanation of the object itself

## Frontmatter
The frontmatter for objectives is relatively simple, as the only required field is the `id`, which is a UUIDv7 that can be used to link this objective with other objects within the platform. An objective file without an `id` is reported and not loaded; nothing mints one for it on read.

### Optional Frontmatter
- `title`: a human readable title for the objective, this is optional because it can be
  - however this will generally be the header instead
- `alias`: an optional short name for the objective that can be used for reference
  - otherwise the objective is named by its file: `<name>.md` is `<name>`, and a directory-form `<name>/README.md` is `<name>`
  - the root objective, `objectives/README.md`, has no file name to fall back on: its name is the workspace's `workspace_name`, which a frontmatter `alias` overrides
- `parent`: the reference of the parent objective, this allows for nesting objectives within objectives, and is optional because not all objectives need to be nested

these serve the [reference syntax](./reference_syntax.md) for objectives: a charter's `objectives` entries name an objective by its alias or its id, as charter `parent` references do. Titles are for display and are never matched, since they change.

## The Root Objective

Every workspace has one root objective, `objectives/README.md`, as it has one root charter, `charters/README.md`: what the whole workspace is for. A plan without an objective is not yet a plan, so the root charter names the root objective in its `objectives`. `clearhead init` creates both, writing the objective's `alias` from `workspace_name` so that renaming the workspace later cannot rename the objective out from under the charters that name it, and the root charter's `objectives` naming it (see [Initialization](./workspace.md#initialization)). In a workspace that predates this, `doctor` reports any charter that names no objective; loading never refuses one.

#### Metrics
For objectives that have a measurable outcome, we can also include a `metrics` field in the frontmatter that contains a list of metrics to be measured including:
- `name`: the name of the metric, this is required for the metric to be valid
- `description`: a description of the metric, this is optional but can be used to give
- `target`: the target value for the metric, this is optional but can be used to give a clear goal for the metric
- `review_date`: the date by which the metric should be reviewed, this is optional but can be used to give a clear timeline for the metric

these small metrics allow for measurable objectives that can be later linked to data systems that track the actual data for runtime calculations of steps

## Content
For the purposes of parsing, the first H1 header is assumed to be the title of the objective, and the content below it is assumed to be the description of the objective. 

```md
# Example Objective Title
with some description text
``` 

this is a simple objective with the title "Example Objective Title" and the description "with some description text"


