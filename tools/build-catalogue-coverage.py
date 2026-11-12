#!/usr/bin/env python3
"""Build a lossless, auditable coverage index from the Chimera command catalogue.

This tool inventories every source entry. It does not pretend that an unmapped
entry is executable or that a same-name command has compatible semantics.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

ENTRY_CLASSES = {
    "linux_posix_shells": "shell-command-or-reference",
    "linux_bash": "bash-command-or-reference",
    "gnu_linux": "gnu-linux-command-or-reference",
    "posix": "posix-standard-or-utility",
    "macos": "macos-command-or-reference",
    "windows_cmd": "windows-cmd-command-or-reference",
    "powershell": "powershell-command-or-reference",
    "windows": "windows-command-or-reference",
    "freebsd_unix": "freebsd-unix-reference",
    "vbscript": "vbscript-language-api",
    "sql_server": "sql-server-language-api",
    "access": "microsoft-access-language-api",
    "tools": "tool-or-general-reference",
}

def load(path: Path):
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)

def build(catalog: dict, curated: dict) -> dict:
    if "platforms" not in catalog or not isinstance(catalog["platforms"], dict):
        raise ValueError("catalogue has no platforms object")
    if curated.get("schema") != "koronos-command-cross-platform-map/v1":
        raise ValueError("unsupported curated map schema")
    by_name = {row["command"].casefold(): row for row in curated["commands"]}
    entries = []
    category_counts = {}
    for category, group in catalog["platforms"].items():
        commands = group.get("commands", [])
        category_counts[category] = len(commands)
        for index, item in enumerate(commands, 1):
            name = str(item.get("name", ""))
            mapping = by_name.get(name.casefold())
            entries.append({
                "id": f"{category}:{index}",
                "name": name,
                "source_category": category,
                "entry_class": ENTRY_CLASSES.get(category, "unclassified"),
                "source_url": item.get("source"),
                "source_kind": item.get("source_kind"),
                "catalogue_provider_status": item.get("provider_status", "not-specified"),
                "cross_platform_mapping_status": "curated-candidate" if mapping else "unmapped-needs-research",
                "equivalents": ({p: mapping[p] for p in ("linux", "windows", "macos")} if mapping else None),
                "options_compatibility": mapping.get("options_compatibility", "not-assessed") if mapping else "not-assessed",
                "execution_status": "not-built-or-runtime-verified",
            })
    mapped = sum(e["cross_platform_mapping_status"] == "curated-candidate" for e in entries)
    return {
        "schema": "koronos-full-command-catalogue-coverage/v1",
        "source_schema": catalog.get("schema_version"),
        "source_generated_at_utc": catalog.get("generated_at_utc"),
        "policy": "Inventory is exhaustive for the supplied source file. Candidate mappings do not assert option/semantic compatibility or binary availability.",
        "totals": {
            "entries": len(entries),
            "categories": len(category_counts),
            "category_counts": category_counts,
            "mapped_catalogue_rows": mapped,
            "unmapped_catalogue_rows": len(entries) - mapped,
            "unique_curated_command_names": len(by_name),
        },
        "entries": entries,
    }

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("catalogue", type=Path)
    parser.add_argument("curated_map", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    result = build(load(args.catalogue), load(args.curated_map))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(result["totals"], indent=2, sort_keys=True))

if __name__ == "__main__":
    main()
