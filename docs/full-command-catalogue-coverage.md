# Full command catalogue coverage

The generated `config/full-command-catalogue-coverage.json` inventories every row
in ChimeraIIOS `system/commands/ss64-command-catalog.json` (schema 4.5,
generated 2026-10-17): **5,296 entries in 13 categories**.

This is an inventory and triage index, not a claim that every row is an
executable command. The source includes shell utilities, PowerShell and CMD
references, POSIX standards material, SQL Server statements, VBScript methods,
Access APIs, FreeBSD references, and general tools/documentation.

## Current mapping coverage

- The existing reviewed cross-platform map contains 64 unique command names.
- Those names match 207 catalogue rows (because source names repeat across
  categories).
- 5,089 catalogue rows remain unmapped and need source-by-source research.
- A mapped row is only a candidate name equivalent. Option semantics,
  version availability, privilege requirements, and side effects are not
  assumed compatible.
- No binary is considered built or runtime-verified by this inventory.

## Reproduce the inventory

```sh
python3 tools/build-catalogue-coverage.py \
  path/to/ss64-command-catalog.json \
  config/command-cross-platform-map.json \
  config/full-command-catalogue-coverage.json
```

## Completion workflow

1. Classify each row as executable command, shell builtin, language/API,
   standard/specification, or documentation.
2. Research Linux, Windows (CMD and PowerShell separately), and macOS/BSD
   equivalents from authoritative upstream documentation.
3. Record exact command identity, provider, upstream URL, supported versions,
   operands/options, and semantic differences.
4. Build only open-source providers with verified provenance and licenses.
5. Add per-platform tests for supported options and negative/unsupported cases.
6. Mark an entry complete only after provider build and runtime tests pass.

The unresolved rows are intentionally visible. Do not fill them with guessed
same-name aliases or downloaded proprietary operating-system binaries.
