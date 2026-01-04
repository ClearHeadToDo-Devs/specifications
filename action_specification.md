---
title: Actions file specification
description: File Specification for the actions filetype
author: primary_desktop
categories: Reference
created: 2025-01-19T03:16:49-0800
updated: 2025-01-20T00:04:29-0800
version: 1.1.1
---
This specification will lay out the formal specifications for the `actions` filetype, usually denoted by a `*.actions` file.

# High-Level Guidelines
This specification will attempt to maintain backwards compatibility. That is, we will only add backwards-compatible changes to prevent implement's from dealing with breaking changes in the specification.

this means that there are currently no plans to add a top-level 'version' structure as we want to make sure that an action list made today will still be parsable 10 years from now, even if there are new features that have been added in that time.

## plaintext implications
Fundamentally, the `actions` filetype is a list of actions that can be formally parsed in a machine-readable way while still being readable and writable with any application the user chooses
As such, great care is taken to minimize the amount of characters that need to be typed by a human, while being considerate to readability of the core file

Special considerations should be made to the readable nature of the document, and how this can result in design decisions that would not normally be taken within a database.
For example, the name should be considered a secondary key for the action. While we will have an ID that will ensure universal uniqueness, the plaintext nature of this solution lends itself to using the name as a natural key
This could result in a situation where other filetypes are using the name of the action rather than the id to identify it
As such, one should be considerate about creating default names for actions as this could lead to name collision within the implementation, and should instead use some form of pattern to create new actions automatically without having name collision (maybe default to UUID of action?)

## Parser Guidance
With that said, it is also a use-case that these files are able to be read by a formal parser to allow for data extraction and the potential for placing these pieces of data into a schema

Finally, in terms of rules-processing, we take the approach of newer markdown formats like neorg which deemphasize the importance of whitespace to denote depth.
Instead, we use explicit characters or a sequence of characters to make the act of parsing this work cleaner

## Align to strong foundations
to the degree possible, we try to adhere to the [action schema](https://schema.org/Action) defined at schema.org so that we are able to align with the larger semantic data community and leave the door open for interoperability in the future

and do note from the W3C consortium we define an Action as a subset of a [Thing](http://webschemas.appspot.com/Thing) from a schema perspective

## Dates, times, and repititions
we make repeated use of date formats in this file type.

we primarily follow the [icalendar standard](https://en.wikipedia.org/wiki/ICalendar) as these can be seen as specialized calendar events and a core usecase is the integration with calendar apps
dates, times, and durations will be written using the [ISO 8601 Date Standard](https://en.wikipedia.org/wiki/ISO_8601) 

this makes reading dates consistent and easily parsable by nearly any language while also aligning to the notation most expected by the international community 

while only some will take advantage of the extended functionality, they will all share the same base of the ISO 8601 standard
### Date Structure
As denoted, each file can be understood as a list of actions that the person intends to take.

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

if in an unambiguous context (like a child of an action due on a specific day) then simply listing the time should be sufficient, without the requirement of even a date

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
Actions can repeat on a schedule using the RRULE (Recurrence Rule) syntax from [RFC 5545 section 3.3.10](https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.10).

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
Every child action starts with atleast one `>` character. Children of a parent action can be denoted by `>>` and so-on down to the official limit of 5 levels of depth. Now while nothing stops implementors from allowing arbitrary nesting, it should be assumed that 5 is the limit if there is indeed a limit.

6 levels was chosen to conform with standard markdown conventions

all other symbols will be valid for child actions, and parsing should still be easy since they will all be preceded by the progression of `>` characters

### Adding Children
Children actions should be added to the end of an action to leave the context closer to the name of the action. 
Children should be the last thing in the chain before the completion-date/Id

As such, child actions are encapsulated within the parent to make for easy parsing
styling around indentation is left up to the implementors, it should NOT be important to parsing the document

## State (Required)
We want to accomodate a few more states than done and not done, so we put the state between the `[` and `]` characters
The options for states are as follows:
- ` ` Not Started (default)
- `x` Completed
- `-` In-Progress (for work-in-progress limits)
- `=` Blocked/Awaiting
- `_` Cancelled (for historical systems)

This and the depth constitute the primary "marker" for the start of an action, making both parsing and reading easier since you can easily scan for the beginning of the next action visually on the screen


## Name (Required)
The final required field is the name of the action itself. 

Due to the nature of the format, special characters will need to be escaped with the `\` character
The list of special characters that need to be escaped are below:
- `$` - Reserved for Descriptions
- `!` - Reserved for Priority
- `*` - Reserved for Stories/Projects
- `+` - Reserved for contexts
- `@` - Reserved for Do-Date-Time
- `%` - Reserved for Completed Date
- `>` - Reserved for Children
- `[` `]` - Reserved for State markers and Links (when used as `[[link]]`)
- `|` - Reserved for Link separator (when within `[[...]]`)

Otherwise, this is one of the more encompassing fields where users are allowed to write as much as they like, even newlines

however, do note the point above about using names as secondary keys so if something is going to be really long, save it for the description section below

### Description (optional)
The name fields status as a secondary key means that it is sometimes necessary to denote a longer description for an action

this is where the description comes in and we can start one at any point within our name field within the `$` character

However, the rules around escaping still apply to ensure easy parsing

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
Because `[` and `]` are used for state markers at the start of actions, links use double-bracket `[[` syntax to avoid parsing ambiguity. The pipe `|` separator follows wiki conventions, though we reverse the order to `[[text|url]]` (rather than `[[url|text]]`) for better plaintext readability when URLs are long.

To use literal `[[`, `]]`, or `|` characters in text outside of links, escape them with backslash: `\[\[`, `\]\]`, `\|`


## Priority (Optional)
Priority can be designated at any time with the `!` character followed by a number.

While there is no limit, it is encourage to support around 4 levels of priority atleast to support the eisenhower method

we use the eisenhower matrix method as described in [the attached pdf](./Eisenhower-Matrix-Fillable.pdf)


## Story/Project (Optional)
An action may designate a parent project/story. in this case, the name of the story/project is used as the key for the sake of readability

designated by the `*` character, the same rules apply around escaping forbidden characters

otherwise actions are assumed to be unparented.

### Root Actions only
It should also be noted that only root actions can have a parent project/story.

It is assumed that any child action(s) are part of the parent action and do not need to be designated as part of a project

This radically reduces the complexity of the parser and allows for a more readable format, it also makes querying radically easier since it enables us to simply query for the root node of the tree and get all of the children without needing to do any special parsing


## Context (Optional)
We use the context in accordance with GTD to answer the where question often. 

started with the `+` character, one can use multiple contexts by separating each one with the `,` character to get multiple tags

contexts are simply keys and cannot be assigned values

## Do-Date/Time (Optional)
Actions can have a do-date, do-time, or both. This is designated by the `@` character. The format conforms to a simplified subset of ISO 8601.

- **Date**: A date is specified in `YYYY-MM-DD` format (e.g., `@2025-10-20`).
- **Time**: A time is specified in 24-hour `HH:MM` format (e.g., `@14:30`).
- **Date and Time**: A date and time are combined with a `T` separator: `YYYY-MM-DDTHH:MM` (e.g., `@2025-10-20T14:30`).

#### Duration (Optional)
We can give an optional duration after the time by supply the `D` character followed by a number that will be converted to minutes

this can look like a simple `D30` to mean a duration of 30 minutes

for application designers, durations are assumed to default to 15 minutes

##### Recurrence (Optional)
Actions can repeat on a schedule by adding recurrence rules after the date/time. Recurrence is specified using the `R:` prefix followed by RRULE syntax (see [Recurrence](#recurrence) section above for full syntax reference).

The do-date/time serves as the DTSTART (start date) for the recurrence, and the RRULE defines the pattern of repetition.

**Examples:**
- `@2025-01-21T19:00 R:FREQ=WEEKLY;BYDAY=TU` - Every Tuesday at 7pm
- `@2025-01-20T09:00 R:FREQ=DAILY;BYDAY=MO,TU,WE,TH,FR` - Weekdays at 9am
- `@2025-02-01 R:FREQ=MONTHLY;BYMONTHDAY=1` - First of each month
- `@2025-01-01 R:FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1;COUNT=10` - Next 10 New Year's Days

**Combining with Duration:**
```actions
[ ] Daily standup @2025-01-20T09:00 D15 R:FREQ=DAILY;BYDAY=MO,TU,WE,TH,FR
```
This creates a recurring 15-minute event every weekday at 9am.

**Recurrence Semantics:**
- The action with recurrence is a **template** that defines the pattern
- Applications expand the template to generate individual **occurrence instances**
- The template itself typically remains in the main `.actions` file unchanged
- Completed occurrences can be logged separately (see [Recurrence Logging](#recurrence-logging-optional) below)

## Completed Date (Optional)

Intended to be added automatically by tooling when the state is changed to completed.

Started with the `%` character, this helps to determine the date/time the action was completed.

It follows the same format as the Do-Date/Time: `YYYY-MM-DD`, `HH:MM`, or `YYYY-MM-DDTHH:MM`.

## Created Date (Optional)

Intended to be added automatically by tooling when an action is first created.

Started with the `^` character, this helps to determine when the action was initially recorded.

It follows the same format as the Do-Date/Time: `YYYY-MM-DD`, `HH:MM`, or `YYYY-MM-DDTHH:MM`.

### Derivation from UUID
Since ClearHead uses UUID v7, which encodes a millisecond-precision timestamp, tooling MAY derive the creation date from the `#` field if the `^` field is missing. However, an explicit `^` field always takes precedence.

## Id (Optional)
for this we are going to be using the v7 of the UUID standard.

the icon for this is `#` but is optional as we want to support the ability to create actions WITHOUT forcing the user to add a uuid manually before it is interpretted

### Implications
here, we are trying to leave the door open for applications to go in later and update this whole thing with automated tools such as the cli that will be able to review and update these ids after the user has created the initial version of the structure

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

