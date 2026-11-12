import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "command-map.py"
DATA = ROOT / "config" / "command-cross-platform-map.json"

class CommandMapTests(unittest.TestCase):
    def test_schema_and_unique_commands(self):
        data = json.loads(DATA.read_text(encoding="utf-8"))
        self.assertEqual(data["schema"], "koronos-command-cross-platform-map/v1")
        names = [r["command"].casefold() for r in data["commands"]]
        self.assertEqual(len(names), len(set(names)))
        for row in data["commands"]:
            for platform in ("linux", "windows", "macos"):
                self.assertTrue(row[platform]["name"])

    def test_windows_grep_candidate(self):
        result = subprocess.run([sys.executable, str(SCRIPT), "resolve", "grep",
                                 "--platform", "windows", "--json"],
                                text=True, capture_output=True, check=True)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["candidate"], "Select-String")
        self.assertEqual(payload["execution"], "not-performed")

    def test_unknown_command_is_not_guessed(self):
        result = subprocess.run([sys.executable, str(SCRIPT), "resolve",
                                 "not-a-real-command", "--platform", "linux"],
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 1)

if __name__ == "__main__":
    unittest.main()
