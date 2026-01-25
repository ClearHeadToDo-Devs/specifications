---
title: plans file specification
description: File Specification for the plans filetype
author: primary_desktop
categories: Reference
created: 2025-01-19T03:16:49-0800
updated: 2025-01-20T00:04:29-0800
version: 1.1.1
---
This specification will lay out the formal specifications for the `plans` filetype, usually denoted by a `*.actions` file.

# High-Level Guidelines
This specification will attempt to maintain backwards compatibility. That is, we will only add backwards-compatible changes to prevent implement's from dealing with breaking changes in the specification.

this means that there are currently no plans to add a top-level 'version' structure as we want to make sure that an plan list made today will still be parsable 10 years from now, even if there are new features that have been added in that time.

## Ontological Backing
This filetype is intended to represent a human-readable interface into data that will ultimately conform to the [Ontology](./ontology.md) defined for ClearHead

In particular the three core entities we are thinking about are:
- Objectives (placed in where people usually think of s/objectives)
- Plans: These are the ACTUAL atomic units of work we are listing here so its more succinct to think of these as a list of plans
  - for the purposes of this specification, plan = plan wherever it is mentioned
- Planned Acts: All plans have atleast one planned act as these are the parts that have actual state and are meant to be planable
  - This is primarily relevant when it comes to recurring plans as each occurrence is a planned act

This filetype does the best it can to represent all of these entities in one succinct format to allow people to easily read and write these plans in any plaintext editor of their choosing

the way to see it is that actions are a way to abstract away the complexity of the ontology into a simple list of plans that can be easily read and written by humans in that `todo.txt` style format

## plaintext implications
Fundamentally, the `actions` filetype is a list of Plans that can be formally parsed in a machine-readable way while still being readable and writable with any application the user chooses
As such, great care is taken to minimize the amount of characters that need to be typed by a human, while being considerate to readability of the core file

Special considerations should be made to the readable nature of the document, and how this can result in design decisions that would not normally be taken within a database.
For example, the name should be considered a secondary key for the plan. While we will have an ID that will ensure universal uniqueness, the plaintext nature of this solution lends itself to using the name as a natural key

We give many forms of reference as we want to make sure that users have many ways for one plan to refer to another plan without needing to remember a long UUID

This could result in a situation where other filetypes are using the name of the plan rather than the id to identify it

As such, one should be considerate about creating default names for plans as this could lead to name collision within the implementation, and should instead use some form of pattern to create new plan automatically without having name collision (maybe default to UUID of plan?)

## Parser Guidance
With that said, it is also a use-case that these files are able to be read by a formal parser to allow for data extrplan and the potential for placing these pieces of data into a schema

Finally, in terms of rules-processing, we take the approach of newer markdown formats like neorg which deemphasize the importance of whitespace to denote depth.
Instead, we use explicit characters or a sequence of characters to make the act of parsing this work cleaner

### Special Characters

Due to the nature of the format, special characters will need to be escaped with the `\` character in any fields where freeform text is allowed unless otherwise noted.

The list of special characters that need to be escaped are below:
- `$` - Reserved for Descriptions
- `!` - Reserved for Priority
- `*` - Reserved for objectives/s
- `+` - Reserved for contexts
- `@` - Reserved for Do-Date-Time
- `%` - Reserved for Completed Date
- `<` - Reserved for Predecessors
- `>` - Reserved for Children
- `=` - Reserved for Aliases
- `~` - Reserved for Sequential Children marker
- `^` - Reserved for Created Date
- `#` - Reserved for ID
- `[` `]` - Reserved for State markers and Links (when used as `[[link]]`)
- `|` - Reserved for Link separator (when within `[[...]]`)

### Reference Styles

other things may need to be referenced in multiple places so such as predecessors.

they go from _most stable_ to _least stable_ but also from _least human friendly_ to _most human friendly_

#### Full UUID
The most specific reference - matches exactly one plan:
```actions
[ ] Task B < 01951111-cfa6-718d-b303-d7107f4005b3
```

#### Short UUID
The first 8 characters of a UUID provide a "good enough" reference that's both specific and human-friendly:
```actions
[ ] Task B < 01951111
```

Short UUIDs are resolved by prefix match. If multiple UUIDs share the same 8-character prefix (extremely rare), a linting warning (W009) suggests using the full UUID.

#### Alias Reference
plans with defined aliases can be referenced by that alias:
```actions
[ ] Run integration tests < staging-deploy
```

See [Alias](#alias-optional) for how to define aliases.

#### plan Name
Case-insensitive name matching within the workspace:
```actions
[ ] Dry clothes < Wash clothes
```

If multiple plans match the name, a linting warning (W009) suggests using a UUID or alias for clarity.


### Resolution Order

Predecessors are resolved within the workspace scope (all `.actions` files under the workspace root):
1. **Full UUID match** - If the reference is 36 characters with hyphens, match against plan IDs
2. **Short UUID match** - If the reference is exactly 8 hex characters, match against UUID prefixes
3. **Alias match** - Case-insensitive match against defined aliases
4. **Name match** - Case-insensitive match against plan names

If no match is found, a linting warning (W008) reports the invalid reference. At parse time, resolved references are converted to UUIDs for internal storage.

## Dates, times, and repititions
we make repeated use of date formats in this file type.

we primarily follow the [icalendar standard](https://en.wikipedia.org/wiki/ICalendar) as these can be seen as specialized calendar events and a core usecase is the integration with calendar apps
dates, times, and durations will be written using the [ISO 8601 Date Standard](https://en.wikipedia.org/wiki/ISO_8601) 

this makes reading dates consistent and easily parsable by nearly any language while also aligning to the notation most expected by the international community 

while only some will take advantage of the extended functionality, they will all share the same base of the ISO 8601 standard
### Date Structure
As denoted, each file can be understood as a list of plans that the person intends to take.

ordering matters here so each part is intended to be done in sequence to again make the act of parsing easier and minimizing the amount of characters that need to be escaped within the main text chunks

both formats should be supported:
- YYYY-MM-DD
- YYYYMMDD

weekly formats should also be supported in cases where the ability for ambiguity is required (like do date)
- YYYY-www
- YYYYwww

ordinal dates are on a per-parser bases. for the time being, there is no need to support this unless there are requests for more generic date representations in specific parsing scenarios
#### Time
Time is denoted with the `T` character after the date and supports both extended and simplified formats:
- full
    - hh:mm:ss.sss
    - hhmmss.sss
- seconds
    - hh:mm:ss
    - hhmmss
- minutes
    - hh:mm
    - hhmm
- hour
    - hh
    - hh

if in an unambiguous context (like a child of an plan due on a specific day) then simply listing the time should be sufficient, without the requirement of even a date

However, do note this will be implementation specific and will require more opinionated configuration than would otherwise be feasible for this work

remember, `00:00:00` denotes the INSTANT a day begins from a calculation perspective and can serve as a good default when needed for a time structure in more strictly typed languages

##### Timezones
Timezones are optional. if omited, local time is assumed as the standard suggests.

However, we should also note that the UTC offsets are accepted for the possibility of international parsing
- <time>Z (zero UTC offset)
- <time>+/-hh:mm
- <time>+/-hhmm
- <time>+/-hh

#### Durations
While a single day-time is the representation of a single time, we also want the ability to easily respresent the DURATION of this time

ISO 8601 covers this with the `P` designator

and has the following format:
- `P[n]Y[n]M[n]DT[n]H[n]M[n]S`
    - like the date format, each designator is preceded by the number of that period
    - durations that dont need a specific signifier, can simply omit it 
        - Full example: `P1Y2M3DT4H5M6S` is: 1 year, 2 Months, 3 Days, 4 Hours, 5 Minutes and 6 Seconds
        - pragmatic date example: `P1M` is: 1 Month
        - pragmatic hour example: `PT5M` is: 5 Minutes
            - note the `T` designator to disambiguate between the `M` for Month and Minutes respectively
- `P<date>T<time>`
    - This format is similar to the first, but instead simply uses a similar format as above to denote the duration
        - do note, standard logic applies, one cannot do an end time that would end up being 25 hours etc
            - full example: `P0001-02-03T04-05-06` is 1 year, 2 Months, 3 Days, 4 Hours, 5 Minutes and 6 Seconds just like above
##### Time Intervals
Therefore, we have a few formats for when we have to designate a duration AND a date
- `<start>/<end>`
- `<start>/<duration>`
- `<duration>/<end>`

While you CAN simply list a duration on its own, again, given the context enables it. 

However, great care must be taken to handle the inherent ambiguity around durations alone (if we say 2 months, that could be 28,29,30, or 31 days)

By contrast, if we put the duration after a proper date, then there is no ambiguity as we can calculate two months from that specific starting date rather than an arbitrary starting date

same goes for time and seconds due to leap seconds

### Recurrence
plans can repeat on a schedule using the RRULE (Recurrence Rule) syntax from [RFC 5545 section 3.3.10](https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.10).

Recurrence is denoted with the `R:` prefix followed by standard RRULE syntax. The do-date/time serves as the DTSTART (start date) for the recurrence rule.

When exported to calendar applications, this generates a recurrence set - the complete set of occurrences based on the rule.

#### RRULE Syntax

The RRULE format uses key-value pairs separated by semicolons:
```
R:FREQ=frequency[;RULE_PART=value]...
```

**Required Component:**
- `FREQ` - The recurrence frequency. Must be one of:
  - `SECONDLY` - Every second (rarely used)
  - `MINUTELY` - Every minute
  - `HOURLY` - Every hour
  - `DAILY` - Every day
  - `WEEKLY` - Every week
  - `MONTHLY` - Every month
  - `YEARLY` - Every year

**Optional Components:**
- `INTERVAL=n` - Repeat every n intervals (default: 1)
  - Example: `FREQ=DAILY;INTERVAL=2` means every other day
- `COUNT=n` - Maximum number of occurrences
  - Example: `FREQ=WEEKLY;COUNT=10` means 10 weekly occurrences
- `UNTIL=datetime` - End date/time for recurrence (ISO 8601 format)
  - Example: `FREQ=DAILY;UNTIL=20251231T235959`
  - Note: `COUNT` and `UNTIL` are mutually exclusive
- `BYDAY=days` - Days of week (MO,TU,WE,TH,FR,SA,SU)
  - Example: `FREQ=WEEKLY;BYDAY=MO,WE,FR` means every Monday, Wednesday, Friday
  - Can include numeric prefix: `+1MO` (first Monday), `-1FR` (last Friday)
- `BYMONTHDAY=days` - Days of month (1-31, or -1 to -31 for counting from end)
  - Example: `FREQ=MONTHLY;BYMONTHDAY=1,15` means 1st and 15th of each month
- `BYMONTH=months` - Months of year (1-12)
  - Example: `FREQ=YEARLY;BYMONTH=1,7` means January and July each year
- `BYHOUR=hours` - Hours of day (0-23)
- `BYMINUTE=minutes` - Minutes of hour (0-59)
- `BYSECOND=seconds` - Seconds of minute (0-59)
- `BYSETPOS=n` - Limits to nth occurrence in period
  - Example: `FREQ=MONTHLY;BYDAY=MO;BYSETPOS=1` means first Monday of each month

#### Common Recurrence Patterns

**Daily Examples:**
- `R:FREQ=DAILY` - Every day
- `R:FREQ=DAILY;INTERVAL=2` - Every other day
- `R:FREQ=DAILY;BYDAY=MO,TU,WE,TH,FR` - Every weekday
- `R:FREQ=DAILY;COUNT=30` - Daily for 30 days

**Weekly Examples:**
- `R:FREQ=WEEKLY` - Every week on the same day as DTSTART
- `R:FREQ=WEEKLY;BYDAY=MO,WE,FR` - Every Monday, Wednesday, Friday
- `R:FREQ=WEEKLY;INTERVAL=2;BYDAY=TU` - Every other Tuesday
- `R:FREQ=WEEKLY;BYDAY=SA,SU` - Every weekend

**Monthly Examples:**
- `R:FREQ=MONTHLY` - Same day each month
- `R:FREQ=MONTHLY;BYMONTHDAY=1` - First of every month
- `R:FREQ=MONTHLY;BYDAY=2FR` - Second Friday of each month
- `R:FREQ=MONTHLY;BYMONTHDAY=-1` - Last day of each month

**Yearly Examples:**
- `R:FREQ=YEARLY` - Same date every year
- `R:FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1` - January 1st every year
- `R:FREQ=YEARLY;BYMONTH=11;BYDAY=4TH` - Fourth Thursday in November (US Thanksgiving)

#### Design Rationale

This specification uses RFC 5545 RRULE syntax directly rather than inventing custom shorthand for several reasons:

1. **Battle-tested standard** - RRULE handles edge cases (leap years, DST, invalid dates) that would be easy to miss in custom syntax
2. **Calendar compatibility** - Direct 1:1 mapping to iCalendar export format without translation layer
3. **Completeness** - Supports complex patterns (e.g., "last Friday of each quarter") without syntax extensions
4. **Tooling ecosystem** - Libraries like [rrule.js](https://github.com/jkbrzt/rrule) already parse and expand RRULE
5. **Unambiguous** - No corner cases where custom syntax behavior is undefined

While RRULE syntax is verbose, editor tooling can provide natural language interfaces that generate RRULE strings, keeping the file format precise while maintaining usability.
## Depth (Required)
Every child plan starts with atleast one `>` character. Children of a parent plan can be denoted by `>>` and so-on down to the official limit of 5 levels of depth. Now while nothing stops implementors from allowing arbitrary nesting, it should be assumed that 5 is the limit if there is indeed a limit.

6 levels was chosen to conform with standard markdown conventions

all other symbols will be valid for child plans, and parsing should still be easy since they will all be preceded by the progression of `>` characters

### Adding Children
Children plans should be added to the end of an plan to leave the context closer to the name of the plan. 
Children should be the last thing in the chain before the completion-date/Id

As such, child plans are encapsulated within the parent to make for easy parsing
styling around indentation is left up to the implementors, it should NOT be important to parsing the document

## State (Required)
We want to accomodate a few more states than done and not done, so we put the state between the `[` and `]` characters
The options for states are as follows:
- ` ` Not Started (default)
- `x` Completed
- `-` In-Progress (for work-in-progress limits)
- `=` Blocked/Awaiting
- `_` Cancelled (for historical systems)

This and the depth constitute the primary "marker" for the start of an plan, making both parsing and reading easier since you can easily scan for the beginning of the next plan visually on the screen


## Name (Required)
The final required field is the name of the plan itself. 


Otherwise, this is one of the more encompassing fields where users are allowed to write as much as they like, even newlines

however, do note the point above about using names as secondary keys so if something is going to be really long, save it for the description section below

### Description (optional)
This field is special as we want to allow for the user to use the full breadth of characters to enable descriptions to be much more expressive.

To this end, this is the only part of the specification that REQUIRES the special `$` character at the start of the line to denote that this is a description line AND the END of the description.

This means descriptions can use any character they need to within the confines of the description block.

like code blocks in other formats, we can designate an area that is free from the traditional rules around the format including being multiline since again, we DONT use whitespace as a meaningful part of the format

```actions
[ ] Cool Plan
    $ This is a description of the plan 
    special characters like ! @ # $ % ^ & * ( ) _ + - = { } [ ] | \ ; ' " : , . < > / ? can all be used here without needing to escape them
    $
```

### Links (optional inline syntax)
Links to external resources can be embedded within the name or description using wiki-style double-bracket syntax:

`[[link text|url]]`

- The link text is what will be displayed (human-readable)
- The url can be any valid URI (http, https, file, mailto, etc.)
- If only a URL is needed without custom text, use `[[url]]` as shorthand

**Examples:**
- `[[Documentation|https://example.com/docs]]`
- `[[https://example.com]]`
- `[[Bug Report|https://github.com/user/repo/issues/123]]`
- `[[Email support|mailto:help@example.com]]`

**Rationale:**
Because `[` and `]` are used for state markers at the start of plans, links use double-bracket `[[` syntax to avoid parsing ambiguity. The pipe `|` separator follows wiki conventions, though we reverse the order to `[[text|url]]` (rather than `[[url|text]]`) for better plaintext readability when URLs are long.

To use literal `[[`, `]]`, or `|` characters in text outside of links, escape them with backslash: `\[\[`, `\]\]`, `\|`


## Priority (Optional)
Priority can be designated at any time with the `!` character followed by a number.

While there is no limit, it is encourage to support around 4 levels of priority atleast to support the eisenhower method

we use the eisenhower matrix method as described in [the attached pdf](./Eisenhower-Matrix-Fillable.pdf)


## Objective (Optional)
A plan may designate a parent objective. in this case, the name of the objective is used as the key for the sake of readability

designated by the `*` character, the same rules apply around escaping forbidden characters

otherwise plans are assumed to be unparented, or if done within a workspace context, as part of the objective associated with the file itself.

For more information on file conventions, please review [naming conventions](./naming_conventions.md)

### Objective Hierarchies (Path Notation)
objectives can be organized into hierarchies using path notation with `/` as the separator:

```actions
[ ] Build the CLI *work/clearhead/cli
[ ] Write documentation *work/clearhead/docs
[ ] Fix personal website *personal/website
```

This allows:
- Scoping plans under nested objectives (work → clearhead → cli)
- Disambiguating objectives with the same leaf name (`work/cli` vs `personal/cli`)
- Hierarchical filtering (query `*work/` to get all work plans)

**Path rules:**
- Segments are separated by `/`
- Each segment follows standard story naming rules
- Paths are case-insensitive for matching
- Leading/trailing slashes are normalized away

**Example hierarchy:**
```
work/
├── clearhead/
│   ├── cli
│   ├── parser
│   └── docs
└── other-
personal/
├── website
└── hobbies
```

### Root plans only
It should also be noted that only root plans can have an objective designated.

It is assumed that any child plan(s) are part of the parent plan and do not need to be designated as part of an objective themselves.

This radically reduces the complexity of the parser and allows for a more readable format, it also makes querying radically easier since it enables us to simply query for the root node of the tree and get all of the children without needing to do any special parsing


## Context (Optional)
We use the context in accordance with GTD to answer the where question often.

started with the `+` character, one can use multiple contexts by separating each one with the `,` character to get multiple tags

contexts are simply keys and cannot be assigned values

### Multiple Contexts
Multiple contexts can ALSO be designated by using multiple `+` characters

```actions
[ ] Prepare presentation +work +meeting +client
```

### Tag Hierarchies
Tags can be organized into hierarchies via configuration (see [configuration.md](./configuration.md)). When a tag has parent tags defined, tagging an plan with a child tag implicitly includes all ancestor tags.

please see [the configuration specification](./configuration.md) for more details on how to set this up

With this configuration:
- `+neovim` implicitly includes `+terminal` and `+computer`
- `+grocery_store` implicitly includes `+driving`
- Queries for `+computer` will match plans tagged with `+neovim`

This enables fine-grained tagging while allowing broad filtering.

## Alias (Optional)
plans can define an alias using the `=` character followed by the alias name. Aliases provide stable, human-readable references that persist even if the plan's name changes.

**Syntax:** `=alias_name`

**Examples:**
```actions
[ ] Get the  documentation completed =docs
[ ] Deploy to staging =staging-deploy
```

**Alias rules:**
- Aliases must be unique within the workspace
- Aliases can contain letters, numbers, underscores, and hyphens
- Aliases cannot contain spaces or special characters
- Aliases are case-insensitive for matching

**Using aliases as references:**
Once defined, aliases can be used in predecessor references:
```actions
[ ] Review the documentation < docs
[ ] Run integration tests < staging-deploy
```

**Rationale:** Names evolve as understanding improves. Aliases provide a stable reference point that doesn't break dependencies when plan names are refined.

## Sequential Children (Optional)
A parent plan can be marked with `~` to indicate that its children should be treated as sequential steps - each child implicitly depends on the previous sibling completing.

**Syntax:** `~` after the plan name/metadata

**Example:**
```actions
[ ] Build release package ~
> [ ] Run linter
> [ ] Run tests
> [ ] Build binary
> [ ] Create archive
```

This is equivalent to:
```actions
[ ] Build release package
> [ ] Run linter
> [ ] Run tests < Run linter
> [ ] Build binary < Run tests
> [ ] Create archive < Build binary
```

**Semantics:**
- The `~` marker on a parent makes ALL direct children sequential
- Sequential ordering applies transitively to nested children
- The first child has no implicit predecessor
- Each subsequent child depends on the immediately preceding sibling

**Rationale:** Many workflows are inherently sequential (build steps, checklists, procedures). Explicitly declaring every dependency is tedious and error-prone. The `~` marker captures this common pattern concisely.

## Predecessors (Optional)

plans can depend on other plans being completed first. A predecessor is another plan that must reach a completed or cancelled state before this plan's dependencies are fully satisfied.

Started with the `<` character, you can specify one predecessor per marker. Multiple predecessors on the same plan means ALL must be completed or cancelled.


### Examples

**Simple predecessor (same file):**
```actions
[ ] Wash clothes < Put clothes in hamper
[ ] Dry clothes < Wash clothes
```

**Multiple predecessors (all must be done):**
```actions
[ ] Deploy to production < Code review complete < Tests passing
```

**Using UUID for specificity:**
```actions
[ ] Task B < #01951111-cfa6-718d-b303-d7107f4005b3
```

**Across files in workspace:**
```actions
# In -a/next.actions
[ ] Deploy < Code review complete

# In -a/code-review.actions
[ ] Code review complete
```

### Semantics

- Predecessors represent a **logical dependency**, independent of parent-child hierarchy (which uses `>`)
- An plan with predecessors can have any state (`[ ]`, `[-]`, `[=]`, etc.) — state is independent of predecessors

## Do-Date/Time (Optional)
plans can have a do-date, do-time, or both. This is designated by the `@` character. The format conforms to a simplified subset of ISO 8601.

Do date/time makes the most use of the date and time formats laid out above.

it ALSO includes recurrence information if needed as described in the recurrence section above

### Planned Acts
in order for a plan to have more than a single planned act, it needs a recurrence rule as described above.

When a plan has a recurrence rule, each occurrence is treated as a separate planned act with its own state and completion tracking.

## Completed Date (Optional)

Intended to be added automatically by tooling when the state is changed to completed.

Started with the `%` character, this helps to determine the date/time the plan was completed.

It only leverages the date/time formats laid out above: `YYYY-MM-DD`, `HH:MM`, or `YYYY-MM-DDTHH:MM`.

## Created Date (Optional)

Intended to be added automatically by tooling when an plan is first created.

Started with the `^` character, this helps to determine when the plan was initially recorded.

Again, like completed, only uses the date/time formats laid out above

### Derivation from UUID
Since ClearHead uses UUID v7, which encodes a millisecond-precision time stamp, tooling MAY derive the creation date from the `#` field if the `^` field is missing. However, an explicit `^` field always takes precedence.

## Id (Optional)
for this we are going to be using the V7 of the UUID standard.

the icon for this is `#` but is optional as we want to support the ability to create plans WITHOUT forcing the user to add a UUID manually before it is interpreted

while v7 is optional, it is highly recommended to include it to ensure universal uniqueness across systems and time

### Implications
here, we are trying to leave the door open for applications to go in later and update this whole thing with automated tools such as the cli that will be able to review and update these ids after the user has created the initial version of the structure

# Examples
Examples are assembled in the [Examples Directory](./examples/README.md) where you will find a variety of file samples that demonstate features, errors, and edge-cases of the specification

