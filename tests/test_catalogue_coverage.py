import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "coverage_builder", ROOT / "tools" / "build-catalogue-coverage.py"
)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

class CatalogueCoverageTests(unittest.TestCase):
    def test_every_source_row_is_retained_and_unknown_is_not_guessed(self):
        catalogue = {
            "schema_version": "test",
            "generated_at_utc": "2026-01-01T00:00:00Z",
            "platforms": {
                "linux_posix_shells": {"commands": [
                    {"name": "ls", "source": "https://example.invalid/ls"},
                    {"name": "unknown-command", "source": "https://example.invalid/unknown"},
                ]},
                "sql_server": {"commands": [
                    {"name": "SELECT", "source": "https://example.invalid/select"}
                ]},
            },
        }
        curated = {
            "schema": "koronos-command-cross-platform-map/v1",
            "commands": [{
                "command": "ls",
                "linux": {"name": "ls", "provider": "host-detect"},
                "windows": {"name": "Get-ChildItem", "provider": "host-detect"},
                "macos": {"name": "ls", "provider": "host-detect"},
                "options_compatibility": "not-assumed",
            }],
        }
        result = MODULE.build(catalogue, curated)
        self.assertEqual(result["totals"]["entries"], 3)
        self.assertEqual(result["entries"][0]["cross_platform_mapping_status"], "curated-candidate")
        self.assertEqual(result["entries"][1]["cross_platform_mapping_status"], "unmapped-needs-research")
        self.assertIsNone(result["entries"][1]["equivalents"])
        self.assertEqual(result["entries"][2]["entry_class"], "sql-server-language-api")
        self.assertEqual(result["entries"][2]["execution_status"], "not-built-or-runtime-verified")

    def test_duplicate_source_names_keep_stable_distinct_ids(self):
        catalogue = {"platforms": {"macos": {"commands": [
            {"name": "open"}, {"name": "open"}
        ]}}}
        curated = {"schema": "koronos-command-cross-platform-map/v1", "commands": []}
        result = MODULE.build(catalogue, curated)
        self.assertEqual([x["id"] for x in result["entries"]], ["macos:1", "macos:2"])

if __name__ == "__main__":
    unittest.main()
