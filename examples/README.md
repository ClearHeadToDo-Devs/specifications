# ClearHead Examples

This directory contains example `.actions` files demonstrating various features of the ClearHead format.

## Basic Examples

- **minimal.actions** - Simplest possible action
- **with_children.actions** - Parent-child action hierarchy
- **with_description.actions** - Actions with descriptions
- **with_priority.actions** - Priority levels
- **with_context.actions** - Context tags
- **with_do_date.actions** - Due dates and times
- **with_completed_date.actions** - Completed actions
- **with_story.actions** - Actions belonging to projects/stories
- **with_everything.actions** - All optional fields demonstrated

## New Features (v2.0)

- **with_alias.actions** - Action aliases for stable references (`=alias-name`)
- **with_sequential.actions** - Sequential children marker (`~`) for ordered workflows
- **with_short_uuid.actions** - Short UUID references (8 chars) for predecessors
- **with_story_path.actions** - Hierarchical story paths (`*work/clearhead/cli`)
- **with_new_features.actions** - Comprehensive example combining all new features

## Recurring Actions

- **recurring_templates.actions** - Comprehensive recurrence patterns (daily, weekly, monthly, yearly)
- **recurring_log_example.actions** - Logging completed recurrence instances
- **with_recurring_daily_do_date.actions** - Simple daily recurrence
- **with_recurring_weekly_do_date.actions** - Simple weekly recurrence

## Calendar Export

The `export` command converts actions with due dates into iCalendar (`.ics`) format for import into calendar applications. Only actions with `@` (do_date_time) are included in the export.

### Example Files

- **calendar_export_example.actions** - Comprehensive demonstration including:
  - Daily, weekly, monthly, and quarterly recurring events
  - All action states (pending, in-progress, blocked, completed, cancelled)
  - Priority mapping, categories, and descriptions
  - Complex recurrence patterns (first Monday of month, etc.)

- **recurring_templates.actions** - Collection of common recurrence patterns

### Example Usage

```bash
# Export all actions with dates to iCalendar format
clearhead export calendar_export_example.actions -o calendar.ics

# Export only open (pending/in-progress/blocked) actions
clearhead export calendar_export_example.actions --open-only -o calendar.ics

# Export to stdout for piping
clearhead export calendar_export_example.actions | less

# Export from stdin
cat recurring_templates.actions | clearhead export > recurring.ics
```

### Importing to Calendar Apps

**Google Calendar:**
1. Export: `clearhead export inbox.actions -o calendar.ics`
2. Go to Google Calendar → Settings → Import & Export
3. Click "Select file from your computer" and choose `calendar.ics`
4. Recurring events will automatically expand in your calendar

**Apple Calendar:**
1. Export: `clearhead export inbox.actions -o calendar.ics`
2. Double-click the `.ics` file
3. Choose which calendar to import into

**Outlook:**
1. Export: `clearhead export inbox.actions -o calendar.ics`
2. File → Open & Export → Import/Export
3. Choose "Import an iCalendar (.ics) or vCalendar file"

### Supported Features

The calendar export supports:

- **Recurring events** - RRULE patterns are preserved (FREQ, INTERVAL, COUNT, UNTIL, BYDAY, etc.)
- **Event times** - `do_date_time` becomes DTSTART
- **Duration** - `do_duration` sets event length (default 15 minutes)
- **Descriptions** - Action descriptions become event descriptions
- **Priority** - Mapped from ClearHead priority (1-4) to iCalendar (1-9)
- **Categories** - Context tags become event categories
- **Status** - Action state maps to event status:
  - `[ ]` NotStarted → TENTATIVE
  - `[-]` InProgress → CONFIRMED
  - `[=]` Blocked/Awaiting → TENTATIVE
  - `[x]` Completed → CONFIRMED
  - `[_]` Cancelled → CANCELLED

### Example File

See **calendar_export_example.actions** for a comprehensive demonstration of calendar-exportable actions.

## Test Files

- **conformance_test.actions** - Comprehensive test covering all features
- **formatting/** - Directory with formatting test cases
- **linting/** - Directory with lint rule examples

## Queries

The **queries/** directory contains examples of SQL queries for filtering actions.
