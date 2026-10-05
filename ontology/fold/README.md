# ClearHead Ontology

**Current**: V5 (`5.0.0-draft`), on CCO v2.2 and IAO. v4 was retired on 2026-10-04 (platform `retire-v4`); git history keeps it.

What ClearHead's data means, stated in standard terms. V5 defines no terms of its own: objectives and plans are CCO, an action is IAO's action specification, and conditions, status, priority and records are CCO patterns. This repository holds the alignment, examples that use it, and checks that prove it answers the questions it must.

- **[docs/domain.md](docs/domain.md)**: the domain in plain words, its competency questions, and the standard term for each part.
- **[docs/DECISIONS.md](docs/DECISIONS.md)**: the choices behind it, with alternatives rejected.

How the data is shaped (JSON schemas, SHACL shapes, the JSON-LD context) belongs to the [specifications](https://github.com/ClearHeadToDo-Devs/specifications), not here (platform Decision 42).

## Layout

| Path | What |
| --- | --- |
| `v5/clearhead.ttl` | The ontology header: imports, no terms. |
| `v5/imports/` | CCO v2.2 and an IAO module, pinned by checksum. |
| `v5/examples/` | Real plans written in the standard terms. |
| `v5/queries/` | One `robot query` per competency question, with its expected answer in `expected/`. |
| `v5/verify/` | Must-never-happen checks (every action belongs to a plan, every plan names an objective). |

## Testing

Needs [ROBOT](https://robot.obolibrary.org) and Java.

```bash
make -C v5 test     # merge, reason with HermiT, verify, check the competency answers, lint
make -C v5 answers  # accept the current answers as expected, after reading the diff
make -C v5 imports  # re-fetch the pinned CCO and IAO; fails if the bytes changed
```

Each answer in `v5/build/*.csv` must match `v5/queries/expected/`, so a question that answers wrong or empty fails. CI runs the same gate with ROBOT pinned by checksum.

## License

See [LICENSE](./LICENSE).
