# Ontology & Linked Data Specification

**Version:** 4.0.0
**Vocabulary URI:** `https://clearhead.us/vocab/actions/v4#`
**Ontology Documentation:** [ontology/README.md](../ontology/README.md)
**Context Map:** [`schemas/actions.context.json`](./schemas/actions.context.json)

## Overview

This specification defines how the `.actions` file format maps to the [Actions Vocabulary](https://clearhead.us/vocab/actions/v4). It is an **integration document**, not an ontology reference — see the [ontology README](../ontology/README.md) for conceptual documentation.

The core philosophy is **"JSON for Developers, RDF for Machines"**. We use JSON-LD contexts to bridge the gap between ergonomic developer experience and semantic formalisms.

## The Context Map (`context.json`)

The `context.json` file is the keystone of the ClearHead data architecture. It maps the simplified JSON keys used by applications to the formal URIs defined in the [Actions Vocabulary](https://clearhead.us/vocab/actions/v4).

### Purpose
- **Decoupling:** Applications don't need to know about RDF or ontologies. They just read/write JSON.
- **Interoperability:** The same JSON data can be treated as a Linked Data graph by any tool that supports JSON-LD.
- **Validation:** The ontology provides a source of truth for the meaning of fields, enabling logic (like inference) that goes beyond syntax checking.

### Usage in Downstream Projects

Downstream projects (like `clearhead-cli`) simply include a reference to the context map in their JSON exports:

```json
{
  "@context": "https://clearhead.us/schemas/actions.context.json",
  "plans": [ ... ]
}
```

This single line transforms a proprietary JSON format into a standard RDF graph.

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
| `> child` | *(hierarchy)* | `actions:partOf` | Plan | Plan |

### Context Requirements

Contexts map to CCO classes for resources required to execute a plan:

| File Syntax | JSON Key | RDF Property | Range (CCO Class) |
|-------------|----------|--------------|-------------------|
| `+@office` | `facility` | `actions:requiresFacility` | `cco:Facility` |
| `+computer` | `artifact` | `actions:requiresArtifact` | `cco:Artifact` |
| `+@bob` | `agent` | `actions:requiresAgent` | `cco:Agent` |

## Semantic Interoperability

By adhering to this specification, tools ensure that:

1. **Phase is Meaningful:** "Completed" isn't just a string; it's a quality instance defined by the ontology, attached to the execution (Planned Act), not the definition (Plan).
2. **Priorities are Standardized:** Priority 1 represents "Urgent & Important" (Eisenhower Matrix).
3. **Dependencies are Traceable:** `dependsOn` allows graph traversal to find critical paths.
4. **Recurrence is Clean:** One Plan can prescribe many Planned Acts — no need to duplicate task definitions.

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
