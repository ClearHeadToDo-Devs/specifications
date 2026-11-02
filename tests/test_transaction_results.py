"""Transaction receipt contract regressions (requires jsonschema).

Run: python -m unittest discover -s tests
"""
import json
from pathlib import Path
import unittest

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[1]
ID = "urn:uuid:019fdffc-b160-74f1-a8b3-a3a5694e794e"


class TransactionResults(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        schema = json.loads((ROOT / "schemas/transaction_result.schema.json").read_text())
        Draft202012Validator.check_schema(schema)
        cls.validator = Draft202012Validator(schema)

    def valid_outcome(self, kind, **fields):
        return self.validator.is_valid({
            "kind": "committed",
            "operations": [{"kind": kind, "id": ID, **fields}],
            "files": [],
        })

    def test_close_reports_open_descendant_ids_not_child_count(self):
        for kind in ("completed", "cancelled"):
            for ids in ([], [ID]):
                with self.subTest(kind=kind, ids=ids):
                    self.assertTrue(self.valid_outcome(kind, open_children=ids))
            for fields in ({}, {"children": 0}, {"open_children": [], "children": 0},
                           {"open_children": 0}, {"open_children": ["not-canonical"]}):
                with self.subTest(kind=kind, fields=fields):
                    self.assertFalse(self.valid_outcome(kind, **fields))

    def test_only_delete_has_children(self):
        self.assertTrue(self.valid_outcome("deleted", children=0))
        self.assertTrue(self.valid_outcome("deleted", children=3))
        self.assertFalse(self.valid_outcome("deleted"))
        self.assertFalse(self.valid_outcome("deleted", children=-1))
        self.assertFalse(self.valid_outcome("deleted", children=0, open_children=[]))
        for kind in ("reopened", "added", "updated"):
            with self.subTest(kind=kind):
                self.assertTrue(self.valid_outcome(kind))
                self.assertFalse(self.valid_outcome(kind, children=0))
                self.assertFalse(self.valid_outcome(kind, open_children=[]))

    def test_result_examples(self):
        for path in sorted((ROOT / "examples/transactions/result").glob("*.json")):
            with self.subTest(path=path.name):
                self.assertEqual(
                    self.validator.is_valid(json.loads(path.read_text())),
                    not path.name.startswith("invalid_"),
                )


if __name__ == "__main__":
    unittest.main()
