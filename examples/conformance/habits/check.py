"""Draft executable specification checks; see README.md for the command."""
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from uuid import UUID, uuid5
from zoneinfo import ZoneInfo
import json

from jsonschema import Draft7Validator
from pyshacl import validate
from rdflib import Graph, Literal, Namespace
from rdflib.namespace import RDF, XSD

ROOT = Path(__file__).resolve().parents[3]
APP = Namespace("https://clearhead.dev/vocab/app/v1#")
OBO = Namespace("http://purl.obolibrary.org/obo/")
CCO = Namespace("https://www.commoncoreontologies.org/")
HABIT = UUID("01951111-cfa6-718d-b303-d7107f4005b4")

for path in (ROOT / "schemas").glob("*.json"):
    Draft7Validator.check_schema(json.loads(path.read_text()))

schema = json.loads((ROOT / "schemas/actions.schema.json").read_text())
Draft7Validator(schema).validate({"actions": [{"state": "not_started", "name": "Review", "recurrenceRule": "FREQ=DAILY", "scheduledDateTime": "2026-10-26"}]})
sidecar = json.loads((ROOT / "schemas/charter_metadata.schema.json").read_text())
Draft7Validator(sidecar).validate({"actions": {"8e337bcd-ad84-5158-baec-ac9b81c5ab0f": {"occurrence": {"habit_id": str(HABIT), "occurrence_key": "D:2026-10-26", "plan_title": "Review"}}}, "habits": {str(HABIT): {"frame": "DATE", "exdate": ["EXDATE;VALUE=DATE:20261027"]}}})

shapes = Graph().parse(ROOT / "schemas/app.shapes.ttl")
graph = Graph().parse(Path(__file__).with_name("app.ttl"))
assert validate(graph, shacl_graph=shapes, advanced=True)[0]
# Missing rule, invalid Habit state, and old datetime slot type must all fail.
for predicate, value in [(APP.rule, None), (APP.state, APP.Blocked)]:
    bad = deepcopy(graph)
    habit = next(bad.subjects(RDF.type, APP.Habit))
    bad.remove((habit, predicate, None))
    if value is not None:
        bad.add((habit, predicate, value))
    assert not validate(bad, shacl_graph=shapes, advanced=True)[0]
bad = deepcopy(graph)
occurrence = next(bad.subjects(APP.occurrenceOf, None))
bad.set((occurrence, APP.slot, Literal("2026-10-26T00:00:00Z", datatype=XSD.dateTime)))
assert not validate(bad, shacl_graph=shapes, advanced=True)[0]

mapped = Graph()
for path in sorted((ROOT / "ontology/mapping").glob("*.rq")):
    mapped += graph.query(path.read_text()).graph
habit = next(graph.subjects(RDF.type, APP.Habit))
occurrence = next(graph.subjects(APP.occurrenceOf, habit))
assert (habit, RDF.type, OBO.IAO_0000007) in mapped
assert (habit, OBO.BFO_0000178, occurrence) in mapped
assert list(mapped.triples((None, CCO.ont00001765, Literal("FREQ=DAILY"))))
assert uuid5(HABIT, "occurrence/D:2026-10-26") == UUID(str(occurrence).removeprefix("urn:uuid:"))

# Canonical keys do not depend on the viewer zone. Test actual series-zone
# fold/gap resolution, rather than interpreting wall times in the viewer zone.
for viewer in ["UTC", "America/Los_Angeles", "Asia/Tokyo"]:
    for local, expected in [
        ("2026-10-26T09:00:00", "U:2026-10-26T16:00:00Z"),
        ("2026-11-01T01:30:00", "U:2026-11-01T08:30:00Z"),
        ("2026-03-08T02:30:00", "U:2026-03-08T10:30:00Z"),
    ]:
        slot = datetime.fromisoformat(local).replace(tzinfo=ZoneInfo("America/Los_Angeles"), fold=0)
        key = "U:" + slot.astimezone(ZoneInfo(viewer)).astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
        assert key == expected
step = UUID("01951111-cfa6-718d-b303-d7107f4005b6")
root = uuid5(HABIT, "occurrence/D:2026-10-26")
assert uuid5(root, "step/" + str(step)) != root
print("Habit draft: JSON schemas, SHACL positive/negative, CCO mapping, native identity and cross-zone DST vectors pass")
