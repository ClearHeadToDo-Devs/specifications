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

- operations are `update-action`, `complete-action`, `cancel-action`, and
  `reopen-action`;
- `complete-action` and `cancel-action` set only the named action's state to
  `completed` or `cancelled` and stamp `completed_at` in place. They do not
  cascade, detach parent links, or move lines to another file;
- `reopen-action` sets only the named closed action to `not_started` and clears
  `completed_at` in place. It is allowed only in the active file and is refused
  for an archived action; unarchive its root tree first;
- all operations target one selected workspace;
- a failed operation rejects the entire batch.

Closed lines in the active file are ordinary records. Closing a parent does not
close its children; W002 (closed parent with an open child) and W003 (open parent
with all children closed) remain warnings, not mutation guards.

Only archive and unarchive transfer action lines between the active and completed
files, always as a whole root tree (a root and everything below it). Archive
requires a closed root whose entire tree is closed. Unarchive takes a root in
the completed file and returns its whole tree without changing states. Either
operation refuses a child target and names its root. Parent links inside an
archived tree are retained; closing does not detach them.

For example, [`valid_reopen.json`](../examples/transactions/request/valid_reopen.json)
reopens one closed action in the active file. Its descendants are unchanged, its
completion date is cleared, and only the active file is written. The
[committed receipt](../examples/transactions/result/committed.json) and
[dry-run preview](../examples/transactions/result/dry_run.json) likewise show
single-action closes: `children` is `0`, and no completed file is written.

Single-item work should use the ordinary verbs. A transaction exists for edits
that must succeed or fail together.
