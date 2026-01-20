# Ontology & Linked Data Specification

**Version:** 3.0.0
**Vocabulary URI:** `https://clearhead.us/vocab/actions/v3#`
**Context Map:** [`schemas/actions.context.json`](./schemas/actions.context.json)

## Overview

This specification defines how the ClearHead platform utilizes Semantic Web technologies (RDF, OWL, SHACL) to provide a rigorous, portable, and interoperable data model. It explains the "Context Map" strategy that allows downstream tools (CLI, IDE extensions, GUIs) to work with simple JSON while maintaining full semantic precision.

The core philosophy is **"JSON for Developers, RDF for Machines"**. We use JSON-LD contexts to bridge the gap between ergonomic developer experience and semantic formalisms.

## The Context Map (`context.json`)

The `context.json` file is the keystone of the ClearHead data architecture. It maps the simplified JSON keys used by applications to the formal URIs defined in the [Actions Vocabulary](https://clearhead.us/vocab/actions/v3).

### Purpose
- **Decoupling:** Applications don't need to know about RDF or ontologies. They just read/write JSON.
- **Interoperability:** The same JSON data can be treated as a Linked Data graph by any tool that supports JSON-LD.
- **Validation:** The ontology provides a source of truth for the meaning of fields, enabling logic (like inference) that goes beyond syntax checking.

### Usage in Downstream Projects

Downstream projects (like `clearhead-cli`) simply include a reference to the context map in their JSON exports:

```json
{
  "@context": "https://clearhead.us/schemas/actions.context.json",
  "actions": [ ... ]
}
```

This single line transforms a proprietary JSON format into a standard RDF graph.

## File Format to RDF Mapping

This section details how the plain text `.actions` format maps to the RDF vocabulary.

### Core Action Structure

| File Syntax | RDF Triple Pattern | Notes |
|-------------|-------------------|-------|
| `[ ] Task name` | `?action a actions:Action ; schema:name "Task name" ; actions:state actions:NotStarted ; actions:depth 1` | Root action |
| `> [ ] Child task` | `?child a actions:Action ; schema:name "Child task" ; actions:state actions:NotStarted ; actions:depth 2 ; actions:parentAction ?parent` | Child relationship |

### State Mappings

| File Syntax | JSON Key | RDF Class/Individual | Schema.org Equivalent |
|-------------|----------|----------------------|----------------------|
| `[ ]` | `not_started` | `actions:NotStarted` | `schema:PotentialActionStatus` |
| `[x]` | `completed` | `actions:Completed` | `schema:CompletedActionStatus` |
| `[-]` | `in_progress` | `actions:InProgress` | `schema:ActiveActionStatus` |
| `[=]` | `blocked` | `actions:Blocked` | *(extension)* |
| `[_]` | `cancelled` | `actions:Cancelled` | *(extension)* |

### Property Mappings

| File Syntax | JSON Key | RDF Property | RDF Value Type |
|-------------|----------|--------------|----------------|
| `!1` | `priority` | `actions:hasPriority` | `xsd:integer` |
| `*Project` | `story` | `actions:hasProject` | `xsd:string` |
| `+context` | `contexts` | `actions:requiresContext` | `xsd:string` |
| `$description` | `description` | `schema:description` | `xsd:string` |
| `@2025...` | `doDate` | `actions:hasDoDateTime` | `xsd:dateTime` |
| `< uuid` | `predecessors` | `actions:dependsOn` | `xsd:string` (UUID) |

## Semantic Interoperability

By adhering to this specification, tools ensure that:

1. **State is Meaningful:** "Completed" isn't just a string; it's a state in a finite state machine defined by the ontology.
2. **Priorities are Standardized:** Priority 1 represents "Urgent & Important" (Eisenhower Matrix), not just "High".
3. **Dependencies are Traceable:** `predecessors` (mapped to `dependsOn`) allows for graph traversal algorithms to find critical paths.

## Implementation Guidelines

### Parsing to JSON-LD

When implementing a parser:
1. Parse the `.actions` text format into the standard JSON structure (defined in [JSON Schema Specification](./json_schema_specification.md)).
2. Inject the `@context` field pointing to the canonical URL.
3. Use the JSON keys exactly as defined in the schema to ensure the context map works.

### Example

**Input:**
```actions
[x] Buy Milk !1
```

**JSON Output:**
```json
{
  "@context": "https://clearhead.us/schemas/actions.context.json",
  "actions": [
    {
      "name": "Buy Milk",
      "state": "completed",
      "priority": 1
    }
  ]
}
```

**RDF Interpretation (Turtle):**
```turtle
@prefix actions: <https://clearhead.us/vocab/actions/v3#> .
@prefix schema: <http://schema.org/> .

_:b0 a actions:Action ;
    schema:name "Buy Milk" ;
    actions:hasState actions:Completed ;
    actions:hasPriority 1 .
```

## Related Specifications
- [JSON Schema Specification](./json_schema_specification.md): Defines the structure of the JSON output.
- [Actions Vocabulary](https://clearhead.us/vocab/actions/v3): The formal OWL ontology.
