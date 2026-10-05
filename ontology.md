# Ontology & Linked Data

> **Draft** (platform Decisions 45 to 53, charter emit-the-ontology). Implementations publish the application graph defined here; v4 is retired.

A conforming implementation publishes a workspace as the **application graph**: RDF in ClearHead's application vocabulary, `app:`, defined here. It is what queries read and what an export writes. What each `app:` term *means* is defined by its mapping to CCO v2.2 and IAO terms, the [ClearHead ontology](./ontology/) (see its [domain reference](./ontology/domain.md)); an `app:` term asserts nothing its mapping does not, and every term has one. The [CCO graph](#meaning-the-cco-graph) below is that meaning, written out for the conformance fixture. The SHACL shapes in [`schemas/`](./schemas/) test both graphs (Decision 42).

## Canonical RDF Dataset

This is the normative, **engine-neutral** contract for the RDF that ClearHead publishes. A conforming implementation produces this dataset from a validated workspace whether or not any SPARQL engine is present.

The single projection is authoritative for every ClearHead RDF statement. JSON-LD is a serialization of this same dataset, never a second export path, and it MUST preserve the same facts and graph identity.

### Publication Boundary

- The plaintext workspace is the only canonical write model. RDF is a deterministic, replaceable **snapshot** of it.
- The read path is one-way: `plaintext workspace -> validated domain model -> RDF dataset`.
- Missing triples are **not** workspace deletions; external graph mutations do **not** sync back into plaintext.
- There is no generic RDF import, no remote endpoint proxy, and no round-trip that recovers workspace *source* (files, line layout, formatting) from RDF.
- Query results address mutation verbs through the same `urn:uuid:...` identities the CLI accepts.

### Named Graph Identity

Every workspace occupies exactly one named graph, `urn:clearhead:workspace:<uuid>`, where `<uuid>` is the stable `workspace_id` from `<data_root>/workspace.json` (see [Workspace — Named Graph Isolation][workspace-graphs]). TriG and N-Quads preserve it; Turtle and compact JSON-LD carry one graph and lose it.

## Application Graph

Namespace `https://clearhead.dev/vocab/app/v1#`, prefix `app:`. Also used: `rdfs:` `http://www.w3.org/2000/01/rdf-schema#`, `dcterms:` `http://purl.org/dc/terms/`, `skos:` `http://www.w3.org/2004/02/skos/core#`, `xsd:` `http://www.w3.org/2001/XMLSchema#`.

### Rules

1. **Standard terms where they fit.** A name is `rdfs:label`, a description `dcterms:description`, a creation time `dcterms:created`, a context hierarchy `skos:broader`. `app:` names only what ClearHead adds.
2. **Written and derived terms.** A written term carries a value as the file states it. A derived term is computed from the files and the viewer's context (the zone in [Time](#time)), so queries need not recompute it; it is never written back, and it is mapped to CCO like any other term. Each derived term below says how it is computed.
3. **Where an entity is kept.** `app:file` is the path of the file holding it, relative to the data root (the directory holding `charters/`, `plans/` and `objectives/`), with `/` separators and no leading `./`. `app:line` is the 1-based line where an action starts. The graph names no root; a client resolves paths against the data root it already knows. If another backend has no files, these are absent.
4. **IRIs.** An entity from a file is `urn:uuid:<id>`. A context is `urn:uuid:<UUIDv5(context namespace, slug)>` (see [Context terms](#context-terms)). A metric is `urn:uuid:<UUIDv5(objective id, "metric/<slug>")>`, its slug made as a context's is. No blank nodes.
5. **Containment points up.** A part `app:partOf` its whole: a child action its parent action, a top-level action its charter, a charter its parent charter, an objective its parent objective. Each has at most one.
6. **Every action, charter and objective has exactly one `app:state`** whose value is one of the IRIs in [State values](#state-values). Absent fields emit nothing.

### Action terms

An action is `app:Action`. Fields are those of [`actions.schema.json`](./schemas/actions.schema.json).

| Field | DSL | Terms |
| --- | --- | --- |
| `id` | `#` | The IRI. |
| `name` | text | `rdfs:label` |
| `description` | `$ … $` | `dcterms:description` |
| `state` | `[ ]` … | `app:state` (below) |
| `priority` | `!` | `app:priority`, an integer |
| `contexts` | `+` | `app:context`, per tag, its context node |
| `scheduledDateTime` | `@` | `app:plannedStart`, written: when the action is planned; and `app:plannedEnd`, written, the block's end when `@` is an interval. Intent: bounds nothing (Decisions 48 and 51) |
| `dueDateTime` | `:` | `app:due`, the deadline as written, and `app:availableFrom`, the window's lower bound as written when `:` is an interval; see [Time](#time) |
| `completedDateTime` | `%` | `app:closed`, written: when the action was completed or cancelled |
| `createdDateTime` | `^` | `dcterms:created`, written |
| `predecessors` | `<` | `app:after`, per reference, the action it names; see [Waits](#waits) |
| `sequentialChildren` | `~` | `app:sequential true` |
| `parentId`, `charter` | `>`, the file | `app:partOf` (rule 5) |
| `alias` | `=` | `app:alias` |
| `externalScheduleId`, `externalOccurrenceKey` | none | Not emitted. |

Derived: `app:notBefore`, `app:lateFrom`, `app:plannedFrom`, `app:durationMinutes` ([Time](#time)) and `app:waitsOn` ([Waits](#waits)). Location: `app:file`, `app:line`.

### State values

| Entity | `app:state` values |
| --- | --- |
| Action | `app:NotStarted` `[ ]`, `app:InProgress` `[-]`, `app:Blocked` `[=]`, `app:Completed` `[x]`, `app:Cancelled` `[_]` |
| Charter | `app:New`, `app:Active`, `app:Blocked`, `app:Closed`, `app:Cancelled`, from its `state` (`app:New` when unset) |
| Objective | Not yet defined ([objectives](./objectives.md) gives objectives a state without naming its values); none is emitted. |

### Time

`app:plannedStart`, `app:plannedEnd`, `app:availableFrom`, `app:due`, `app:closed` and `dcterms:created` are **as written**: a date alone is an `xsd:date`; a date and time is an `xsd:dateTime` of the form `YYYY-MM-DDThh:mm:ss`, with an offset or `Z` only if the file wrote one.

The window is `:` alone; `@` is intent and bounds nothing (Decision 48). A date covers its day and a time is an instant (Decisions 47 and 51). The derived instants say when an action's **effective window** opens and closes, each an `xsd:dateTime` with an offset:

- `app:notBefore`: the first instant the action may be worked. The latest of its own `app:availableFrom` and every ancestor action's, taking a date's first instant.
- `app:lateFrom`: the first instant the action is late. The earliest of its own `app:due` and every ancestor action's, taking where it ends: a date's following midnight, a time itself.

A child with no bound of its own therefore inherits its parent's, and one with its own narrows it ([action file format](./action_file_format.md#due-datetime-optional)). A time written without an offset, and every date, is resolved in the **viewer's zone**, the zone in which the graph is projected, using the time-zone database. Queries compare these instants, never the written values: an `xsd:date`, a floating `xsd:dateTime` and one with an offset do not compare reliably in SPARQL.

The planned block is `@`, never inherited, and read as the window is.

- `app:plannedFrom`: the first instant of `app:plannedStart`, an `xsd:dateTime` with an offset: a date's first instant, a time itself. Queries compare it, never the written start.
- `app:durationMinutes`: the block's length in whole minutes, rounded down, from the first instant of `app:plannedStart` to the end of `app:plannedEnd` (a date's following midnight, a time itself). Emitted only for an interval of at least a minute; a single `@` value has no duration.

### Waits

`app:after` is each predecessor as written. `app:waitsOn` is derived: everything that must be closed before the action can start. It is the action's own `app:after` targets, the sibling before it when its parent is `app:sequential`, and its parent action's `app:waitsOn`. An action is free to start when every `app:waitsOn` target is completed or cancelled.

### Charter terms

A charter (a [charter document](./charters.md)) is `app:Charter`.

| Field | Terms |
| --- | --- |
| `id` | The IRI. |
| title (H1 or `title`) | `rdfs:label` |
| body text | `dcterms:description` |
| `alias` | `app:alias` |
| `parent` | `app:partOf` the parent charter |
| `objectives` | `app:serves`, per objective |
| `state` | `app:state` |
| its file | `app:file`: the charter document, or its actions file if it has none |

### Objective terms

An objective (an [objective file](./objectives.md)) is `app:Objective`.

| Field | Terms |
| --- | --- |
| `id`, title, body, `alias`, `parent` | As for charters; `app:partOf` the parent objective. |
| `metrics` | `app:metric`, per metric, an `app:Metric` with `rdfs:label` its name, `dcterms:description` and `app:target` (text) when given. |
| its file | `app:file` |

### Context terms

A plus-tag names a context: where, with what or by whom an action can be done (Decision 43). The set is open. Each tag is one `app:Context`, `urn:uuid:<UUIDv5(context namespace, slug)>`, with `rdfs:label` the slug (leading `+` stripped, trimmed, lowercased, spaces to `-`). The context namespace is the constant `0d8937ce-eb24-52d2-9532-39ea299f888b`. It was minted as the UUIDv5 of `https://clearhead.us/context` under the RFC 9562 URL namespace, while names lived at that domain, and does not move with it: changing it would rename every context node. Hierarchies from workspace configuration are `skos:broader`, child to parent; a context named only as a parent is emitted too.

### Recurrence

Not yet specified for the application graph. A materialized occurrence is an ordinary action with its own bounds; the recurring plan itself and its rule are the open part (the fixture has neither).

### Example

The line

```text
[-] Call the plumber !2 +phone @2026-10-03T09:00/2026-10-03T09:15 :2026-10-03/2026-10-04 =plumber #01a0faa2-0000-7000-8000-000000000001
```

at line 1 of `charters/next.actions`, a top-level action of the root charter, projects in a UTC viewer's zone as:

```turtle
<urn:uuid:01a0faa2-0000-7000-8000-000000000001> a app:Action ;
  rdfs:label "Call the plumber" ;
  app:state app:InProgress ;
  app:priority 2 ;
  app:context <urn:uuid:aa0d0a8e-8a8b-5ef1-b25b-f894935d2d82> ;   # phone
  app:plannedStart "2026-10-03T09:00:00"^^xsd:dateTime ;
  app:plannedEnd "2026-10-03T09:15:00"^^xsd:dateTime ;
  app:availableFrom "2026-10-03"^^xsd:date ;
  app:due "2026-10-04"^^xsd:date ;
  app:notBefore "2026-10-03T00:00:00Z"^^xsd:dateTime ;
  app:lateFrom "2026-10-05T00:00:00Z"^^xsd:dateTime ;
  app:plannedFrom "2026-10-03T09:00:00Z"^^xsd:dateTime ;
  app:durationMinutes 15 ;
  app:alias "plumber" ;
  app:partOf <urn:uuid:01a0faa2-0000-7000-8000-0000000000c0> ;   # the root charter
  app:file "charters/next.actions" ; app:line 1 .
```

## Meaning: the CCO Graph

> The mapping is [`ontology/mapping/`](./ontology/mapping/) (Decisions 45 and 50): one SPARQL CONSTRUCT per structure, run over the application graph. This section describes what it produces; the queries are authoritative. The gate checks that mapping the fixture's `expected-app.ttl` yields its `expected.ttl`, and that every application term is read by a query or listed, with why, in [`ontology/unmapped.ttl`](./ontology/unmapped.ttl).

### Conventions

These rules decide every row of the mapping below.

1. **Meaning the competency questions reason over uses the ontology's patterns.** State, priority, conditions (waits, contexts, energy, times), parts, objectives and records are CCO/IAO structures, as the domain reference gives them.
2. **Facts about the record itself are Dublin Core annotations.** A long description and when an entry was written are metadata about an information entity: `dcterms:description` and `dcterms:created`, used as annotation properties, the way CCO annotates its own terms. Annotations carry no logical meaning, so the reasoner ignores them; they add no nodes and mint nothing.
3. **The graph carries no storage facts.** No file paths, line numbers, workspace roots or calendar identifiers (`UID`, `RECURRENCE-ID`): they describe where a copy is kept, not the work, and would not exist in another backend. Queries return identities; where an entity is stored is answered by the implementation that stores it, from those identities. The workspace's identity stays, as the named graph.
4. **Literal values sit on a bearer.** As CCO requires, a measurement or description carries its value through an Information Bearing Entity (`cco:ont00000253`) that `is carrier of` it (`obo:BFO_0000101`), with `has text value` (`cco:ont00001765`), `has integer value` (`cco:ont00001773`) or `has datetime value` (`cco:ont00001767`).
5. **Containment is published downward.** A whole `has continuant part` (`obo:BFO_0000178`) each part; the inverse is derivable and not emitted.
6. **Entities keep their IRIs; helper nodes are blank** (Decision 49). Actions, charters, objectives, metrics and contexts are IRIs; a condition, description, measurement, bearer, intent or act exists only as part of its owner and nothing outside the graph refers to it, so it is a blank node. Exports that must diff byte for byte are canonicalized with RDF Dataset Canonicalization (RDFC-1.0); fixtures compare by graph isomorphism.
7. **One condition per Performance Specification.** Each wait, context, energy level or time is its own Performance Specification (`cco:ont00000127`) whose parts are the action and one Descriptive ICE (`cco:ont00000853`) that `describes` (`cco:ont00001982`) the condition.
8. **Conditions are effective.** An action carries every wait and window bound that applies to it, its own and those it inherits, read from `app:waitsOn`, `app:notBefore` and `app:lateFrom` rather than from the terms as written: one fact, one condition. An inherited condition is true of the child.

Prefixes: `cco:` `https://www.commoncoreontologies.org/`, `obo:` `http://purl.obolibrary.org/obo/`, `dcterms:` `http://purl.org/dc/terms/`, `skos:` `http://www.w3.org/2004/02/skos/core#`, `rdfs:` as usual.

### Actions

An action (one line of a [`.actions` file](./action_file_format.md)) is an IAO action specification, `obo:IAO_0000007`. Fields are those of [`actions.schema.json`](./schemas/actions.schema.json).

| Field | DSL | Representation |
| --- | --- | --- |
| `id` | `#` | The IRI, `urn:uuid:<id>`. No separate id triple. |
| `name` | text | `rdfs:label`. |
| `description` | `$ … $` | `dcterms:description` (convention 2). |
| `state` | `[ ]` … | See [Action state](#action-state). |
| `priority` | `!` | A Priority Measurement ICE (`cco:ont00000369`) that `is an ordinal measurement of` (`cco:ont00001811`) the action; integer on its bearer, 1 first. |
| `contexts` | `+` | Per tag, a condition describing the [context](#contexts). |
| `scheduledDateTime` | `@` | Intent (Decision 48): a Prescriptive ICE (`cco:ont00000965`) that is part of the action, the planned start on its bearer; a block's length is the duration below, so `app:plannedEnd` is not read. Not a condition, and no act exists until the work starts (ontology Decision 4). |
| `dueDateTime` | `:` | The effective window (convention 8): per bound, a condition whose description's bearer carries the text `not before` or `late from` and the instant, from `app:notBefore` and `app:lateFrom`. The time sits on the bearer, not on a BFO temporal instant designated through a CCO identifier, which would add two nodes per time. |
| `durationMinutes` | derived from `@` | A Measurement ICE (`cco:ont00001163`) `is about` (`cco:ont00001808`) the action; its bearer has the integer and `uses measurement unit` (`cco:ont00001863`) Minute (`cco:ont00001667`). |
| `predecessors` | `<` | Per effective wait (`app:waitsOn`, convention 8), a condition describing the awaited action. |
| `sequentialChildren` | `~` | Expanded through `app:waitsOn`: each child after the first waits on the child before it. The marker itself is not emitted. |
| `parentId`, `children` | `>` | The parent `has continuant part` the child. A top-level action is a part of its charter. |
| `charter` | `*` | No triple: membership is the containment above. |
| `alias` | `=` | A Designative Name (`cco:ont00000003`) that `designates` (`cco:ont00001916`) the action; text on its bearer. |
| `createdDateTime` | `^` | `dcterms:created` (convention 2). |
| `completedDateTime` | `%` | The time on the bearer of the record that closed the action: the act's completed status, or the cancelled measurement (below). |
| `externalScheduleId`, `externalOccurrenceKey` | none | Not emitted (convention 3). |

#### Action state

State is never one field in the graph (ontology Decisions 4 and 5): what is shown is derived from records.

| State | DSL | Representation |
| --- | --- | --- |
| Not started | `[ ]` | Nothing: no act, no status. |
| In progress | `[-]` | A Planned Act (`cco:ont00000228`) `prescribed by` (`cco:ont00001920`) the action, and an Event Status Nominal ICE (`cco:ont00000203`) that `is a nominal measurement of` (`cco:ont00001868`) the act, text `in progress`. |
| Completed | `[x]` | As in progress, text `completed`; the completion time, if any, as datetime on the same bearer. |
| Blocked | `[=]` | A condition describing something outside the data the action waits on: a Descriptive ICE with text `waiting` and no `describes` target. |
| Cancelled | `[_]` | A Nominal Measurement ICE (`cco:ont00000293`) that `is a nominal measurement of` the action itself, text `cancelled`; the cancellation time, if any, on the same bearer. |

### Charters

A charter (a [charter document](./charters.md)) is a Plan, `cco:ont00000974`.

| Field | Representation |
| --- | --- |
| `id` | The IRI. |
| title (H1 or `title`) | `rdfs:label`. |
| body text | `dcterms:description`. |
| `alias` | A Designative Name, as for actions. |
| `parent` | The parent charter `has continuant part` this one. |
| `objectives` | The charter `has continuant part` each objective. A charter with none is reported, never refused ([Objectives](./objectives.md)). |
| `state` | A Nominal Measurement ICE that `is a nominal measurement of` the plan, text `new`, `active`, `blocked`, `closed` or `cancelled`. |
| its actions | The charter `has continuant part` each top-level action. |

### Objectives

An objective (an [objective file](./objectives.md)) is an Objective, `cco:ont00000476`.

| Field | Representation |
| --- | --- |
| `id` | The IRI. |
| title, body, `alias` | As for charters. |
| `parent` | The parent objective `has continuant part` this one. |
| `state` | A Nominal Measurement ICE of the objective, confirmed by an agent (ontology Decision 5). |
| `metrics` | Per metric, a Descriptive ICE `is about` the objective, its done-condition, keeping the metric's IRI, with text `<name>: <target>` (or `<name>` with no target) on its bearer and its description as `dcterms:description`. |

### Contexts

A plus-tag names a context: where, with what or by whom an action can be done (Decision 43). The set is open. Each tag is one node, `urn:uuid:<UUIDv5(context namespace, slug)>`, with `rdfs:label` the slug (leading `+` stripped, trimmed, lowercased, spaces to `-`). It is not typed: a tag may name a site, a tool, a person or a state of the doer, and the projection cannot know which. Hierarchies from workspace configuration are `skos:broader`, child to parent. This makes each context a `skos:Concept` by inference, which is harmless while SKOS is not merged with BFO for reasoning.

### Recurring plans

A recurring schedule (an [`.ics` plan](./ics_schedule_spec.md)) is an action specification that prescribes many acts (ontology Decision 6), a part of its charter. Its recurrence is a time condition like any other (convention 7), one that repeats: the condition's description carries the RFC 5545 `RRULE` as text on its bearer, and the due recurrence likewise. This specification owns the rule's semantics; the graph does not take it apart. No BFO-family ontology structures a recurrence rule (searched CCO v2.2, IAO and the OBO library, 2026-10-01); the structured alternatives, schema.org `Schedule` and the W3C RDF Calendar `ical:rrule`, sit outside it. Cost: a query cannot tell a recurring condition from a one-off one except by its text. Revisit if a question ever needs to reason inside a rule.

Each materialized occurrence is its own action specification, a part of the recurring one, with its own scheduled or due condition. When an occurrence is done, its act is the calendar event: a Planned Act in its temporal region, as for any action.

### Helper nodes

Every node that is not an action, charter, objective, metric or context is a blank node (convention 6). A query reaches it from its owner through the pattern its row gives, never by name.

A context node keeps an IRI of its own: the UUIDv5 of its slug under the context namespace `0d8937ce-eb24-52d2-9532-39ea299f888b` (a constant; see [Context terms](#context-terms)).

### Worked example

The line

```text
[-] Call the plumber !2 +phone @2026-10-03T09:00 =plumber #01a0faa2-0000-7000-8000-000000000001
```

projects as follows, with `:a` the action and `:phone` its context; the blank-node labels are only for reading.

```turtle
:a a obo:IAO_0000007 ; rdfs:label "Call the plumber" ;
    obo:BFO_0000178 _:intent .                                    # @: planned for 09:00

_:intent a cco:ont00000965 .
_:intent-value a cco:ont00000253 ; obo:BFO_0000101 _:intent ;
    cco:ont00001767 "2026-10-03T09:00:00"^^xsd:dateTime .

_:priority a cco:ont00000369 ; cco:ont00001811 :a .
_:priority-value a cco:ont00000253 ; obo:BFO_0000101 _:priority ; cco:ont00001773 2 .

_:phone a cco:ont00000127 ; obo:BFO_0000178 :a , _:phone-condition .
_:phone-condition a cco:ont00000853 ; cco:ont00001982 :phone .
:phone rdfs:label "phone" .

_:alias a cco:ont00000003 ; cco:ont00001916 :a .                  # designates
_:alias-value a cco:ont00000253 ; obo:BFO_0000101 _:alias ; cco:ont00001765 "plumber" .

_:act a cco:ont00000228 ; cco:ont00001920 :a .
_:status a cco:ont00000203 ; cco:ont00001868 _:act .
_:status-value a cco:ont00000253 ; obo:BFO_0000101 _:status ; cco:ont00001765 "in progress" .
```

With `:2026-10-04` on the line, it would also carry a condition whose bearer holds `"late from"` and `"2026-10-05T00:00:00Z"`; its children would carry the same one unless they had an earlier deadline of their own.

### Times

A window bound is the effective instant from the application graph: `has datetime value` (`cco:ont00001767`), an `xsd:dateTime` with an offset, resolved in the viewer's zone (convention 8). Every other time is as written: an intent, a completion or cancellation time and `dcterms:created`. A date and time is `has datetime value`, an `xsd:dateTime` in the form `YYYY-MM-DDThh:mm:ss`, with the offset or `Z` only if the file wrote one; a date alone is `has date value` (`cco:ont00001771`), an `xsd:date`.

## Conformance

[`examples/conformance/graph/`](./examples/conformance/graph/) holds the oracle: a workspace and the exact graphs it projects to.

- **Application graph.** A conforming implementation, projecting in the UTC zone, produces a graph isomorphic to `expected-app.ttl`. [`schemas/app.shapes.ttl`](./schemas/app.shapes.ttl) holds its SHACL shapes, including that the derived terms agree with the written ones; `invalid-app/` holds a graph per rule that must fail on exactly the shape it names.
- **CCO graph.** `expected.ttl` is the same workspace's meaning. [`schemas/graph.shapes.ttl`](./schemas/graph.shapes.ttl) holds its SHACL shapes, validated without inference; `invalid/` holds graphs that must each fail on one named shape and `warning/` one that must pass with only a warning. Merged with the ontology, it must reason consistent.

Not yet covered by the fixture: recurring plans and objective states.

## Determinism

For a given workspace and viewer's zone, a given serialization is byte-deterministic: node order is stable and documented, and IRIs follow the rules above. Written values never depend on the machine. The derived instants `app:notBefore` and `app:lateFrom` depend on the viewer's zone wherever a time was written without an offset or a bound is a date, and so does `app:durationMinutes` for a block that crosses a change of offset; a graph exported from one zone and read in another keeps the instants of the zone that projected it.

## Optional Local SPARQL Evaluation

This section is **non-normative to the dataset**: running SPARQL locally over exactly the dataset defined above, as an optional convenience. The evaluator loads only ClearHead's generated dataset into an ephemeral in-memory store, runs one query, and exits. Saved queries are ordinary `.sparql` files that MUST also run unchanged in independent SPARQL tooling.

### Union Default Graph

The evaluator uses a **union default graph**: triple patterns without a `GRAPH` clause match across all named graphs, so the same query works over one workspace or several. Use `GRAPH ?g` only when a query must expose or constrain the source workspace. A test that loads into the default graph and then queries via SPARQL tests a configuration that never occurs in production.

## Source Boundary: Ontology vs Integration Profiles

The ontology stays source-agnostic; integration profiles such as `.ics` carry source-specific semantics. When actions are generated from an external schedule, implementations preserve the link through two optional fields, mapped in the ICS profile as:

- `externalScheduleId <- recurring VTODO.UID`
- `externalOccurrenceKey <- RECURRENCE-ID` (or the canonicalized occurrence datetime when it is absent)

[workspace-graphs]: ./workspace.md#named-graph-isolation
