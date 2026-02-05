# Ontology & Linked Data Specification

**Version:** 4.0.0
**Vocabulary URI:** `https://clearhead.us/vocab/actions/v4#`
**Ontology Documentation:** [ontology/README.md](../ontology/README.md)
**Context Map:** `https://clearhead.us/vocab/actions/v4/actions.context.json`
**JSON Schema:** `https://clearhead.us/vocab/actions/v4/actions.schema.json`

## Overview

This specification defines how the `.actions` file format maps to the [Actions Vocabulary](https://clearhead.us/vocab/actions/v4). It is an **integration document**, not an ontology reference — see the [ontology README](../ontology/README.md) for conceptual documentation.

The core philosophy is **"JSON for Developers, RDF for Machines"**. We use JSON-LD contexts to bridge the gap between ergonomic developer experience and semantic formalisms.

## The Context Map (`actions.context.json`)

The `actions.context.json` file is the keystone of the ClearHead data architecture. It maps the simplified JSON keys used by applications to the formal URIs defined in the [Actions Vocabulary](https://clearhead.us/vocab/actions/v4).

### Purpose
- **Decoupling:** Applications don't need to know about RDF or ontologies. They just read/write JSON.
- **Interoperability:** The same JSON data can be treated as a Linked Data graph by any tool that supports JSON-LD.
- **Validation:** The ontology provides a source of truth for the meaning of fields, enabling logic (like inference) that goes beyond syntax checking.

### Usage in Downstream Projects

Downstream projects (like `clearhead-cli`) simply include a reference to the context map in their JSON exports:

```json
{
  "@context": "https://clearhead.us/vocab/actions/v4/actions.context.json",
  "plans": [ ... ]
}
```

This single line transforms a proprietary JSON format into a standard RDF graph.

## JSON Schema (Ontology-Out)

The ontology-out JSON shape is validated with a JSON Schema published alongside the vocabulary:

- `https://clearhead.us/vocab/actions/v4/actions.schema.json`

This schema validates the **document container** (`@context`, `@graph`) and the **entity nodes** inside the graph, while SHACL validates the RDF semantics.

## File Format to RDF Mapping

This section details how the plain text `.actions` format maps to the RDF vocabulary.

### Core Structure

When you write a task in the file format, you're creating two linked entities:
1. A **Plan** (the task definition)
2. A **Planned Act** (the execution instance, which carries the phase)

| File Syntax | Creates | Notes |
|-------------|---------|-------|
| `[ ] Task name` | Plan + Planned Act | Plan prescribes the act; act has phase NotStarted |
| `> [ ] Child task` | Plan + Planned Act | Child plan linked via `actions:partOf` |
| `*project/path` | Objective | Plan linked via `actions:hasObjective` |

### Phase Mappings

Phase is a quality of the **Planned Act**, not the Plan.

| File Syntax | JSON Key | RDF Individual | Meaning |
|-------------|----------|----------------|---------|
| `[ ]` | `not_started` | `actions:NotStarted` | Act has not begun |
| `[-]` | `in_progress` | `actions:InProgress` | Act is currently executing |
| `[x]` | `completed` | `actions:Completed` | Act finished successfully |
| `[=]` | `blocked` | `actions:Blocked` | Act cannot proceed (external factor) |
| `[_]` | `cancelled` | `actions:Cancelled` | Act abandoned without completion |

### Property Mappings

| File Syntax | JSON Key | RDF Property | Domain | Range |
|-------------|----------|--------------|--------|-------|
| `!1` | `priority` | `actions:hasPriority` | Plan | `xsd:integer` (1-4) |
| `*Project` | `objective` | `actions:hasObjective` | Plan | Objective |
| `@2025...` | `doDate` | `actions:hasDoDateTime` | Plan | `xsd:dateTime` |
| `%2025...` | `completedDate` | `actions:hasCompletedDateTime` | Planned Act | `xsd:dateTime` |
| `< uuid` | `dependsOn` | `actions:dependsOn` | Plan | Plan |
| `> child` | *(hierarchy)* | `bfo:BFO_0000050` | Plan | Plan (partOf) |
| `^2025...` | `createdDate` | `actions:hasCreatedDateTime` | Plan | `xsd:dateTime` |
| `#uuid` | `uuid` | `actions:hasUUID` | Plan | `xsd:string` |
| `=alias` | `alias` | `actions:hasAlias` | Plan | `xsd:string` |
| `~` | `sequentialChildren` | `actions:hasSequentialChildren` | Plan | `xsd:boolean` |
| `R:FREQ=...` | `recurrence` | `actions:hasRecurrenceRule` | Plan | `xsd:string` |
| `D60` | `duration` | `actions:hasDurationMinutes` | Plan | `xsd:integer` |

### Context Requirements

Contexts use entity-based system for tag hierarchies and type classification:

| File Syntax | JSON Key | RDF Property | Range |
|-------------|----------|--------------|-------|
| `+work` | `context` | `actions:requiresContext` | `actions:Context` |
| `+computer` | `context` | `actions:requiresContext` | `actions:Context` |
| `+@office` | `context` | `actions:requiresContext` | `actions:Context` |

#### Context Entity Properties

| Property | Domain | Range | Purpose |
|----------|--------|-------|---------|
| `actions:hasContextIdentifier` | Context | `xsd:string` | DSL identifier (`"work"`, `"@office"`) |
| `actions:hasContextType` | Context | `actions:ContextType` | Type classification |
| `actions:contextBroader` | Context | Context | Parent in hierarchy |
| `actions:contextNarrower` | Context | Context | Children in hierarchy |

#### Context Types

- `actions:FacilityContextType` - Physical locations (`+@office`, `+@home`)
- `actions:AgentContextType` - People (`+@bob`, `+@manager`)
- `actions:ToolContextType` - Tools/software (`+computer`, `+phone`)
- `actions:CategoryContextType` - General categories (`+work`, `+personal`)

## V4 Design Principles

### Priority Simplification
V4 uses simple integer priorities (1-4) rather than CCO Priority Measurement entities for ergonomics:
- **1** = Urgent & Important (Do First)
- **2** = Important & Not Urgent (Schedule) 
- **3** = Urgent & Not Important (Delegate)
- **4** = Not Urgent & Not Important (Eliminate)

This follows the Eisenhower Matrix while remaining simple for users and queries.

### Entity-Based Contexts
V4 models contexts as entities rather than strings to enable:
- **Tag Hierarchies:** `+neovim` inherits from `+terminal` inherits from `+computer`
- **Type Classification:** Distinguish facilities, agents, tools, and categories
- **Inheritance Queries:** Find all tasks requiring "computer" contexts (including neovim)
- **Configuration Integration:** Connect to tag hierarchy configuration files

### CCO Alignment Strategy
V4 minimally extends CCO rather than wrapping it:
- **Use BFO directly** for part-whole relationships (`bfo:BFO_0000050`)
- **Reference CCO classes** by URI (`cco:ont00000974` for Plan)
- **Extend only where needed** (ActPhase, Context system, specialized temporal properties)
- **Maintain CCO semantics** while adding practical functionality

## Semantic Interoperability

By adhering to this specification, tools ensure that:

1. **Phase is Meaningful:** "Completed" isn't just a string; it's a quality instance defined by the ontology, attached to the execution (Planned Act), not the definition (Plan).
2. **Priorities are Standardized:** Priority integers map to Eisenhower Matrix quadrants consistently.
3. **Dependencies are Traceable:** `dependsOn` allows graph traversal to find critical paths.
4. **Recurrence is Clean:** One Plan can prescribe many Planned Acts — no need to duplicate task definitions.
5. **Context Hierarchies Work:** Tag inheritance enables flexible context-based filtering.

## Validation (SHACL)

The v4 SHACL shapes live in the ontology repo and are the canonical validation ruleset:

- `ontology/v4/actions-shapes-v4.ttl`

Implementations should use these shapes for linting, import validation, and integration testing.

## Implementation Guidelines

### Parsing to JSON-LD

When implementing a parser:
1. Parse the `.actions` text format into the standard JSON structure (defined in [JSON Schema Specification](./json_schema_specification.md)).
2. Inject the `@context` field pointing to the canonical URL.
3. Use the JSON keys exactly as defined in the schema to ensure the context map works.
4. Generate UUIDs for both the Plan and its Planned Act.

### Example

**Input:**
```actions
[x] Buy Milk !1 *groceries
```

**JSON Output:**
```json
{
  "@context": "https://clearhead.us/schemas/actions.context.json",
  "plans": [
    {
      "id": "urn:uuid:abc123",
      "name": "Buy Milk",
      "priority": 1,
      "objective": "groceries",
      "execution": {
        "id": "urn:uuid:def456",
        "phase": "completed"
      }
    }
  ]
}
```

**RDF Interpretation (Turtle):**
```turtle
@prefix actions: <https://clearhead.us/vocab/actions/v4#> .
@prefix cco: <https://www.commoncoreontologies.org/> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

# The Plan (task definition)
<urn:uuid:abc123> a cco:ont00000974 ;  # cco:Plan
    rdfs:label "Buy Milk" ;
    actions:hasPriority 1 ;
    actions:hasObjective <urn:objective:groceries> ;
    actions:prescribes <urn:uuid:def456> .

# The Planned Act (execution instance)
<urn:uuid:def456> a cco:ont00000228 ;  # cco:PlannedAct
    actions:hasPhase actions:Completed .

# The Objective (project)
<urn:objective:groceries> a cco:ont00000476 ;  # cco:Objective
    rdfs:label "groceries" .
```

## Related Specifications
- [Actions Vocabulary v4](https://clearhead.us/vocab/actions/v4): The formal OWL ontology.
- [V4 Design Document](../ontology/V4_DESIGN.md): Full design rationale and CCO alignment.
