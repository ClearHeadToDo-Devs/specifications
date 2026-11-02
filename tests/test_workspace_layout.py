"""Regression checks for the action lifecycle documented in the file layout."""
from pathlib import Path
import unittest


class WorkspaceLayoutTests(unittest.TestCase):
    def test_action_files_distinguish_archival_from_closure(self):
        workspace = (Path(__file__).resolve().parents[1] / "workspace.md").read_text()
        layout = workspace.split("All paths are relative to `charters/`:", 1)[1].split(
            "When a charter is archived", 1
        )[0]
        entries = dict(
            line.removeprefix("- ").split(" — ", 1)
            for line in layout.splitlines()
            if line.startswith("- ")
        )
        self.assertIn(
            "including closed lines",
            entries["`charters/<charter>.actions`"],
        )
        self.assertIn(
            "archived whole root trees",
            entries["`charters/<charter>.completed.actions`"],
        )
        self.assertIn(
            "not moved here merely by closing",
            entries["`charters/<charter>.completed.actions`"],
        )


if __name__ == "__main__":
    unittest.main()
