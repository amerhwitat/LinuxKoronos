# Full command catalogue coverage

The generated `config/full-command-catalogue-coverage.json` now inventories every row in the current ChimeraIIOS command list:

- Source: `ChimeraIIOS/system/commands/chimera-command-list.json`
- Source schema: `3.0`
- Catalogue rows: **1,281 across 8 categories**
- Unique curated cross-platform names: **64**
- Rows with a curated candidate mapping: **139**
- Rows still unmapped and needing source research: **1,142**

| Category | Rows |
|---|---:|
| Linux Bash | 301 |
| macOS core | 117 |
| Windows CMD | 161 |
| PowerShell | 142 |
| VBScript | 86 |
| SQL Server | 73 |
| Native Chimera | 90 |
| Compatibility commands | 311 |
| **Total** | **1,281** |

The inventory builder supports both the newer `platforms.{category}.commands` schema and the current top-level category-array schema. The older referenced `ss64-command-catalog.json` and `online-command-catalog.json` files in the current ChimeraIIOS main branch are empty, so they are not treated as the source of truth.

## ISA and native-command status are separate

The separate ChimeraIIOS `system/commands/command-isa-coverage.json` reports:

- **853 unique command names**
- **104 ISA architecture rows**
- **154 instruction forms**
- **15 native source commands** in the current multicall implementation

The LinuxKoronos ISA cross-platform matrix further records 19 architectures with an LLVM backend, 23 QEMU guest targets, and 81 architecture rows without a QEMU target. Those are toolchain/emulator references, not proof of a complete OS port, native binary, assembler/disassembler, or runtime.

## Mapping and execution policy

A mapped row is only a candidate name equivalent. Option semantics, version availability, privilege requirements, output format, and side effects are not assumed compatible. Every inventory row remains `not-built-or-runtime-verified` until an actual provider binary is built or verified and its supported operands/options are tested.

The generated file deliberately leaves unknown entries as `unmapped-needs-research`; it does not invent equivalents or mark catalogue presence as implementation.

## Reproduce the inventory

```sh
python3 tools/build-catalogue-coverage.py \
  path/to/chimera-command-list.json \
  config/command-cross-platform-map.json \
  config/full-command-catalogue-coverage.json
```

## Completion workflow

1. Classify each row as executable command, shell builtin, language/API, standard/specification, compatibility alias, or documentation.
2. Research Linux, Windows (CMD and PowerShell separately), and macOS/BSD equivalents from authoritative upstream documentation.
3. Record exact command identity, provider, upstream URL, supported versions, operands/options, and semantic differences.
4. Build only open-source providers with verified provenance and licenses.
5. Add per-platform tests for supported options and negative/unsupported cases.
6. Mark an entry complete only after provider build and runtime tests pass.

The unresolved rows remain visible by design. Do not fill them with guessed same-name aliases or downloaded proprietary operating-system binaries.
