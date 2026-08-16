# Data Workflows: Select From the Graph, Act Atomically

ClearHead's read and write paths are deliberately separate tools that compose
through the shell. You **select** work with a query and **act** on it with a
transaction. Neither side knows about the other; they meet only at a canonical
identity (`urn:uuid:…`) and a pair of JSON schemas.

- Read: `clearhead query …` (a projection of the [graphd](../ontology.md) graph).
- Write: `clearhead transact` (an ordered, atomic batch of action operations).
- Contract: [`transaction_request`](../schemas/transaction_request.schema.json)
  and [`transaction_result`](../schemas/transaction_result.schema.json).

## The loop

```sh
# Complete every unscheduled action the graph surfaces, in one atomic batch.
clearhead query index unscheduled --format ids \
  | jq -Rn '{operations: [inputs | {op: "complete-action", target: .}]}' \
  | clearhead transact
```

The query's `--format ids` projection emits one canonical `urn:uuid:` per line;
`transact` accepts exactly that string as an operation `target`. The two sides
were built to the same schema and are pinned together by a cross-binary test, so
the id spelling cannot silently drift.

### For a human

Run the query alone first to see what you'd touch; add `--dry-run` to the
transaction to preview without writing:

```sh
clearhead query index agenda            # look
clearhead transact request.json --dry-run   # rehearse — kind: "dry-run", writes nothing
clearhead transact request.json              # commit — kind: "committed"
```

### For an agent

Everything is data. `transact` always emits a schema-valid `transaction_result`
on stdout — `committed`, `dry-run`, or `rejected` with the 0-based index of the
failed operation — and exits non-zero on rejection, so a loop can branch on the
`kind` field without parsing prose. Because the batch is all-or-nothing, a
rejected operation leaves the workspace exactly as it was.

## The facade

`clearhead query` forwards `raw`, `named`, `index`, `tree`, `graph`, `chain`,
`show`, and `list` straight to `clearhead-graphd query …` with inherited stdio —
a **pure projection**: graphd renders, the CLI adds nothing, and stdout and exit
status match invoking graphd directly. (This forwarding shim was retired when
graphd was decoupled into a standalone peer, then narrowly restored so the "one
tool" ergonomics return without re-coupling the crates.) Its sole bit of
cleverness is `chain`, which resolves a fuzzy action name to a canonical IRI in
the CLI before forwarding — because name resolution is an actions-domain concern,
not a graph one.

## Intentionally deferred

The first transaction surface is small on purpose:

- **Operations are `update` / `complete` / `cancel` only.** No `add`, `delete`,
  `move`, generic JSON Patch, or desired-state snapshots. Each operation names an
  intent whose side effects core owns (a field edit vs. cascade-close + date
  stamp + file move), not a diff to reconcile.
- **A terminal `update.state` is rejected** before the lock, not applied — use
  `complete` / `cancel`, which cascade and archive. A field edit must never strand
  a "completed" action with open children.
- **No compare-and-swap / conflict detection.** One workspace lock serializes all
  writers; no lost-update race is observable, so none is modeled.
- **Single-workspace.** Targets resolve within the primary workspace.

Single-item work should use the ordinary verbs; a transaction exists only for
edits that must be atomic *together*.
