import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class IsaMatrixTests(unittest.TestCase):
    def test_all_catalogue_architectures_and_instruction_forms_are_mapped(self):
        matrix = json.loads((ROOT / "config/isa-cross-platform-matrix.json").read_text())
        self.assertEqual(matrix["counts"]["architectures"], 104)
        self.assertEqual(matrix["counts"]["instruction_forms"], 154)
        self.assertEqual(len(matrix["architectures"]), 104)
        self.assertEqual(len(matrix["instructions"]), 154)
        for row in matrix["architectures"]:
            for host in ("linux", "windows", "macos"):
                self.assertIn(host, row["host_build_os"])
            self.assertIn("binary_build_status", row)
        self.assertTrue(all(row["verification_status"] == "catalogued-form-not-conformance-tested" for row in matrix["instructions"]))

class DatabaseMatrixTests(unittest.TestCase):
    def test_open_source_database_profiles_are_consistent(self):
        matrix = json.loads((ROOT / "config/database-backend-matrix.json").read_text())
        ids = {row["id"] for row in matrix["backends"]}
        self.assertEqual(len(ids), 10)
        for profile in matrix["profiles"].values():
            self.assertTrue(set(profile).issubset(ids))
        self.assertEqual(matrix["profiles"]["core_embedded"], ["sqlite"])
        self.assertTrue(all(row.get("source_url") and row.get("license") for row in matrix["backends"]))
        excluded = {row["name"] for row in matrix["excluded_source_available"]}
        self.assertIn("MongoDB Community Server", excluded)

if __name__ == "__main__":
    unittest.main()
