#!/usr/bin/env python3
"""Read-only cross-platform command name resolver for LinuxKoronos."""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "config" / "command-cross-platform-map.json"

def load():
    with DATA.open(encoding="utf-8") as stream:
        obj = json.load(stream)
    if obj.get("schema") != "koronos-command-cross-platform-map/v1":
        raise ValueError("unsupported command map schema")
    return obj

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    sub.add_parser("list", help="list curated command identifiers")
    resolve = sub.add_parser("resolve", help="show candidate platform command")
    resolve.add_argument("command")
    resolve.add_argument("--platform", required=True, choices=("linux", "windows", "macos"))
    resolve.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    try:
        data = load()
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"command-map: {exc}", file=sys.stderr)
        return 2
    if args.action == "list":
        for row in data["commands"]:
            print(row["command"])
        return 0
    row = next((r for r in data["commands"] if r["command"].casefold() == args.command.casefold()), None)
    if row is None:
        print(f"command-map: no curated mapping for {args.command}", file=sys.stderr)
        return 1
    result = {"command": row["command"], "platform": args.platform,
              "candidate": row[args.platform]["name"],
              "provider": row[args.platform]["provider"],
              "description": row["description"],
              "options_compatibility": row["options_compatibility"],
              "execution": "not-performed"}
    if args.json:
        print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    else:
        print(f'{result["command"]} -> {result["candidate"]} [{args.platform}]')
        print(f'options: {result["options_compatibility"]}; execution: not-performed')
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
