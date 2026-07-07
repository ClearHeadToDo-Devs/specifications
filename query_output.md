---
title: query output specification
description: The single JSON-LD output contract for query and view results, consumed identically by clients and integration partners
author: primary_desktop
categories: Reference
created: 2026-07-05T00:00:00-0800
updated: 2026-07-05T00:00:00-0800
version: 1.0.0
---

This specification defines the shape of **query and view output** — the result of
running a saved or ad-hoc query against a workspace graph. It is the contract every
consumer conforms to, whether a UI client building a navigable list or an
integration partner federating the data.

It does **not** define the vocabulary or the JSON-LD `@context` — those are owned by
[ontology.md](./ontology.md) and the `ontology/` artifacts. This document defines how
query output *applies* them. Node identity conventions follow
[reference_syntax.md](./reference_syntax.md).

## Core Principle: one payload, every consumer

A query emits **one** JSON-LD document. There is no per-consumer serialization.
Simple clients read the `@graph` array and ignore the rest; semantic consumers honor
the `@context`. Forking the payload by consumer is prohibited — a bespoke shape for a
client that differs from what an integration partner receives is the drift this
contract exists to prevent. Meaning travels with the data everywhere; consumers **opt
out of depth**, never into it.

# Scope

Covers:

- Serialization of entity/view results (lists, trees, networks of identified things).
- Identity, ordering, and shape conventions.
- The producer/consumer seam: what the query engine emits vs. what a client renders.

Does **not** cover:

- The `@context`/vocabulary — see [ontology.md](./ontology.md).
- Pure aggregate/analytic results (COUNT, AVG, GROUP BY) — see
  [Aggregates](#aggregates-out-of-scope).
- How any client renders the output (quickfix list, DOT graph, cards) — a client
  concern by design.

# The Contract

## Identity is `@id`

Every node carries an `@id` equal to its **canonical workspace identity** (the IRI the
graph knows it by; see [reference_syntax.md](./reference_syntax.md)). `@id` is:

- the join key between a displayed entry and the thing it refers to,
- the address a mutation verb targets,
- **never** a throwaway or presentation-local identifier.

A consumer holding a node's `@id` can act on exactly that node.

## Query form follows data shape

Serialization is JSON-LD regardless; the SPARQL *form* follows the natural shape of the
data:

- **`SELECT`** — for ordered lists and trees. Bindings are framed into `@graph` nodes;
  one projected variable binds the node IRI (`@id`).
- **`CONSTRUCT`** — for genuine networks (nodes with many edges). Emits an RDF graph
  serialized directly as JSON-LD.

Choosing JSON-LD does **not** force `CONSTRUCT`. Order-bearing views stay `SELECT` — a
`CONSTRUCT` result is a set of triples and cannot carry row order.

## Shape is edge count

List, tree, and network are not distinct formats. They are the same node-set differing
only in how many `@id`-valued edge properties each node carries:

- **list** — no edge properties,
- **tree** — one hierarchical edge (e.g. `parent`),
- **network** — several edges.

The serialization is identical; a renderer chooses its widget from the edges present.

## Ordering

A graph is unordered; the agenda and similar views are ordered. Order is carried two
ways, belt and suspenders:

1. `@graph` is a JSON array; a `SELECT`'s `ORDER BY` is preserved in array position,
   which direct JSON readers consume as-is.
2. The sort keys are **also** emitted as node properties, so a consumer that
   round-trips through an RDF store (where `@graph` is a set and array order is not
   guaranteed) can recover the ordering.

Producers **MUST** emit sort keys as properties for any ordered view. Consumers **MAY**
rely on array order for direct reads.

## Contract validation

Each response type declares the node properties its consumer requires — identity,
locator, display fields, sort keys. The engine validates output against the declared
contract and errors clearly when properties are missing. It does **not** compose,
inject, or repair: a query either satisfies its contract or fails loudly.

# The Seam

The query engine is a **stateless producer**. It runs SPARQL and emits the JSON-LD
document; it holds no session and no mutable result set.

Mutation is a separate set of **verbs addressed by `@id`** (complete, update,
cancel, …), each a targeted, single-node, single-file write.

"Living" views are not an engine feature. They are the client composing
**read → act → re-read**: run the query, fire a verb by `@id`, re-run the query. A human
editor, an agent, and a GUI drive the *identical* loop over the *identical* primitives.
This is the test of the seam: if any consumer needs an endpoint the others don't get,
the seam has leaked.

The engine **MUST NOT** know about client widgets. Output named after one client's
widget (e.g. a "quickfix list") is a leak; the contract is client-neutral — identified
nodes plus locator, display, and sort-key properties — and each client maps it to its
own substrate.

## Errors as data

Verb failures (already-complete, not-found, conflict) are returned as structured,
branchable results, not prose on stderr, so an automated loop can respond rather than
guess.

# Aggregates (out of scope)

Pure aggregate/analytic queries (COUNT, AVG, GROUP BY, completion velocity) return
computed values with no identity — nothing to navigate to, nothing to address. They are
the deliberate exception to the one-payload rule: they use `SELECT` and return
scalar/tabular results, not a JSON-LD node set.

> **Open:** whether aggregate results ever warrant wrapping as observation nodes (so
> they too carry `@id` and rejoin the graph) is deferred to the analytics/review work,
> not settled here.
