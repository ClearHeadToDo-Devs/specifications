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

## Canonical RDF Dataset

This is the normative, **engine-neutral** contract for the RDF that ClearHead
publishes. A conforming implementation produces this dataset from a validated
`DomainModel` whether or not any SPARQL engine is present. The optional local
evaluator described further down is *one consumer* of this dataset, not its
definition, and nothing here depends on a database being installed.

The single projection is authoritative for every ClearHead RDF statement.
JSON-LD is a serialization of this same dataset — compact framing may reorder or
rename terms per format, but it MUST preserve the same facts and the same graph
identity. There is no second, hand-built export path.

### Publication Boundary

- The plaintext workspace is the only canonical write model. RDF is a
  deterministic, replaceable **snapshot** of the validated domain model.
- The read path is one-way:
  `plaintext workspace -> validated DomainModel -> RDF dataset`.
- Missing triples are **not** workspace deletions; external graph mutations do
  **not** sync back into plaintext.
- There is no generic RDF import, no arbitrary-Turtle loading surface, no remote
  endpoint proxy, and no round-trip that recovers workspace *source* (files,
  line layout, formatting) from RDF.
- Query results address ordinary mutation verbs through the same canonical
  `urn:uuid:...` identities the CLI already accepts.

### Named Graph Identity

Every workspace occupies exactly one RDF named graph. The named graph IRI for a
workspace is:

```text
urn:clearhead:workspace:<uuid>
```

where `<uuid>` is the stable `workspace_id` from `.clearhead/workspace.json`,
generated once by `clearhead init` and never regenerated. See
[Workspace — Named Graph Isolation][workspace-graphs] for how that UUID is
created and why it must remain stable.

Dataset-capable syntaxes (**TriG**, **N-Quads**) preserve this named graph, so a
multi-workspace export keeps each workspace addressable and separable. Graph-only
syntaxes (Turtle, and compact JSON-LD) serialize a single graph's statements and
therefore do **not** carry the named-graph identity; they are offered only where
that loss is acceptable and their contract is well-defined.

### Entity Scope and Identity

The canonical dataset projects five entities:

| Entity | IRI shape |
|---|---|
| Charter | `urn:uuid:<uuid>` |
| Plan | `urn:uuid:<uuid>` |
| Action | `urn:uuid:<uuid>` |
| Context (tag) | `urn:context:<slug>` |
| Workspace | `urn:clearhead:workspace:<uuid>` |

Context `<slug>` normalization: leading `+` stripped, trimmed, lowercased,
internal spaces replaced with `-`.

**Objective is reserved but not yet projected.** The ontology-out contract
(`ontology/v4/ONTOLOGY_OUT_CONTRACT.md`) declares `Objective` (and
`ContextType`) in the canonical seam, but the current projection emits no
Objective statements. This is a known, tracked gap, not a silent omission: the
platform projection scope is the five entities above until Objective projection
is deliberately added. The ontology repository remains the authority for the
*term* vocabulary regardless of what the platform currently emits.

### Canonical Term Reference

The following table is the authoritative cross-reference between domain entities
and their RDF representation in `v4`. All predicates use the prefix
`actions: <https://clearhead.us/vocab/actions/v4#>` unless otherwise noted.

| Domain Entity | `rdf:type` | Key predicates |
|---|---|---|
| Charter | `actions:Charter` | `rdfs:label`, `actions:hasUUID`, `actions:hasAlias`, `actions:hasCharterState`, `actions:hasSubCharter` (parent → child), `bfo:BFO_0000051` (hasPart → Plans / Actions) |
| Plan | `cco:ont00000974` | `rdfs:label`, `actions:hasUUID`, `actions:hasRecurrenceRule`, `actions:hasExternalScheduleId`, `cco:ont00001942` (prescribes → Actions) |
| Action | `actions:Action` | `rdfs:label`, `actions:hasUUID`, `cco:ont00001868` (status), `cco:ont00001920` (prescribedBy → Plan), `cco:ont00001916` (isSuccessorOf → predecessor Action), `bfo:BFO_0000050` (partOf → parent Action), `actions:requiresContext` (→ Context) |
| Context (tag) | `actions:Context` | `actions:hasContextIdentifier`, `actions:contextBroader` (child→parent), `actions:contextNarrower` (parent→child) |
| Workspace | `ws:Workspace` | `rdfs:label`, `actions:hasAlias`, `ws:root`, `ws:charterRoot` |

**Status values** are IRIs: `actions:NotStarted`, `actions:InProgress`,
`actions:Completed`, `actions:Blocked`, `actions:Cancelled`.

The CCO property identifiers (`ont00000974`, `ont00001868`, etc.) are stable and
normative — they come from the Common Core Ontologies and must not change
without a coordinated update to the ontology repo, the constants in the Core RDF
module, and every `.sparql` query file. Any drift between those locations
produces **silent empty results**: the query executes successfully but matches
no triples because the predicate IRI changed. Named-query smoke tests exist to
catch this drift automatically.

### Datatypes

- Date-times use `xsd:dateTime` with a single canonical RFC3339 representation
  (`hasScheduledDateTime`, `hasDueDateTime`, `hasCompletedDateTime`,
  `hasCreatedDateTime`).
- Counts use `xsd:integer` (`hasPriority`, `hasDurationMinutes`, source line).
- Sequential flag uses `xsd:boolean` (`hasSequentialChildren`).
- Identifiers and provenance strings use `xsd:string`; `rdfs:label` /
  `rdfs:comment` are plain literals.

### Determinism

- Node ordering is stable and documented: by type rank, then lexical identifier.
- A single canonical RFC3339 representation is used for every datetime literal.
- For a given `DomainModel`, a given serialization is byte-deterministic, so
  exports are diffable and testable.

### Provenance and Reconstruction

- `ws:hasSourceFile` / `ws:hasSourceLine` are **workspace-snapshot** properties,
  valid for the current filesystem state and intended for editor integration
  (quickfix, jump-to-source). They are not portable cross-machine identity and
  are not required to reconstruct the domain model.
- The projected entity scope reconstructs to *equivalent domain data* — the
  semantic reconstruction scope is the five entities above, **not** the workspace
  source layout. Recovering files or formatting from RDF is explicitly out of
  scope (see Publication Boundary).

### Authoritative Artifacts

- `ontology/v4/*` is canonical: `actions.context.json`, `actions.schema.json`,
  `actions-vocabulary.owl`, `actions-shapes-v4.ttl`, and
  `ONTOLOGY_OUT_CONTRACT.md`.
- Any `*.v4.*` files vendored inside an implementation (for example under a
  graph module's `resources/`) are **copies for offline stability**, not a second
  authority. They must be verified against `ontology/v4`, never forked from it.

## Optional Local SPARQL Evaluation

This section is **non-normative to the dataset**. It describes an *optional
convenience*: running SPARQL locally over exactly the dataset defined above. The
evaluator is not a ClearHead backend, not a persistence layer, and not required
for RDF publication — a minimal build has no query engine at all. Its behavior
below constrains how queries are written, not what the canonical dataset
contains.

The evaluator loads only ClearHead's generated dataset (and trusted bundled
ontology/shape resources required by the contract) into an ephemeral in-memory
store, runs one query, and exits. It does not persist state, load arbitrary
foreign RDF, federate, or proxy remote endpoints. Complete saved queries are
ordinary `.sparql` files that MUST also run unchanged in independent SPARQL
tooling.

### Union Default Graph

The evaluator is configured with a **union default graph**: triple patterns
without an explicit `GRAPH` clause match across all named graphs in the store.
This is applied automatically for any query that does not declare its own
`FROM` / `FROM NAMED` dataset.

The same `.sparql` file therefore works in single- and multi-workspace contexts
without modification: a single-workspace store has one named graph; a
multi-workspace store has several, and the union includes all of them.

### Query Conventions

**Omit `GRAPH ?g` for standard queries.** The recommended style for built-in
named queries is no explicit `GRAPH` clause:

```sparql
PREFIX actions: <https://clearhead.us/vocab/actions/v4#>
PREFIX cco:     <https://www.commoncoreontologies.org/>
PREFIX rdfs:    <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?name WHERE {
    ?act a actions:Action ;
         rdfs:label ?name ;
         cco:ont00001868 actions:NotStarted .
}
```

**Use `GRAPH ?g` for workspace-aware queries** — when the query needs to expose
or constrain the source workspace:

```sparql
-- identify which workspace each action came from
SELECT ?workspace ?name WHERE {
    GRAPH ?workspace {
        ?act a actions:Action ; rdfs:label ?name .
    }
}

-- scope to a single workspace
SELECT ?name WHERE {
    GRAPH <urn:clearhead:workspace:019e43e4-e0bb-7f91-9d37-9f769a35108a> {
        ?act a actions:Action ; rdfs:label ?name .
    }
}
```

`DefaultGraph` is only appropriate for single-use transient stores written
directly to Turtle and never queried via SPARQL (for example archive
serialization). Any test that loads into `DefaultGraph` and then queries via
SPARQL is testing a configuration that never occurs in production; use a named
graph IRI everywhere else.

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

- `externalScheduleId <- recurring VTODO.UID`
- `externalOccurrenceKey <- RECURRENCE-ID` (or canonicalized occurrence datetime when recurrence-id is absent)

This mapping belongs to the integration contract, not the core ontology definition.

[workspace-graphs]: ./workspace.md#named-graph-isolation
