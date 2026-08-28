# Data workflows: select semantically, act atomically

ClearHead keeps reading and writing as separate operations that compose through
canonical identities and published JSON contracts.

- **Read:** `clearhead query …` loads the authoritative plaintext workspace,
  asks Core for its deterministic RDF dataset, and optionally evaluates SPARQL
  in a fresh in-process store.
- **Write:** `clearhead transact` applies an ordered, atomic batch of Action
  operations through Core's mutation decisions and the native delivery adapter.
- **Contract:** [`transaction_request`](../schemas/transaction_request.schema.json)
  and [`transaction_result`](../schemas/transaction_result.schema.json).

The RDF dataset and ephemeral query store are replaceable projections. Neither
is a persistence layer or a mutation surface.

## The loop

```sh
# Complete every unscheduled action the query surfaces, in one atomic batch.
clearhead query index unscheduled --format ids \
  | jq -Rn '{operations: [inputs | {op: "complete-action", target: .}]}' \
  | clearhead transact
```

The index family's `--format ids` projection emits one canonical `urn:uuid:` per
line. `transact` accepts that spelling as an operation target, so selection does
not need a name-resolution or output-conversion shim.

### For a human

Run the query alone first, then rehearse the mutation:

```sh
clearhead query index agenda
clearhead transact request.json --dry-run
clearhead transact request.json
```

A dry run validates and prepares the complete batch without writing.

### For an agent

`transact` emits a schema-valid `transaction_result`: `committed`, `dry-run`, or
`rejected`, including the zero-based index of a failed operation. Rejection is
non-zero and leaves the authoritative workspace unchanged.

## Query ownership

`clearhead query` owns the complete query surface:

- `raw` and `named` evaluate standard SPARQL over Core's canonical dataset;
- `index`, `tree`, `graph`, and `chain` add query-family validation and
  presentation;
- `show` prints the selected SPARQL document;
- `list` reports available saved and built-in queries.

With the default `sparql` feature, evaluation uses a fresh in-memory Oxigraph
store for each invocation. The store is never persisted, federated, or exposed
as a service. A minimal CLI build omits the query engine entirely. Exported RDF
remains engine-independent and may be consumed by external SPARQL tooling.

## Mutation boundary

Transactions express intent, not filesystem patches. Core prepares semantic
changes and host-neutral effects; `clearhead-workspace-fs` validates revisions
under the native lock and delivers the complete batch durably.

The initial transaction surface remains deliberately small:

- operations are `update`, `complete`, and `cancel`;
- terminal state transitions use `complete` or `cancel`, preserving subtree and
  archival policy;
- all operations target one selected workspace;
- a failed operation rejects the entire batch.

Single-item work should use the ordinary verbs. A transaction exists for edits
that must succeed or fail together.
