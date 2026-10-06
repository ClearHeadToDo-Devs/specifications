# ClearHead Ontology

**Current**: V5 (`5.0.0-draft`), on CCO v2.2 and IAO. Folded into the specification on 2026-10-04 from the former `ontology` repository, with its history (platform Decision 50).

What ClearHead's data means, stated in standard terms. V5 defines no terms of its own: objectives and plans are CCO, an action is IAO's action specification, and conditions, status, priority and records are CCO patterns. The application vocabulary ([`../ontology.md`](../ontology.md)) is what implementations publish; this directory is its meaning.

- **[domain.md](domain.md)**: the domain in plain words, its competency questions, and the standard term for each part.
- **[DECISIONS.md](DECISIONS.md)**: the choices behind it, with alternatives rejected.

## Layout

| Path | What |
| --- | --- |
| `clearhead.ttl` | The ontology header: imports, no terms. |
| `imports/` | CCO v2.2 and an IAO module, pinned by checksum. |
| `examples/` | Real plans written in the standard terms. |
| `queries/` | One `robot query` per competency question, with its expected answer in `expected/`. |
| `verify/` | Must-never-happen checks (every action belongs to a plan, every plan names an objective). |
| `mapping/` | One SPARQL CONSTRUCT per structure, from the application graph to these terms (Decision 50). |
| `unmapped.ttl` | Every application term the mapping does not read, and why. |

## Testing

Needs [ROBOT](https://robot.obolibrary.org) and Java. The specification stays inert data: the platform's `scripts/validate-pinned` runs this gate, and `scripts/check-graph-shapes.py` runs the mapping against the graph fixture.

```bash
make -C ontology test     # merge, reason with HermiT, verify, check the competency answers, lint
make -C ontology answers  # accept the current answers as expected, after reading the diff
make -C ontology imports  # re-fetch the pinned CCO and IAO; fails if the bytes changed
```

Each answer in `build/*.csv` must match `queries/expected/`, so a question that answers wrong or empty fails.

## License

MIT, as the whole specification: see [its license section](../README.md#license), which also credits the imports' own licenses.
