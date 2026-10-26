# Habit draft conformance

This supplements the already approved `examples/actions/habits/` and formatting pairs; those source oracles are unchanged.

Run from the specification root in a Python environment with `rdflib==7.2.1`, `pyshacl==0.30.1`, `jsonschema==4.25.1`:

```sh
python examples/conformance/habits/check.py
```

The check validates all JSON schemas, accepts a Habit serialization and durable sidecar, validates a native application graph, rejects missing rules/unsupported state/old datetime slot typing, executes the CCO mapping, checks one occurrence UUID oracle and resolves series-zone fold/gap examples in three viewer zones. It is specification-artifact validation, **not proof that Core conforms**. Core adoption must execute the same vectors against its real canonicalizer, stamping and graph projection, including DATE/floating slots, template-step rename/reorder, interrupted catch-up, archives and edited rules.

Release gate: integrate this suite with the implementation conformance tests and the existing graph suite; review the complete mapping under the ontology reasoner. This standalone draft check does not replace that gate.
