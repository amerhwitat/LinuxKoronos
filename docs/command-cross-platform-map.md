# Cross-platform command reference: Linux, Windows and macOS

This curated command map connects Koronos command names with candidate Linux, Windows and macOS equivalents. It is a reference and resolver input, **not** a claim that the commands are installed or that their options/exit codes are identical.

## Important platform differences

- Linux and macOS share many POSIX command names, but macOS ships BSD-derived userland. GNU-only options (for example, some `sed`, `date`, `stat`, `grep`, and `find` flags) must not be assumed on macOS.
- Windows has both `cmd.exe` built-ins/utilities and PowerShell cmdlets. PowerShell aliases such as `ls`, `cat`, `curl`, and `wget` can shadow executables; use explicit executable names such as `curl.exe` where needed.
- Windows ACLs are not POSIX mode bits. `chmod`/`chown` mappings are approximate and must not be treated as safe automatic rewrites.
- Compiler, linker, debugger, binary format, and ABI differences matter: ELF, PE/COFF, and Mach-O are not interchangeable.

## Mapping data

The machine-readable map is `config/command-cross-platform-map.json`. It contains curated common command families, per-platform candidate names, descriptions, and an explicit `options_compatibility=not-assumed` policy.

## Resolver

Run:

```sh
python3 tools/command-map.py list
python3 tools/command-map.py resolve grep --platform windows
python3 tools/command-map.py resolve objdump --platform macos --json
```

The resolver only reports a candidate mapping. It does not execute it, install packages, translate flags, or claim provider availability. Execution must separately validate provider presence, version, license, ABI, and argument semantics, and must pass an argv vector without shell interpolation.

## Extending the map

For each imported catalogue entry, add a curated row only after checking the platform's official documentation or man page. Record upstream references and verified version ranges. Classify each row as exact, partial, unavailable, shell-builtin, or platform-specific. Do not turn broad catalogue entries, URLs, documentation pages, or ISA names into executable commands.
