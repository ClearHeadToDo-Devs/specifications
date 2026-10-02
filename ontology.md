# Ontology & Linked Data

> **Draft** (platform Decision 43, charter emit-the-ontology). This replaces the v4 term reference. Until implementations move, they still emit v4; the sections marked *unchanged* already hold.

What ClearHead's data means is defined by the [ClearHead ontology](https://github.com/ClearHeadToDo-Devs/ontology): CCO v2.2 and IAO terms, nothing of ClearHead's own, described in its [domain reference](https://github.com/ClearHeadToDo-Devs/ontology/blob/main/docs/domain.md). This specification defines how a workspace is **represented** in those terms: which RDF a conforming implementation publishes for each field of each file. The ontology owns meaning; this document owns the mapping; the SHACL shapes in [`schemas/`](./schemas/) test it (Decision 42).

## Canonical RDF Dataset

*Unchanged.* This is the normative, **engine-neutral** contract for the RDF that ClearHead publishes. A conforming implementation produces this dataset from a validated workspace whether or not any SPARQL engine is present.

The single projection is authoritative for every ClearHead RDF statement. JSON-LD is a serialization of this same dataset, never a second export path, and it MUST preserve the same facts and graph identity.

### Publication Boundary

*Unchanged.*

- The plaintext workspace is the only canonical write model. RDF is a deterministic, replaceable **snapshot** of it.
- The read path is one-way: `plaintext workspace -> validated domain model -> RDF dataset`.
- Missing triples are **not** workspace deletions; external graph mutations do **not** sync back into plaintext.
- There is no generic RDF import, no remote endpoint proxy, and no round-trip that recovers workspace *source* (files, line layout, formatting) from RDF.
- Query results address mutation verbs through the same `urn:uuid:...` identities the CLI accepts.

### Named Graph Identity

*Unchanged.* Every workspace occupies exactly one named graph, `urn:clearhead:workspace:<uuid>`, where `<uuid>` is the stable `workspace_id` from `<data_root>/workspace.json` (see [Workspace — Named Graph Isolation][workspace-graphs]). TriG and N-Quads preserve it; Turtle and compact JSON-LD carry one graph and lose it.

## Conventions

These rules decide every row of the mapping below.

1. **Meaning the competency questions reason over uses the ontology's patterns.** State, priority, conditions (waits, contexts, energy, times), parts, objectives and records are CCO/IAO structures, as the domain reference gives them.
2. **Facts about the record itself are Dublin Core annotations.** A long description and when an entry was written are metadata about an information entity: `dcterms:description` and `dcterms:created`, used as annotation properties, the way CCO annotates its own terms. Annotations carry no logical meaning, so the reasoner ignores them; they add no nodes and mint nothing.
3. **The graph carries no storage facts.** No file paths, line numbers, workspace roots or calendar identifiers (`UID`, `RECURRENCE-ID`): they describe where a copy is kept, not the work, and would not exist in another backend. Queries return identities; where an entity is stored is answered by the implementation that stores it, from those identities. The workspace's identity stays, as the named graph.
4. **Literal values sit on a bearer.** As CCO requires, a measurement or description carries its value through an Information Bearing Entity (`cco:ont00000253`) that `is carrier of` it (`obo:BFO_0000101`), with `has text value` (`cco:ont00001765`), `has integer value` (`cco:ont00001773`) or `has datetime value` (`cco:ont00001767`).
5. **Containment is published downward.** A whole `has continuant part` (`obo:BFO_0000178`) each part; the inverse is derivable and not emitted.
6. **Every node has a deterministic IRI.** Entities from files use `urn:uuid:<id>`. A helper node (a condition, a measurement, a bearer, an act) is `urn:uuid:<UUIDv5(owner id, role)>`, where the role is a fixed path such as `priority`, `priority/value` or `condition/context/<slug>`, so exports diff cleanly and no blank nodes appear.
7. **One condition per Performance Specification.** Each wait, context, energy level or time is its own Performance Specification (`cco:ont00000127`) whose parts are the action and one Descriptive ICE (`cco:ont00000853`) that `describes` (`cco:ont00001982`) the condition.

Prefixes: `cco:` `https://www.commoncoreontologies.org/`, `obo:` `http://purl.obolibrary.org/obo/`, `dcterms:` `http://purl.org/dc/terms/`, `skos:` `http://www.w3.org/2004/02/skos/core#`, `rdfs:` as usual.

## Actions

An action (one line of a [`.actions` file](./action_file_format.md)) is an IAO action specification, `obo:IAO_0000007`. Fields are those of [`actions.schema.json`](./schemas/actions.schema.json).

| Field | DSL | Representation |
| --- | --- | --- |
| `id` | `#` | The IRI, `urn:uuid:<id>`. No separate id triple. |
| `name` | text | `rdfs:label`. |
| `description` | `$ … $` | `dcterms:description` (convention 2). |
| `state` | `[ ]` … | See [Action state](#action-state). |
| `priority` | `!` | A Priority Measurement ICE (`cco:ont00000369`) that `is an ordinal measurement of` (`cco:ont00001811`) the action; integer on its bearer, 1 first. |
| `contexts` | `+` | Per tag, a condition describing the [context](#contexts). |
| `scheduledDateTime` | `@` | A condition: not before this time. The datetime sits on the condition's bearer, not on a BFO temporal instant designated through a CCO identifier, which would add two nodes per time. |
| `dueDateTime` | `:` | A condition: by this time; datetime on the condition's bearer. |
| `durationMinutes` | `D` | A Measurement ICE (`cco:ont00001163`) `is about` (`cco:ont00001808`) the action, integer on its bearer, `uses measurement unit` (`cco:ont00001863`) Minute (`cco:ont00001667`). |
| `predecessors` | `<` | Per predecessor, a condition describing the predecessor action. |
| `sequentialChildren` | `~` | Expanded: each child after the first gets a condition describing the child before it. The marker itself is not emitted. |
| `parentId`, `children` | `>` | The parent `has continuant part` the child. A top-level action is a part of its charter. |
| `charter` | `*` | No triple: membership is the containment above. |
| `alias` | `=` | A Designative Name (`cco:ont00000003`) that `designates` (`cco:ont00001916`) the action; text on its bearer. |
| `createdDateTime` | `^` | `dcterms:created` (convention 2). |
| `completedDateTime` | `%` | The datetime on the bearer of the act's completed status (below). |
| `externalScheduleId`, `externalOccurrenceKey` | none | Not emitted (convention 3). |

### Action state

State is never one field in the graph (ontology Decisions 4 and 5): what is shown is derived from records.

| State | DSL | Representation |
| --- | --- | --- |
| Not started | `[ ]` | Nothing: no act, no status. |
| In progress | `[-]` | A Planned Act (`cco:ont00000228`) `prescribed by` (`cco:ont00001920`) the action, and an Event Status Nominal ICE (`cco:ont00000203`) that `is a nominal measurement of` (`cco:ont00001868`) the act, text `in progress`. |
| Completed | `[x]` | As in progress, text `completed`; the completion time, if any, as datetime on the same bearer. |
| Blocked | `[=]` | A condition describing something outside the data the action waits on: a Descriptive ICE with text `waiting` and no `describes` target. |
| Cancelled | `[_]` | A Nominal Measurement ICE (`cco:ont00000293`) that `is a nominal measurement of` the action itself, text `cancelled`. |

## Charters

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

## Objectives

An objective (an [objective file](./objectives.md)) is an Objective, `cco:ont00000476`.

| Field | Representation |
| --- | --- |
| `id` | The IRI. |
| title, body, `alias` | As for charters. |
| `parent` | The parent objective `has continuant part` this one. |
| `state` | A Nominal Measurement ICE of the objective, confirmed by an agent (ontology Decision 5). |
| `metrics` | Per metric, a Descriptive ICE `is about` the objective, carrying the metric's name and target as text: its done-condition. |

## Contexts

A plus-tag names a context: where, with what or by whom an action can be done (Decision 43). The set is open. Each tag is one node, `urn:uuid:<UUIDv5(context namespace, slug)>`, with `rdfs:label` the slug (leading `+` stripped, trimmed, lowercased, spaces to `-`). It is not typed: a tag may name a site, a tool, a person or a state of the doer, and the projection cannot know which. Hierarchies from workspace configuration are `skos:broader`, child to parent. This makes each context a `skos:Concept` by inference, which is harmless while SKOS is not merged with BFO for reasoning.

## Recurring plans

A recurring schedule (an [`.ics` plan](./ics_schedule_spec.md)) is an action specification that prescribes many acts (ontology Decision 6), a part of its charter. Its recurrence is a time condition like any other (convention 7), one that repeats: the condition's description carries the RFC 5545 `RRULE` as text on its bearer, and the due recurrence likewise. This specification owns the rule's semantics; the graph does not take it apart. No BFO-family ontology structures a recurrence rule (searched CCO v2.2, IAO and the OBO library, 2026-10-01); the structured alternatives, schema.org `Schedule` and the W3C RDF Calendar `ical:rrule`, sit outside it. Cost: a query cannot tell a recurring condition from a one-off one except by its text. Revisit if a question ever needs to reason inside a rule.

Each materialized occurrence is its own action specification, a part of the recurring one, with its own scheduled or due condition. When an occurrence is done, its act is the calendar event: a Planned Act in its temporal region, as for any action.

## Worked example

The line

```text
[-] Call the plumber !2 +phone @2026-10-03T09:00 =plumber #01a0faa2-0000-7000-8000-000000000001
```

projects as follows. Helper IRIs are shortened to `:a.<role>`; each is a UUIDv5 under convention 6.

```turtle
:a a obo:IAO_0000007 ; rdfs:label "Call the plumber" .

:a.priority a cco:ont00000369 ; cco:ont00001811 :a .
:a.priority.value a cco:ont00000253 ; obo:BFO_0000101 :a.priority ; cco:ont00001773 2 .

:a.condition.context.phone a cco:ont00000127 ; obo:BFO_0000178 :a , :a.condition.context.phone.d .
:a.condition.context.phone.d a cco:ont00000853 ; cco:ont00001982 :phone .
:phone rdfs:label "phone" .

:a.condition.scheduled a cco:ont00000127 ; obo:BFO_0000178 :a , :a.condition.scheduled.d .
:a.condition.scheduled.d a cco:ont00000853 .
:a.condition.scheduled.value a cco:ont00000253 ; obo:BFO_0000101 :a.condition.scheduled.d ;
    cco:ont00001767 "2026-10-03T09:00:00"^^xsd:dateTime .

:a.alias a cco:ont00000003 ; cco:ont00001916 :a .  # designates
:a.alias.value a cco:ont00000253 ; obo:BFO_0000101 :a.alias ; cco:ont00001765 "plumber" .

:a.act a cco:ont00000228 ; cco:ont00001920 :a .
:a.act.status a cco:ont00000203 ; cco:ont00001868 :a.act .
:a.act.status.value a cco:ont00000253 ; obo:BFO_0000101 :a.act.status ; cco:ont00001765 "in progress" .
```

Twenty-odd triples for one line, against eight in v4. That is the trade-off Decision 43 accepted.

## Determinism

*Unchanged in substance.* For a given workspace, a given serialization is byte-deterministic: node order is stable and documented, every datetime uses one canonical RFC 3339 form, and helper IRIs follow convention 6.

## Optional Local SPARQL Evaluation

*Unchanged.* This section is **non-normative to the dataset**: running SPARQL locally over exactly the dataset defined above, as an optional convenience. The evaluator loads only ClearHead's generated dataset into an ephemeral in-memory store, runs one query, and exits. Saved queries are ordinary `.sparql` files that MUST also run unchanged in independent SPARQL tooling.

### Union Default Graph

The evaluator uses a **union default graph**: triple patterns without a `GRAPH` clause match across all named graphs, so the same query works over one workspace or several. Use `GRAPH ?g` only when a query must expose or constrain the source workspace. A test that loads into the default graph and then queries via SPARQL tests a configuration that never occurs in production.

## Source Boundary: Ontology vs Integration Profiles

*Unchanged.* The ontology stays source-agnostic; integration profiles such as `.ics` carry source-specific semantics. When actions are generated from an external schedule, implementations preserve the link through two optional fields, mapped in the ICS profile as:

- `externalScheduleId <- recurring VTODO.UID`
- `externalOccurrenceKey <- RECURRENCE-ID` (or the canonicalized occurrence datetime when it is absent)

[workspace-graphs]: ./workspace.md#named-graph-isolation
