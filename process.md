# Process Overview

Our fundamental unit of measurement is lists of actions.

Therefore, the entire system can be thought of as no more or less than a set of interconnected lists of actions.

This process covers the workflow to manage the state of said actions as they move through the system.

This process is built around the human-editable [Actions File Format](./action_file_format.md). Implementations may project those facts into the canonical [Action JSON Schema](./schemas/actions.schema.json), RDF, tables, or other presentations without making those projections a second workspace authority.

The process can be adapted to different implementation methods and delivery backends.

## Capture

Like GTD, we can always start our actions in the "Inbox" whether that be a file, a binary format, or a physical tray a core piece of the system is the idea of an inbox where all the new stuff is aggregated.

Normally, it is assumed that people will be writing to the "inbox.actions" file located at the workspace root which you can read more about in the [Workspace specification](./workspace.md).

Remember, we arent putting all the details in yet, just get it out of your head and into the inbox.

### 5 Minute Rule

The 5 minute rule answers that annoying question "how do i know when something is too small for the inbox?". the answer is "when it takes you longer to write it down than to do it".

For most people, this can be ~5 minutes or less. so, if you know an action will take less than 5 minutes, and you CAN do it right now, just do it.

It seems small, but this core insight is one of the most powerful ways to get seemingly small things done that can have major impact while making the process of maintaining the list easier.

#### List Size

The 5 minute rule has a more subtle benefit. Its important to understand that as your action list grows, so does the sophistication needed to manage it.

Therefore, discipline is required to keep the list manageable and the 5 minute rule is a key part of that.

## Clarify

Its also where the really hard work happens of deciding what ACTIONS need to be done to get to an _intended outcome_.

In particular, we want to have a viscious focus on writing down _the next physical action_ that needs to be done to move something forward.

In many ways, this is the most important, and most difficult part of the process but is also the part that makes the system save more work than it costs as this allows us to do our thinking ahead-of-time such that by the time we get to doing the work, we already know exactly what to do and just have a list of next actions to follow.

This is also where we link our actions to the proper research material, next-step links and really CLARIFYING what is needed to move forward

We should also figure out what actions are indepedent and dependent, making sure to mark actions with dependendent actions as we work through the list

Another important consideration is the addition of tags as context for these actions so that we can filter down based on the context this action must be done within

### Timeframes, and Dates

While this system supports the use of explicit time-blocking techniques, i find myself aligning with David on this point that scheduling hard-chunks on the calendar is often overwhelming for most people and requires a deep knowledge of the future to do well.

Instead, actions should only be scheduled if they have a proper due date or deadline associated with them.

Regular actions that dont need a due date should simply rely on the priority and context system to help them surface during times when we dont have our calendar time-blocked with a specific intention.

Otherwise, we run the risk of over-scheduling ourselves and creating a system that is more rigid than it needs to be.

## Organize

As we move through the inbox, we either complete actions, or move them to the appropriate [action list](./workspace.md)

    Like in other systems, its not about finishing everything necessarily its about putting them in the right place whether that be in the main workspace, a project folder, or even a someday/maybe list.

    This is also usually where we start setting due/do dates on the calendar (yes, we have both).

    And for any recurring actions, we should define them in `.ics` schedules so calendar timing stays canonical and expansion into `.actions` remains deterministic

    This is also where priorities can be assigned on the RFC 5545-aligned 1-9 scale (1 highest, 9 lowest); urgency and importance remain separate planning judgments rather than encoded quadrants.

### On IDs

    By the time we move the actions out of the inbox, it is recommended that each action is given a unique UUID so that it can be tracked throughout the system.

    While optional, this is a key feature that enables powerful features from analytics, to logging, to cross-referencing actions between lists in a deterministic way. 

    It is assumed this will be done with tooling, either automatically or as a script, but it can also be done manually if needed.

## Reflect

    This one is either part 4 or 5 depending on your perspective. 

    But this is also where GTD aligns with Agile in their emphasis on _regular reflection and review_.

    Both systems stress the importance of periodic review and periodically doing the three steps above at the appropriate times:
    - Capture: Always happening, should be near effortless and be the first thing you do when something new comes up
    - Clarify: Requires the most decision making of the other steps
    - Sometimes you are working with others and clarifying actions can be a group activity
    - Other times it is benficial to clarify actions as soon as you write them while the context is fresh
    - other times the purpose of the inbox is important and it is a mark of discipline to NOT clarify actions on particularly thorny days and save this work for more dedicated review times.
    - Organize: Like clarify, this often depends on the context but should be done in regular intervals
    - If you do organize daily, restrict it to once or twice a day to avoid decision fatigue
    - Weekly reviews are also a good default and when the bulk of the organizing is often done
    - Monthly reviews can be good for full refactors of existing outcomes to ensure everything is still aligned with your goals

    The real importance of reflection is that it is done _regularly_ such that it becomes a core _habit_ you build within your system. This means it must be deeply aligned with your workflow and schedule and will be a core part of how the workflow is built around you rather than the other way around.

    While a good default is a weekly review, agile does this process bi-weekly on average which is normal for teams doing this process, while some individuals fine building a daily ritual to be core to how they keep aligned through the day.

### On Analytics

    This is where a robust system of review is crucial for success. We want to look back at what we have done while planning future intentions, so tooling may project the workspace into JSON, RDF, tables, or an external analytical store. These are read models over the authoritative workspace unless an explicit mutation contract says otherwise.

#### Blocked and Dependent Actions

    One particular place where tooling makes this easier is the ability to identify when some actions may be blocked or depend upon one another which will help us identify bottlenecks in our workflow and ensure we are focusing on the right actions at the right time.

    This process is difficult to do by hand with a file of strings, but trivially easy with even a simple database.

### On Scheduling

    This is also the stage where active use of the calendar bcomes key to managing the list of actions as reviewing both our upcoming and past intentions can often bring up new actions or remind us of key other actions we are trying to do

## Engage

    Any other point in time that you are not doing one of the above phases, you are in the "Engage" phase where you are using your system as a declarative action system where you simply look at your list of actions and complete them as time permits

    Here we are embodying the core principles of deep work to keep us aligned on the next action we want to focus on, knowing that we have reviewed the relevant inboxes and have decided what can and should be done ahead of time.

### Agenda View

    Another core usecase for the system is being able to generate an "agenda view" of the actions that need to be done today or in the near future.

    This is not simply actions that are due/do today, but also represents actions that have no open dependencies, are within the proper context you are in, and are the top priority actions you want to focus on. All of this requires not just a data system, but a robust one that is able to leverage the relationships between actions as a graph and do the hard work of filtering down to the right actions for you to focus on.

    In many ways, this is the core "why" beind the whole system as we want to make generating, maintaining, and updating this list as easy and effortless as possible so that we are mostly focused on completing actions rather than managing the system itself.

    If all goes well, this list should be where you spend the majority of your time as you work through your day.

    This list will include recurring and one-off actions, as well as actions that have no due date but are of high priority of which can be done within the current context/timeframe.

## Arhiving

    Archival is a sparate activity from closure, a record can be closed however long we want to before it is "archived" and for some formats, the distinction isnt needed as much if the state is maintained within a database. however, for file-based interfaces it is often easier to move the closed records into some sort of "archive" for external storage and querying such that the whole graph can be queried at a a later time such as is outlined in the [workspace spec](./workspace.md)

# Workflow

    Now that we have covered the overarching stages, we want to get a bit more granular around the relationships between various properties around the actions and how they are meant to communicate our intent

## Charters

    Charters follow a fairly simple workflow as they are higher level than the plan and thus are expected to see less daily alteration. still, there is still some workflow to consider.

### State

Charter state is a local fact governing whether its work stream is admitted for
engagement:

- `New` — defined but not yet admitted. This is the default when `state` is
  omitted from source.
- `Active` — eligible for engagement, provided every ancestor Charter is also
  `Active`.
- `Blocked` — cannot currently advance.
- `Closed` — finished and terminal.
- `Cancelled` — abandoned and terminal.

States never cascade implicitly. Changing a Charter's state does not rewrite any
descendant Charter or Action. Effective eligibility is nevertheless inherited:
a Charter beneath a non-`Active` ancestor is not admitted even when its own local
state is `Active`.

Cross-level contradictions remain visible and are diagnosed rather than
silently normalized:

- an `Active` descendant Charter or `InProgress` Action beneath `New` or
  `Blocked` ancestry is a warning;
- an open descendant Charter or Action beneath `Closed` or `Cancelled` ancestry
  is a violation.

An `Active` Charter with no Actions is valid and does not require a warning.

#### Closure

Before closing or cancelling a Charter, its open descendant work should normally
be completed, cancelled, moved, or otherwise reconciled. Implementations must not
automatically complete or cancel descendants as an implicit consequence of the
Charter transition. A separate explicit batch operation may be offered when the
user deliberately requests cascading mutations.

## Plans

    Plans are schedule definitions represented in `.ics` files. They define timing and recurrence, while `.actions` files hold the generated or manually-created actions.

### Recurring Actions

    Recurring actions are prescribed by Plan `VTODO` masters carrying `RRULE`.

    Template references may expand each occurrence into richer act structures.

### Plans vs Actions

    Plans/schedules and actions are distinct concerns:
    - Plans/schedules live in `.ics`
    - Actions live in `.actions`

    Not all actions must have a formal schedule source (ad-hoc actions are valid).

    please review [the workspace spec](./workspace.md) for the process of how they are moved from open, to closed, to archive within the file-based format

    please review the [ontology](./ontology.md) for more details on the relationship between plans and actions

### Instance-Count Generation

    Instances are generated per schedule based on two configured counts rather than a date horizon. This keeps generation cadence-agnostic: a daily habit and a quarterly review both produce a predictable number of queued instances regardless of recurrence frequency.

    The two values (see [Configuration](./configuration.md)):
    - `expansion_total_instances` (default: `2`) — total instances generated per schedule
    - `expansion_primary_instances` (default: `1`) — how many land in the primary `.actions` file; the rest go to `.upcoming.actions`

    Both can be overridden per-schedule via the `upcoming:` directive in the Plan VTODO DESCRIPTION.

    See [ICS Schedule Spec](./ics_schedule_spec.md) for expansion details.

### Expand Actions Workflow

    The schedule expansion lifecycle is:

    1. Read schedules from `.ics`
    2. For each schedule, count open instances already in `.actions` and `.upcoming.actions`
    3. Resolve template (charter-local first, then workspace root)
    4. Generate or upsert instances up to `expansion_total_instances`, placing the first `expansion_primary_instances` into `<charter>.actions` and the remainder into `<charter>.upcoming.actions`

    This process must be idempotent: rerunning expansion for the same schedule must not duplicate acts or change the placement of already-existing instances.

### Upcoming Actions Workflow

    Managing upcoming actions follows three stages:

    **1. Expand**
    Run `expand` (or equivalent) to ensure each schedule has its full complement of instances across both files. This is the entry point — the move command will warn if expansion has not been run.

    **2. Archive**
    Complete or cancel actions normally. Closed actions in `<charter>.actions` move to `<charter>.completed.actions` as usual. Closed or cancelled actions in `<charter>.upcoming.actions` are also moved to `<charter>.completed.actions` — they are never promoted to the primary file retroactively.

    **3. Move**
    Run the `move` command (or equivalent) to promote instances from `<charter>.upcoming.actions` into `<charter>.actions` when the primary file has open slots below `expansion_primary_instances` for a given schedule. The move command checks this invariant per schedule and pulls the next chronological instance from upcoming to fill each empty slot.

    The move command will warn if `expand` has not been run and there are not enough upcoming instances to fill the slots.

    These commands are the primary interface. Users who want a tighter conveyor belt can wire expand and move together (e.g. run both after closing actions), but they remain separate by default so that generation and promotion are explicit and debuggable.

#### Schedule Edits

    Editing a schedule updates future generation behavior.

    - **Past acts:** remain historical records
    - **Existing generated future acts:** implementation policy decides mutate vs replace
    - **Not-yet-generated future acts:** reflect latest schedule/template state

    Implementations should document their policy and keep behavior deterministic.

### Children of Recurring Actions

    For complex recurring workflows, schedules can reference templates via the Plan VTODO DESCRIPTION field (first line: `template: <name>`).

    Rather than generating one flat act, expansion can generate a structured act tree per occurrence.

## Actions

    Actions will be the primary record type that people will interact with day-to-day and as such understanding their workflow is key

### State

Action state records the lifecycle of one concrete act:

- `NotStarted` — open and not presently underway; the default for a new Action.
- `InProgress` — presently underway. It is not another spelling of Charter
  `Active`.
- `Blocked` — open but unable to advance; explicit dependencies are preferred
  when they accurately identify the blocker.
- `Completed` — finished successfully and terminal.
- `Cancelled` — intentionally abandoned and terminal.

A common workflow is `NotStarted -> InProgress -> Completed`; blocked or
cancelled paths remain valid. State transitions are local facts and do not
implicitly mutate parent or child Actions.

`Ready` is derived and must not be stored as an Action state. A `NotStarted`
Action is ready only when:

1. its owning Charter and every ancestor Charter are `Active`;
2. every predecessor is satisfied (`Completed` or `Cancelled`); and
3. applicable schedule and context constraints permit execution.

A trusted next-work projection surfaces admitted `InProgress` Actions before
ready `NotStarted` Actions. Contradictory `InProgress` work beneath non-admitted
Charter ancestry is reported as a coherence finding rather than silently treated
as ready.

### On Closure

    Closure is different from archiving which we will cover later.

    All formats should support closure and when we have completed a plan the most upcoming action, which is the only one except for the case of a recurring action, is also completed, while all projected actions are removed as they were simply projections and we dont want to clutter the archive with them

### On Child Actions

Parent and child Action states remain independently asserted; neither direction
cascades implicitly. Tooling may derive facts such as “subtree complete” or omit
an open container from a next-work projection while an executable descendant
exists, but those projections do not change the parent's stored state.

A terminal parent with open descendants is contradictory and should be reported
for deliberate reconciliation. An explicit command may offer a reviewed batch
transition, but merely completing or cancelling one Action must not rewrite its
relatives.

### Priority

    Priority uses the RFC 5545 range directly: 1 is highest and 9 is lowest. An omitted priority means undefined. This direct scale preserves VTODO interoperability without a lossy conversion table.

    Priority is ordering guidance, not an encoded Eisenhower quadrant. Urgency may be represented by dates and importance by the surrounding charter or objective. Work that no longer deserves attention should be explicitly cancelled rather than hidden behind a special priority value.

# Engineering Process

    The stages above describe how *users* move actions through the system. This section describes how *we* should move engineering next-actions through it, because the same discipline that keeps a personal list honest keeps a charter honest.

## The Call-Site Sweep Done-Gate

    A core capability is not done until every call site that duplicated it has been swept onto it, and a guard exists so the old pattern cannot silently reappear.

    This was learned the expensive way on the core-seam charter (2026-07-11): several next-actions had been marked `[x]` with plausible, detailed descriptions of what "landed" — a precedence-bug fix, subtree-close semantics moved to core, a durability guard — and none of it existed anywhere in the repository. No commit, no stash, no other branch. One of them was a live user-facing bug marked fixed while still reachable through four different commands.

    The pattern that let this happen: a capability got added to core, but the CLI's own call sites kept their inline, duplicate implementation next to it. Nothing forced convergence, so "the core function exists" was mistaken for "the capability is done." Two capabilities can coexist for a long time — the description alone can't tell you which one a caller actually goes through.

    The done-gate this charter proposes, going forward:

    1. **Implement the capability once**, in the layer that should own it (core, in the core-seam charter's case).
    2. **Sweep every call site onto it.** Find each place the old inline/duplicate logic lived and delete it, not just add a new path beside it. If a caller can still reach the old code, the sweep is not done.
    3. **Add a guard** — a test, a lint, a grep-check — that fails if the old pattern reappears. Not every capability needs one (a guard is proportional to how easy the old pattern is to reintroduce and how costly a regression would be), but if you needed to sweep it once, assume someone will reintroduce it by accident later.
    4. **Verify the claim against the code, not the description**, before marking it done. A next-action's description is a claim about the world; `git log` and the source tree are the world. If you can't point at a commit and a diff that matches the description, it isn't done yet — write down what's actually true instead of what was planned.

    Step 4 is the one that would have caught the 2026-07-11 gap immediately: none of the falsely-completed items had a matching commit. Checking is cheap; trusting a well-written description is what's expensive.
