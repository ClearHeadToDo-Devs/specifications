# Ontology Domain
Please feel free to review the full ontology and docs at [the full ontology repo](https://github.com/ClearHeadToDo-Devs/ontology).

For this we have a few primary entities that will align how much of the specifications are structured and understood:

- **Objectives**: Desired outcomes written down for the sake of planning towards them
- **Charters**: Declarations of scope for a particular domain of concern, these are the containers for plans and actions
- **Plans**: Formalized prescriptions that describe intended execution patterns or schedule-backed prescriptions
- **Actions**: The actual executable work items, whether prescribed by a plan or created directly

many of our structure map to these domain objects

## In specifications
many of the concepts and topics are ultimately converted into the domain objects or thought through the structure of the domain objects which is why this is an important core to understand when putting your head around the topic itself

## In Application Code
Another use of the ontology is in the form of structs or classes that can mirror the domain objects, either explicitly or through generation, so that we are able to have the structured understanding all the way through

### For querying
With this established, applications that use this format can start querying application data that is available through the lens of these domain objects using the SHACL shapes for validation of data in a graph database, and SPARQL queries for the primary querying technique for this work.

in this way, we can have a normal query language that can be shared between applications and composed with different ontologies so that this work can be put into the context of a larger ecosystem of ontologies and data

## Applied Ontology Contract (Implementation-Agnostic)

This section defines how downstream implementations should apply the ontology in data pipelines, without assuming a specific programming language or codebase.

### Canonical Semantic Bridge

Implementations should provide a canonical bridge between an internal domain model and RDF graph data:

- Domain data MUST be representable as RDF using the ontology terms.
- RDF graph data MUST be reconstructable into equivalent domain data for the supported entity scope.
- JSON-LD interchange SHOULD be produced from canonical graph semantics rather than ad hoc serializers.

The bridge is considered foundational for CRUD flows, query layers, and downstream display/export tools.

### Determinism Requirements

To support reproducibility, testing, and contributor confidence:

- Implementations SHOULD emit deterministic JSON-LD and graph-derived exports.
- Graph node ordering SHOULD be stable and documented (for example, by type rank then lexical identifier).
- Date-time literals SHOULD use a single canonical RFC3339 representation.

### Validation Expectations

Implementations SHOULD validate semantic constraints before publishing graph-derived interchange artifacts.

At minimum, validation should cover:

- Action lifecycle/status integrity
- Plan-to-action relationship integrity (where a plan link exists)
- Relationship constraints that prevent structurally invalid graphs

Ontology shapes and schema artifacts remain the normative source for term-level and shape-level constraints.

### Canonical Contract Artifacts

The ontology repository remains the canonical location for term and schema artifacts. In particular, implementations should follow the current `v4` contract files there (for example JSON-LD context, schema, and ontology-out contract documentation).

This specification does not redefine those artifacts; it defines how downstream tools should apply them consistently.

## Source Boundary: Core Ontology vs Integration Profiles

To preserve portability and avoid coupling the core model to a specific scheduling format:

- Core ontology/domain terms should remain source-agnostic.
- Integration profiles (such as `.ics`) may carry source-specific semantics.

### Neutral External Identity Bridge

When actions are generated from external scheduling systems, implementations should preserve linkage via neutral fields:

- `externalScheduleId` - series-level external identifier
- `externalOccurrenceKey` - instance-level external identifier

These fields are optional and do not imply that every action has an external schedule source.

### ICS Mapping (Profile-Level)

In the ICS integration profile, these map as follows:

- `externalScheduleId <- VEVENT.UID`
- `externalOccurrenceKey <- RECURRENCE-ID` (or canonicalized occurrence datetime when recurrence-id is absent)

This mapping belongs to the integration contract, not the core ontology definition.
