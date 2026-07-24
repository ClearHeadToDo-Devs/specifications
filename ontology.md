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

## RDF Graph Layer

This section documents how the ontology manifests in the runtime Oxigraph store.
It is the normative reference for anyone writing SPARQL queries, extending the
graph module, or building a new client that needs to read clearhead graph data.

### Named Graph Isolation

Every workspace occupies exactly one RDF named graph.  No workspace data is
ever written to `DefaultGraph`.  The named graph URI for a workspace is:

```
urn:clearhead:workspace:<uuid>
```

where `<uuid>` is the stable `workspace_id` from `.clearhead/workspace.json`,
generated once by `clearhead init`.  See [Workspace — Named Graph
Isolation][workspace-graphs] for how that UUID is created and why it must
never be regenerated.

`DefaultGraph` is only correct in two specific contexts:

| Context | Why `DefaultGraph` is acceptable |
|---|---|
| Archive serialization (`load_acts_into_store`, `serialize` module) | A single-use transient store written directly to Turtle; never queried via SPARQL. |
| Test stores that explicitly cover the archive/serialization path | Same reason. |

Everywhere else — CLI query paths, named query smoke tests, multi-workspace
loading, new graph-layer code — use a named graph URI.  Any test that loads
into `DefaultGraph` and then queries via SPARQL is testing a configuration
that never occurs in production.

### SPARQL Evaluator Behaviour

The evaluator is configured with a **union default graph**: triple patterns
without an explicit `GRAPH` clause match across all named graphs in the store.
This is applied automatically for any query that does not declare its own
`FROM` / `FROM NAMED` dataset.

This means the same `.sparql` file works correctly in single-workspace and
multi-workspace contexts without modification: in a single-workspace store
there is one named graph; in a multi-workspace store there are several, and the
union includes all of them.

### SPARQL Query Conventions

#### Omit `GRAPH ?g` for standard queries

The recommended style for built-in named queries is no explicit `GRAPH` clause:

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

All files in `clearhead-cli/src/queries/*.sparql` follow this convention.

#### Use `GRAPH ?g` for workspace-aware queries

Add a `GRAPH` clause when the query needs to expose or constrain the source
workspace:

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

### Canonical Term Reference

The following table is the authoritative cross-reference between domain
entities and their RDF representation in `v4`.  All predicates use the prefix
`actions: <https://clearhead.us/vocab/actions/v4#>` unless otherwise noted.

| Domain Entity | `rdf:type` | Key predicates |
|---|---|---|
| Charter | `actions:Charter` | `rdfs:label`, `actions:hasUUID`, `actions:hasAlias`, `actions:hasCharterState`, `bfo:BFO_0000051` (hasPart → Plans / Actions) |
| Plan | `cco:ont00000974` | `rdfs:label`, `actions:hasUUID`, `actions:hasRecurrenceRule`, `actions:hasExternalScheduleId`, `cco:ont00001942` (prescribes → Actions) |
| Action | `actions:Action` | `rdfs:label`, `actions:hasUUID`, `cco:ont00001868` (status), `cco:ont00001920` (prescribedBy → Plan), `bfo:BFO_0000050` (partOf → parent Action) |
| Context (tag) | `actions:Context` | `actions:hasContextIdentifier`, `actions:contextBroader` (child→parent), `actions:contextNarrower` (parent→child) |

**Status values** are IRIs: `actions:NotStarted`, `actions:InProgress`,
`actions:Completed`, `actions:Blocked`, `actions:Cancelled`.

The CCO property identifiers (`ont00000974`, `ont00001868`, etc.) are stable
and normative — they come from the Common Core Ontologies and must not change
without a coordinated update to the ontology repo, the constants in
`clearhead-core/src/graph/mod.rs`, and every `.sparql` query file.  Any drift
between those three locations produces **silent empty results** — the query
executes successfully but matches no triples because the predicate IRI has
changed.  This is why the named query smoke tests in
`clearhead-core/tests/graph_queries.rs` exist: they catch this drift
automatically.

### Testing the Graph Layer

New graph-layer code and new named queries each require a corresponding test:

| What you added | What to add |
|---|---|
| A new `insert_*` function or new triple emitted from an existing one | A unit test in `graph/insert.rs` that loads into `TRANSIENT_GRAPH_URI` and asserts the triple is present via `quads_for_pattern(…, None)` (any graph). |
| A new reconstruction path in `query.rs` | A roundtrip test in `graph/query.rs`: load a model → load into store with transient graph → `load_domain_model_from_store` → assert the field is preserved. |
| A new `.sparql` named query file | A smoke test in `tests/graph_queries.rs` using `include_str!`.  Assert non-empty results against the fixture workspace.  If the query is legitimately empty for the fixture (e.g. it filters by a date in the future), document *why* rather than letting it silently pass. |
| A new multi-workspace code path | A test in `clearhead-cli/src/lib.rs` similar to `multi_workspace_tests` that spins up two temp workspaces and asserts cross-workspace query results. |

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
