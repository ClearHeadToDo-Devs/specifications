# Action Data Model Design

**Purpose:** Define conceptual data model that serves as canonical representation bridging DSL, CRDT, and RDF
**Philosophy:** This is a **model design document**, not an implementation specification. Focuses on WHAT and WHY, not HOW.

---

## Core Architectural Principles

### 1. Lossless Conversion

Every transformation must preserve information perfectly:
- **CRDT → Data Model → CRDT** = identical state
- **Data Model ↔ RDF** = no semantic information lost
- **DSL ↔ Data Model** = preserves user intent (formatting where it matters)

### 2. Type Safety Through Semantics

Use type system to enforce invariants that ontology defines:
- ActionPlans cannot have process states (BFO: continuants don't have occurrent states)
- ActionProcesses must reference an ActionPlan (prescribed_by relationship)
- Depth is constrained to 0-5 (hierarchy limit)

### 3. Plan/Process Separation

Distinguish between **intention** and **execution**:
- **ActionPlan** = What should happen (continuant, information entity)
- **ActionProcess** = What actually happened (occurrent, has temporal parts)
- One plan can prescribe many processes (recurring actions)

---

## Core Concepts

### ActionPlan (Intention)

An ActionPlan is the canonical representation of an intention to do something.

**Semantic category:** Continuant (exists across time)
**Ontology class:** `actions:ActionPlan` (extends `cco:ont00000965` Directive Information Content Entity)

**Essential properties:**
- **id:** Unique identifier (UUIDv7)
- **name:** Human-readable title
- **depth:** Hierarchical level (0 = root, 1-4 = child, 5 = leaf)

**Intentional properties:** (What should happen)
- **priority:** Importance level (1-4, Eisenhower Matrix)
- **project:** Associated project/story (root only)
- **do_datetime:** When to start
- **duration:** Estimated time needed
- **recurrence:** Pattern for repetition (RRULE)
- **contexts:** What conditions are needed (energy, location, tools, social)

**Relational properties:** (Structure)
- **parent_id:** Parent action in hierarchy (None for root)
- **predecessors:** Logical dependencies (must complete first)
- **sequential_children:** Marker that children should execute in order

**Metadata:**
- **alias:** Stable human-readable reference
- **created_at:** When intention was first recorded

### ActionProcess (Execution)

An ActionProcess is the canonical representation of actual execution of an intention.

**Semantic category:** Occurrent (unfolds over time)
**Ontology class:** `actions:ActionProcess` (extends `cco:ont00000228` Planned Act)

**Essential properties:**
- **id:** Unique identifier (UUIDv7)
- **plan_id:** Which ActionPlan this executes (prescribed_by)
- **name:** Action name (may inherit or override from plan)

**Execution properties:** (What actually happened)
- **state:** Current execution phase (NotStarted, InProgress, Completed, Blocked, Cancelled)
- **completed_at:** When execution finished
- **notes:** Notes about execution

**Metadata:**
- **created_at:** When process was created

---

## Hierarchy Model

### Depth Levels

| Depth | Ontology Class | Parent Type | Children Type | Max Children |
|--------|----------------|-------------|---------------|-------------|
| 0 | RootActionPlan | None | ChildActionPlan | Unlimited |
| 1-4 | ChildActionPlan | Root or Child | Child or Leaf | Unlimited |
| 5 | LeafActionPlan | ChildActionPlan | None | None (leaf node) |

**Constraints:**
- Maximum depth is 5
- Only root actions (depth 0) can have project assignments
- Only leaf actions (depth 5) cannot have children

### Parent vs. Predecessor

These are **orthogonal** relationships - an action can have both:

**Parent (hierarchical containment):**
```
[ ] Deploy to production
  > [ ] Code review
  > [ ] Run tests
```
- Code review and tests are PART OF the deployment
- Structured containment (tree)

**Predecessor (logical dependency):**
```
[ ] Deploy to production < Code review complete < Tests passing
```
- Deployment depends on code review AND tests
- Logical ordering (can cross hierarchies)

---

## Context Model

### Current Approach: String-Based (Pragmatic)

**Representation:** `Vec<String>`

**Examples:**
```rust
contexts: vec!["@computer", "@office", "low_energy"]
```

**Benefits:**
- Simple, ergonomic for hand-editing
- Matches current DSL format (`+@computer, @office`)
- No ontology knowledge required

**Limitations:**
- Can't leverage ontology reasoning over contexts
- "computer" and "neovim" relationship is implicit (not explicit)
- SHACL validation can't enforce context types

### Future Approach: Typed Entities (Rigorous)

**Representation:** `Vec<ContextRef>`

**Examples:**
```rust
enum ContextType {
    Location,
    Tool,
    Energy,
    Social,
}

struct ContextRef {
    id: String,  // Maps to ActionContext instance
    name: String, // Human-readable: "@office", "low_energy"
}

contexts: vec![
    ContextRef {
        id: "ctx-office-001",
        name: "@office",
    },
    ContextRef {
        id: "ctx-low-energy",
        name: "low_energy",
    },
]
```

**Benefits:**
- Leverages ontology reasoning
- Enables SHACL validation (e.g., "actions:requiresContext" must reference ActionContext)
- Supports hierarchical contexts (via tag_hierarchies config)

**Migration Strategy:**
Start with string-based, add typed support when LSP integration needs it for SHACL validation

---

## State Model

### Plan State (Disposition)

ActionPlans have a **disposition** that describes their lifecycle state.

| State | Meaning | Use Case |
|-------|---------|----------|
| Active | Plan is active and can generate processes | Default for most actions |
| Retired | Plan is complete (non-recurring) or no longer in use | One-time tasks marked [x] |
| Blocked | Plan is blocked by external factor | Cannot generate new processes |

**Representation:**
```rust
pub enum PlanDisposition {
    Active,
    Retired,
    Blocked,
}
```

### Process State (Execution Phase)

ActionProcesses have an **execution state** that describes current phase.

| State | Meaning | BFO Category | Use Case |
|-------|---------|-------------|----------|
| NotStarted | Not yet started | BFO Quality (inheres in process) | Default state |
| InProgress | Currently being worked on | BFO Quality | User actively focused |
| Completed | Successfully finished | BFO Quality | Marked [x] in DSL |
| Blocked | Waiting for dependency/external factor | BFO Quality | Can't proceed |
| Cancelled | Abandoned without completion | BFO Quality | Marked [_] in DSL |

**Representation:**
```rust
pub enum ProcessState {
    NotStarted,
    InProgress,
    Completed,
    Blocked,
    Cancelled,
}
```

---

## Priority Model

### Eisenhower Matrix Alignment

Priority follows Eisenhower Decision Matrix principles:

| Priority | Urgent | Important | Meaning | Typical Action |
|----------|---------|-----------|----------|---------------|
| 1 | Yes | Yes | Do now | Critical bug fix, urgent deadline |
| 2 | No | Yes | Schedule | Strategic planning, deep work |
| 3 | Yes | No | Delegate | Urgent but low-value task |
| 4 | No | No | Delete/Defer | Low priority, unclear value |

**Constraints:**
- Priority range: 1-4
- Default: None (no priority set)

---

## Reference Resolution

### Reference Styles

Actions can be referenced by multiple styles:

| Style | Example | Ambiguity | Performance |
|--------|---------|------------|--------------|
| Full UUID | `#01950000-...` | None (exact match) | Fast (UUID index) |
| Short UUID | `#01950000` | Low (8-char prefix collision) | Fast |
| Alias | `=deploy-staging` | Medium (duplicate aliases possible) | Medium (hash lookup) |
| Name | `<Wash clothes` | High (multiple actions with same name) | Slow (full table scan) |

### Resolution Order

References resolved in order of preference:
1. Full UUID (exact match)
2. Short UUID (prefix match)
3. Alias (case-insensitive)
4. Name (case-insensitive)

### Dependency Types

**Must complete before:** (Hard constraint)
- Represents that action CANNOT start until prerequisite is done
- Example: "Deploy < Deploy approved"
- SHACL can validate: "actions:dependsOn" cardinality

**Prefer to start after:** (Soft constraint)
- Suggestion for optimal ordering
- Example: "Review docs before code review"
- Not enforced in validation

**Sequential children:** (Special case of predecessors)
- Parent with `~` marker means children execute in order
- Each child implicitly depends on previous sibling
- Equivalent to adding explicit predecessor dependencies

---

## Recurrence Model

### Template-Based Approach

Recurrence uses **template pattern** approach:

**Template (ActionPlan):**
- Defines the recurrence rule (RRULE)
- Remains unchanged across all executions
- Stores metadata common to all instances

**Instances (ActionProcesses):**
- Each execution creates a new ActionProcess
- References the template via `plan_id`
- Has its own `completed_at`, `notes`, etc.

**Example:**
```
Template: "Weekly standup" (ActionPlan, recurring every Monday)
  ├─→ Instance 1: "Weekly standup 2025-01-20" (ActionProcess, completed)
  ├─→ Instance 2: "Weekly standup 2025-01-27" (ActionProcess, in progress)
  └─→ Instance 3: "Weekly standup 2025-02-03" (ActionProcess, future)
```

**Why this matters:**
- Enables "How often do I complete this weekly task?" queries
- Allows tracking execution patterns vs. intention
- Supports analytics like "What days am I most productive?"

---

## Data Invariants

### Must Always Be True

1. **No orphaned processes:** Every ActionProcess must reference a valid ActionPlan
2. **Depth consistency:** Depth field must match actual parent chain depth
3. **No circular dependencies:** No transitive dependency cycle
4. **Max depth 5:** Hierarchy cannot exceed 5 levels
5. **Valid UUIDs:** All UUIDs must be valid UUIDv7 format
6. **Project constraint:** Only depth 0 actions can have projects

### Should Always Be True

1. **Contexts have content:** Context tags must not be empty or whitespace-only
2. **Duration requires do_date:** Can't have duration without start time
3. **Recurrence requires do_date:** Can't have recurrence without start time
4. **Priority in range:** Priority must be 1-4 if set
5. **Completion date after do_date:** Processes complete after planned start

---

## Transformation Contracts

### CRDT ↔ Data Model

**Direction:** Bidirectional, lossless

**CRDT schema:**
```json
{
  "plans": Map<UUID, ActionPlan>,
  "processes": Map<UUID, ActionProcess>
}
```

**Invariants:**
- Plan and process IDs are unique across both maps
- Process `plan_id` references valid plan ID
- Parent IDs reference valid plans
- Predecessor IDs reference valid plans

### Data Model ↔ RDF

**Direction:** Semantic mapping (not 1:1 field mapping)

**Mapping strategy:**
- Use ontology classes (`actions:ActionPlan`, `actions:ActionProcess`)
- Use ontology properties (`actions:hasPriority`, `cco:prescribes`, etc.)
- Preserve all semantic relationships
- Convert typed values to RDF literals (strings, integers, datetimes)

**Example mapping:**
```rust
// String contexts (Phase 1)
for ctx in &plan.contexts {
    triples.push(Triple::literal(
        plan_uri,
        "actions:requiresContext",
        ctx,  // String literal
    ));
}

// Typed contexts (Phase 2 - when available)
for ctx_ref in &plan.contexts {
    triples.push(Triple::iri(
        plan_uri,
        "actions:requiresContext",
        format!("urn:context:{}", ctx_ref.id),  // Typed entity
    ));
}
```

### Data Model ↔ DSL

**Direction:** Lossless projection

**Rules:**
- Roundtrip: DSL → Data Model → DSL = identical state
- Preserve: User's horizontal spacing and indentation
- Canonicalize: Order metadata according to linting rules (I006)
- Add: Depth markers (`>`, `>>`) based on depth field

**Formatting exception:**
- Vertical spacing: Ensure one action per line
- Everything else: User's choices preserved

---

## Query Requirements

### Agenda View (Killer Feature)

**Question:** "What can I do right now?"

**Answer must consider:**

1. **Is this a root action plan?** (Depth 0)
   - Filter: `actions:hasDepth 0`

2. **Is the plan active?** (Disposition = Active)
   - Filter: Exclude retired/blocked plans

3. **Are all predecessors complete?** (No blocking dependencies)
   - Check: All `actions:dependsOn` references have completed processes
   - OR: Plan has no predecessors

4. **Are all parents complete?** (Hierarchical completion)
   - Check: All `actions:parentAction` ancestors have completed processes
   - Note: Root actions have no parents

5. **Does context match current situation?**
   - Match: One of `actions:requiresContext` values
   - Expansion: Include parent contexts from tag_hierarchies

6. **Is timing appropriate?**
   - Not overdue: `actions:hasDoDateTime` >= NOW or NULL
   - Not past do-date: Can't have passed scheduled start

7. **Sort by priority**
   - Order: `actions:hasPriority` ASC (1 = highest priority)

**Result:** Top 20 actions I can work on right now, ranked by importance

### Critical Path Analysis

**Question:** "What's blocking shipping this feature?"

**Answer must find:**
- All transitive dependencies of a target action
- Which of those are completed
- Which are still pending (blocking)

**Complexity:**
- Requires recursive SPARQL queries or path algorithms
- Must handle multiple dependency types (predecessors, parent hierarchy)

### Completion Analytics

**Question:** "How well am I sticking to my intentions?"

**Answer requires:**
- Group processes by prescribing plan
- Calculate completion rate per plan
- Identify plans with poor completion rates
- Analyze delays (actual completion vs. scheduled start)

---

## Open Questions

1. **Context transition strategy:**
   - When to migrate from `Vec<String>` to `Vec<ContextRef>`?
   - How to handle existing string contexts in CRDT?

2. **Process tracking:**
   - Should we track processes for non-recurring plans?
   - Or only create processes when marked `[x]` in DSL?

3. **UUID generation:**
   - Always generate UUIDv7 on creation?
   - Or allow user to omit and backfill later?

4. **Conflict resolution:**
   - What happens when CRDT sync changes a plan user is editing?
   - LSP merge strategy?

---

## See Also

- [Actions Ontology](../ontology/) - Semantic definitions
- [Action File Format](./action_file_format.md) - DSL syntax
- [Linting Specification](./linting.md) - Validation rules
- [DECISIONS.md](../DECISIONS.md) - Architectural decisions

---

**Version:** 1.0.0
**Created:** 2026-01-19
**Status:** Design Document
