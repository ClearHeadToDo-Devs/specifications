# Objective File specification
Objectives, like [charters](./charters.md), are a core domain object that represent the desired outcomes that plans and actions serve. They are the "why" behind the "what" of plans and actions.

Like charters, they use frontmatter to determine data, and content to give a prose explanation of the object itself

## Frontmatter
The frontmatter for objectives is relatively simple, as the only required field is the `id`, which is a UUIDv7 that can be used to link this objective with other objects within the platform.

### Optional Frontmatter
- `title`: a human readable title for the objective, this is optional because it can be
  - however this will generally be the header instead
- `alias`: an optional short name for the objective that can be used for reference
  - otherwise, the name of the file assumed to be the objective name
- `parent`: the reference of the parent objective, this allows for nesting objectives within objectives, and is optional because not all objectives need to be nested

these serve the [reference syntax](./reference_syntax.md) for objectives, with the alias being the most human readable, then the title, then the id being the strongest reference

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


