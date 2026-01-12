# Process Overview
Our fundamental unit of measurement is lists of actions.

Therefore, the entire system can be thought of as no more or less than a set of interconnected lists of actions.

This process covers the workflow to manage the state of said actions as they move through the system.

All of this process is assumed to be built around the [Actions File Format](./action_file_format.md) which can be easily translated into either [json data](./json_schema.md), [relational databases](./sql_schema.md), or even more visual formats like markdown files for easier human consumption.

## Capture

Like GTD, we can always start our actions in the "Inbox" whether that be a file, a binary format, or a physical tray a core piece of the system is the idea of an inbox where all the new stuff is aggregated.

Normally, it is assumed that people will be writing to the "inbox.actions" file located at the workspace root which you can read more about in the [Naming conventions specification](./naming_conventions.md).

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

As we move through the inbox, we either complete actions, or move them to the appropriate [action list](./naming_conventions.md)

Like in other systems, its not about finishing everything necessarily its about putting them in the right place whether that be in the main workspace, a project folder, or even a someday/maybe list.

This is also usually where we start setting due/do dates on the calendar (yes, we have both).

And for any recurring actions, we should write out RRULEs to make sure they are tracked properly in our calendar

I also think this is where we should start thinking about priorities which align to the eisenhower matrix of 1-4
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
This is where a robust system of review is crucial for success. We want to be able to both look back at what we have done, while also planning for future intentions and as such this is often where we transition from working with the file format to things like [sql](./sql_schema.md) or [json](./json_schema.md) to get better insights into the state of our actions. and track these actions as they move through the system and to be able to find the relevant actions we need to focus on next.

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
