# Cross-platform command and Linux-userspace mapping for Koronos

**Status:** reference contract and implementation roadmap. This document does not claim that every mapped command, option, Linux service, or foreign executable is implemented by Koronos.

## 1. Command-resolution contract

Resolve each command in this order:

1. Koronos-native implementation with a passing native conformance test.
2. A licensed, source-built provider packaged for the current target and architecture.
3. An explicitly installed compatibility runtime, selected only when its ABI and executable format match.
4. A documented platform adapter that translates the command's arguments and reports unsupported options.
5. A clear `command not found` / `unsupported option` error.

Never silently reinterpret an option when the source and target semantics differ. Preserve exit status, stdout, stderr, signals, quoting, environment, working directory, file descriptors, and path semantics. Privileged commands must pass the Koronos capability/security policy; command-name equivalence never grants privilege.

## 2. Common command-name reference

The table maps familiar command names, not every option or behavior. PowerShell cmdlets are the preferred native PowerShell equivalents; CMD names are shown separately where useful.

| Purpose | POSIX / Linux / BSD / macOS | Windows CMD | PowerShell | Koronos canonical family |
|---|---|---|---|---|
| List directory | `ls` | `dir` | `Get-ChildItem` (`gci`, `ls`) | filesystem.list |
| Change directory | `cd` | `cd`, `chdir` | `Set-Location` (`cd`) | filesystem.chdir |
| Current directory | `pwd` | `cd` | `Get-Location` (`pwd`) | filesystem.getcwd |
| Copy | `cp` | `copy`, `xcopy` | `Copy-Item` | filesystem.copy |
| Move / rename | `mv` | `move`, `ren` | `Move-Item`, `Rename-Item` | filesystem.move |
| Remove | `rm` | `del`, `erase`, `rmdir` | `Remove-Item` | filesystem.remove |
| Read file | `cat` | `type` | `Get-Content` | text.read |
| Search text | `grep` | `findstr` | `Select-String` | text.search |
| Search paths | `find` | `where` (PATH lookup) | `Get-ChildItem -Recurse` | filesystem.find |
| Create directory | `mkdir` | `mkdir`, `md` | `New-Item -ItemType Directory` | filesystem.mkdir |
| File metadata | `stat`, `file` | `dir`, `fsutil` (different scope) | `Get-Item`, `Get-Acl` | filesystem.metadata |
| Environment | `env`, `printenv` | `set` | `Get-ChildItem Env:` | process.environment |
| Process list | `ps`, `top` | `tasklist` | `Get-Process` | process.list |
| Stop process | `kill`, `pkill` | `taskkill` | `Stop-Process` | process.signal |
| Network config | `ip`, `ifconfig` | `ipconfig` | `Get-NetIPConfiguration` | network.configure |
| Listening sockets | `ss`, `netstat` | `netstat` | `Get-NetTCPConnection` | network.sockets |
| HTTP transfer | `curl`, `wget` | `curl`, `bitsadmin` (not equivalent) | `Invoke-WebRequest`, `Invoke-RestMethod` | network.http |
| Archive | `tar`, `gzip`, `xz`, `zip` | `tar` (supported Windows versions), archive tools | `Compress-Archive`, `Expand-Archive` | archive |
| Permissions | `chmod`, `chown`, `chgrp` | `icacls` | `Get-Acl`, `Set-Acl` | security.permissions |
| Disk space | `df`, `du` | `fsutil`, volume tools | `Get-Volume`, filesystem cmdlets | storage.usage |
| Mounts | `mount`, `umount` | `mountvol`, `diskpart` | `Get-Volume`, `Mount-DiskImage` | storage.mount |
| Services | `systemctl`, `service` (Linux-specific) | `sc.exe`, `net` | `Get-Service`, `Start-Service`, `Stop-Service` | service.manager |
| Manuals/help | `man`, `info` | `help`, `/?` | `Get-Help` | help |

### Portability rules

- POSIX specifies a portable baseline; GNU, BSD, Darwin, Solaris/illumos, and BusyBox implementations add different options and extensions.
- macOS userland is Darwin/BSD-derived; do not assume GNU-specific flags such as GNU `sed -i` or `date -d` are available.
- Windows CMD, PowerShell, and WSL are distinct execution environments. A command name shared by them does not imply identical quoting, wildcard expansion, streams, path handling, or exit codes.
- PowerShell aliases are session conveniences, not a POSIX ABI. A Koronos shell should resolve aliases to canonical operations and retain the source shell's semantics only when that shell mode is explicitly selected.
- For every imported command, record source project, version, license, target architecture, build recipe, option coverage, tests, and provenance. Do not download proprietary Windows/macOS executables for redistribution.

## 3. Linux userspace mapped to Koronos

A Linux distribution userspace is a stack, not a directory of command binaries. Koronos needs explicit ABI contracts and runtime services for each layer.

| Linux userspace layer | Linux reference | Koronos destination | Minimum acceptance evidence |
|---|---|---|---|
| Boot and PID 1 | initramfs `/init`, systemd or another init | target-specific `/sbin/init-live`, `init-installer`, `init-recovery`; Kore supervisor | Correct target manifest, ELF admission, real user-mode entry, dependency start, health/readiness trace |
| Executable ABI | ELF, syscalls, auxv, dynamic linker | Koronos ELF loader, process model, syscall ABI and runtime linker | Map PT_LOAD, zero BSS, enforce page permissions, valid stack/auxv, syscall and exit tests |
| C runtime | glibc, musl, uClibc | Koronos libc/sysroot and ABI adapters | Compile and run representative dynamically and statically linked programs; errno/thread/signal tests |
| Shell | sh, Bash, dash, zsh | Koronos shell providers | Parsing, expansion, redirection, pipelines, job control, signals and script conformance |
| Base utilities | GNU coreutils, BusyBox, Toybox | Native Koronos utilities plus licensed providers | Per-command/per-option manifest and tests; no catalogue-only success |
| Service management | systemd, OpenRC, runit | Kore | Start/stop/restart, ordering, failure propagation, supervision and logs |
| Device discovery | udev, devtmpfs, sysfs | Koronos device manager and HAL | Enumerated device nodes, permissions, hotplug and driver-backed I/O |
| Virtual filesystems | procfs, sysfs, devtmpfs, tmpfs | Koronos VFS pseudo-filesystem providers | Mount, lookup, permissions, read/write, lifecycle and unmount tests |
| Persistent storage | Linux block layer and filesystem drivers | Koronos block layer + VFS + QFS and qualified filesystem drivers | Real block-device I/O, flush/barrier, mount/read/write/sync/unmount and fault tests |
| Networking | Linux net stack, iproute2, resolver, DHCP | Spotnik and network services | Interface lifecycle, sockets, DNS, routing, packet I/O and network conformance |
| Logging and observability | journald/syslog, proc metrics, tracing | Koronos logging and telemetry | Persistent/volatile logs, process metrics, crash records and bounded tracing |
| Graphics | DRM/KMS, Mesa, Wayland/Xorg | Koronos display driver, compositor and protocol server | Hardware/virtual display initialization, input, buffers, modesetting and session lifecycle |
| Desktop session | GNOME/KDE/Xfce or other session | Aurora Glass and Marine Blue | Launch from display server; file manager, launcher, settings, session services and clean logout |
| Package management | dpkg/apt, rpm/dnf, apk | Koronos package manager and signed repository metadata | Dependency solver, signature/hash verification, transactional install/rollback and uninstall |
| Compatibility | Wine, Box64, QEMU-user, containers | Explicit CEF/foreign ABI providers | Format/architecture detection, syscall/API coverage, sandboxing and per-application tests |

## 4. LinuxKoronos hosted runtime boundary

The currently implemented LinuxKoronos 0.1.0 edition is a Linux-hosted Koronos process runtime:

- It uses Linux for scheduling, virtual memory, filesystems, networking, and hardware drivers.
- It discovers host kernel/architecture, reports a host profile, and starts an explicitly named process through `fork(2)` / `execvp(3)`.
- It propagates child exit status and is unprivileged by default.
- It is not a freestanding Koronos kernel, Linux distribution userspace replacement, init system, or bare-metal boot image.

The next compatible extension is a versioned host-service ABI: process, filesystem, device, network, logging, service-supervision and graphics providers. Each provider must declare whether it is host-backed, Koronos-native, or a foreign compatibility runtime. This avoids presenting Linux host services as native Koronos kernel implementations.

## 5. Build and verification workflow

For each command/provider or userspace component:

1. Inventory the canonical command/API and source-family variants.
2. Select a maintained open-source implementation with a compatible license.
3. Pin source revision and checksums; preserve license and notices.
4. Build separately for each supported host/target architecture.
5. Record build provenance, binary format, ABI, dynamic dependencies and supported options.
6. Run unit, integration, negative, permission, signal and exit-status tests.
7. Run target runtime tests under QEMU or real hardware where required.
8. Promote the capability only after the evidence record passes; otherwise leave it unavailable or compatibility-only.

Suggested evidence states: `catalogued`, `source-reviewed`, `build-passing`, `host-tested`, `target-runtime-tested`, `production-qualified`. A state must never be inferred from a command's presence in a CSV/JSON catalogue.

## 6. Safety and licensing

Do not copy proprietary Windows or macOS operating-system binaries, frameworks, or SDK components into either OS repository without redistribution rights. Prefer clean-room behavioral compatibility, open-source providers, and documented external dependencies. Device flashing, disk formatting, bootloader changes, and service administration require explicit capability checks, device identity validation, signed manifests, and read-back verification.


## 6. Generated Chimera command and ISA crosswalk

The current Chimera II OS catalogue snapshot is reconciled into a machine-readable crosswalk:

- [Generated command and ISA crosswalk](https://github.com/amerhwitat/ChimeraIIOS/blob/main/system/commands/generated-cross-platform-crosswalk.json)
- [Generator](https://github.com/amerhwitat/ChimeraIIOS/blob/main/tools/commands/generate_cross_platform_crosswalk.py)
- [Canonical command catalogue](https://github.com/amerhwitat/ChimeraIIOS/blob/main/system/commands/chimera-command-list.json)
- [Canonical ISA database](https://github.com/amerhwitat/ChimeraIIOS/blob/main/isa/isa_database.json)
- [Architecture backend registry](https://github.com/amerhwitat/ChimeraIIOS/blob/main/tools/isa/architecture-backends.json)

The generated snapshot reconciles 892 unique command names across the seven catalogue namespaces, 104 architecture records, and 154 instruction-form records. Exact command-name matches are distinguished from curated semantic equivalents. The source command catalogue does not carry complete per-command option grammars, so option coverage is explicitly marked as absent rather than guessed. ISA backend matching records compiler targets, QEMU user-mode providers and binary-format metadata where declared; it does not promote a compile target or emulator to native conformance.

A CI workflow regenerates the artifact and checks deterministic output and record counts. The command provider ledger, per-option conformance suite, per-ISA semantic vectors and actual target execution remain separate release gates.

## 7. Database provider mapping

The Chimera builder now includes distribution packages and development interfaces for MariaDB, PostgreSQL, SQLite and Redis, with a verification script that checks the client/server executables and installed package records. This is a builder-image provider set; it does not imply that database daemons are started in the ISO, that Kore manages them, or that they are Koronos-native.

Additional open-source engines tracked for source/pinned-package integration are DuckDB (MIT), Firebird (IPL/IDPL), ClickHouse (Apache-2.0), Apache CouchDB (Apache-2.0) and Valkey (BSD-3-Clause). See the [database provider catalog](https://github.com/amerhwitat/ChimeraIIOS/blob/main/databases/database-provider-catalog.json). Any binary redistribution must preserve exact upstream versions, checksums, licenses and notices.

## 8. Linux kernel-to-userspace handoff reference for Koronos

Use Linux as a behavioral and engineering reference, not as a claim that the Linux kernel ABI is already implemented by Koronos. The reference boot path is:

1. Firmware transfers control to the bootloader; the bootloader loads the kernel and initramfs and supplies the machine/boot parameters.
2. The kernel initializes memory management, interrupt handling, scheduler, device discovery, VFS and the root-device path.
3. The kernel unpacks the initramfs and executes its first userspace process (/init, PID 1). If no initramfs init is supplied, Linux searches its configured init candidates on the mounted root filesystem.
4. The initramfs init mounts or prepares required pseudo-filesystems and devices, discovers the real root, validates it, and performs the root transition (commonly switch_root or pivot_root).
5. PID 1 starts the service manager and target-specific system services, then launches the selected login/display/session path. Readiness is a userspace assertion, not merely a kernel boot banner.

Koronos should preserve the same separation while using its own explicit contract:

| Linux reference event | Koronos handoff event | Required evidence |
|---|---|---|
| Bootloader passes kernel/initramfs | Jasper/Gates/GRUB passes the Koronos image and typed Multiboot2 modules | Boot report, module type/size/hash and target identity |
| Kernel initializes scheduler, memory and VFS | Koronos emits KORONOS READY only after core services and module table are usable | QEMU debugcon marker plus kernel invariant checks |
| Kernel executes /init as PID 1 | target_launch validates the selected target ELF and enters its ring-3 entry point | ELF admission, address-space setup, ring-3 transition and target PID |
| Init mounts root and starts services | Live/Installer/Recovery init consumes its target manifest and mounts its declared root/runtime | Mount and dependency trace; fail closed on missing providers |
| Service manager reaches target readiness | Kore reports target-specific service readiness | Per-service health checks and explicit target-ready marker |
| Display manager starts a desktop session | Display server/compositor starts the selected desktop profile | Display/input provider readiness, shell marker and app-launch smoke tests |

The three Koronos target contracts must remain distinct:

- **Live:** interactive live environment, storage discovery and display/session startup.
- **Installer:** partition and filesystem planning followed by explicit, confirmed block-device writes, read-back verification and rollback/error handling.
- **Recovery:** emergency shell and diagnostics first; filesystem repair is a separate privileged operation with explicit target selection and post-repair verification.

A target init ELF entering ring 3 proves the kernel-to-userspace control transfer only. It does not prove that a graphical session, installer write path, recovery repair path, or all Linux userspace services are complete. Keep these as separate acceptance gates.

The LinuxKoronos hosted executable is a different path: Linux remains the real host kernel and PID 1; the adapter launches child processes with the host process API. It is not evidence of the freestanding Koronos boot sequence above.



## Linux boot handoff reference and Koronos target mapping

This section treats Linux as a behavioral reference, not as code that can be relabeled as a Koronos implementation. The Linux sequence below is the reference contract used when designing the Linux-hosted Koronos adapter and the native Koronos target loader.

### Linux kernel-to-userspace sequence

| Linux reference stage | Observable Linux behavior | Koronos counterpart | Required evidence |
|---|---|---|---|
| Firmware and bootloader | Firmware loads GRUB/systemd-boot and the selected kernel plus initramfs | BIOS/UEFI → GRUB/Jasper/Gates → Multiboot2 Koronos ELF and modules | Boot report, kernel ELF validation, firmware boot trace |
| Kernel entry | Kernel validates boot parameters, memory map, command line and initrd | Koronos validates Multiboot2 information and classifies bounded modules | Kernel debug trace and module-classification tests |
| Early userspace | Kernel unpacks initramfs and executes its configured `/init` | Koronos selects exactly one `USER_INIT_ELF` with a matching `target=` value | Module count, target match, ELF admission and address-space checks |
| Process entry | Linux transfers control to PID 1 in userspace | Koronos enters the admitted ELF at CPL3 with a dedicated CR3 and bounded stack | CPL3 syscall acknowledgement, RIP/CR3/PID validation |
| Root transition | Early init mounts the real root and switches root/pivots root | Target init mounts or activates its target root/runtime through explicit target services | Mount/root transition trace; not currently implied by ring-3 entry |
| Service startup | PID 1 starts configured services and reaches a declared boot target | Kore/service manager starts declared Koronos services and reports target readiness | Per-service readiness, dependency state, exit status and target marker |
| Session/display | Display manager starts compositor/X server and a user session | Native display server/compositor starts the selected desktop profile | Compositor protocol test, session launch and visible desktop smoke test |

Linux's initramfs `/init` is PID 1 (or hands off to the real init); it is not equivalent to merely loading an ELF into ring 3. Likewise, a successful CPL3 entry and target-specific readiness marker prove the narrow init handshake only. They do not prove root mounting, service completeness, a graphical session, disk installation, or filesystem repair.

### Three native target userspaces

| Target | Linux reference model | Koronos entry artifact | Current verified scope | Remaining production work |
|---|---|---|---|---|
| Live | initramfs `/init`, systemd/sysvinit service graph, udev/device discovery, display manager | `target-init-live.elf`, Live initramfs and Live manifest | OctavianOS candidate: native ELF enters ring 3, performs DPL3 syscall acknowledgement, emits Live readiness, and remains resident as kernel-verified PID 1; BIOS and UEFI acceptance passed | Real root/runtime activation, device discovery, network/audio/storage services, compositor/X server, login/session and app launch |
| Installer | Anaconda, Debian Installer, Subiquity/ curtin style installer environment | `target-init-installer.elf`, installation image, manifest and installer contracts | OctavianOS candidate: persistent PID 1 and installer readiness passed BIOS and UEFI; current implementation is still a dry-run storage plan with no block writes | Partition discovery, explicit destructive-operation confirmation, GPT/MBR handling, filesystem creation, block-device writes, bootloader install, rollback and post-install boot test |
| Recovery | initramfs emergency shell, systemd rescue/emergency targets, fsck and recovery utilities | `target-init-recovery.elf`, Recovery initramfs and manifest | OctavianOS candidate: persistent PID 1 and recovery readiness passed BIOS and UEFI; current implementation is still diagnostics-only with no filesystem repair | Real read-only-first volume discovery, filesystem-specific repair tools, repair logs, backup/rollback safeguards and damaged-image tests |

### Linux userspace layers to Koronos userspace services

| Linux userspace layer | Linux examples | Koronos service/API destination | Implementation status rule |
|---|---|---|---|
| Init and service supervision | systemd, OpenRC, SysV init | Kore service manager, dependency graph and target units | A mapped service name is not a running service; require start/health/stop tests |
| Device management | udev, eudev, mdev | Koronos device manager and driver-event broker | Require real device enumeration and hotplug tests |
| Storage and mounts | util-linux, mount, blkid, udisks2 | VFS, block layer, filesystem drivers and mount service | Require actual block-device and filesystem integration tests |
| Networking | iproute2, NetworkManager, systemd-networkd, wpa_supplicant | Spotnik networking stack and network service adapters | Require link, DHCP/static config, DNS and packet tests |
| Logging and diagnostics | journald, rsyslog, dmesg, procps | Koronos event log, kernel trace, process and diagnostics services | Require persistent log and process introspection tests |
| Security | PAM, polkit, auditd, SELinux/AppArmor | Aegis policy, authentication and audit services | Require enforced policy tests; catalogue references alone are not enforcement |
| Desktop/display | Wayland compositors, Xorg, display managers | Native Koronos display server, compositor and session manager | Require native protocol and real session tests; host previews are not native compositor proof |
| Shell and commands | coreutils, Bash, GNU utilities, BSD userland | Koronos command registry, native providers and compatibility adapters | Track each command, option, architecture, provider provenance and test result independently |
| Databases | SQLite, PostgreSQL, MariaDB, Redis, DuckDB and others | Native packages or explicitly hosted provider services | Require license/source provenance, architecture build, persistent storage and SQL/protocol tests |

### Linux-hosted Koronos boundary

The LinuxKoronos executable is a Linux-hosted process adapter. It uses Linux host facilities (including process creation and host command execution) and exposes a Koronos-oriented interface. It is not a replacement for the native Koronos kernel, does not boot as PID 1, and does not claim to implement the three native boot targets. Keep host-adapter CI results separate from native-kernel, installer, recovery, desktop and device acceptance results.

### Acceptance evidence checklist

- [ ] Kernel and bootloader artifacts validated for the target architecture.
- [ ] Exactly one selected native init ELF, with explicit target identity and bounded module metadata.
- [ ] ELF admission, address-space ownership and CPL3 entry validated.
- [ ] DPL3 syscall acknowledgement and target-specific readiness marker tied to the active PID.
- [ ] Target init completes root/runtime activation and service startup (not merely prints readiness).
- [ ] Live reaches a real login/session and launches the selected desktop.
- [ ] Installer writes to a disposable virtual disk and the resulting disk boots.
- [ ] Recovery repairs deliberately damaged disposable filesystem images and records its actions.
- [ ] BIOS and UEFI traces are retained with exact source revision, ISO digest and toolchain metadata.

A checkmark in an upstream CI job should be interpreted only against the tests actually run. Never promote the narrow ring-3 handshake to full userspace or release acceptance.


### Persistent PID 1 verification update — 2026-11-13

The OctavianOS candidate branch fixed a real lifecycle defect in which each target init printed readiness and immediately exited, allowing the kernel to reclaim its address space. The corrected candidate keeps Live, Installer and Recovery init resident, confirms the same process-table PID is still RUNNING, disarms the startup-only timeout only after readiness, and emits the kernel-owned PID1 ACTIVE marker after the user-authored readiness bytes.

Evidence:
- [Six-case target/firmware acceptance #43412390841](https://github.com/amerhwitat/OctavianOS/actions/runs/43412390841): Live, Installer and Recovery passed BIOS and UEFI.
- [Native ISO build and full-ISO QEMU acceptance #43412390877](https://github.com/amerhwitat/OctavianOS/actions/runs/43412390877): build, artwork validation, target routing, complete ISO boot and full-ISO userspace verifier passed.
- Candidate ISO SHA-256: ac5d11e895ea0b8d70e2127b276099e509b7ca51996c7efe09e8368405dde745.

This verifies persistent PID 1 handoff, not complete production userspace. Live is still a text-console payload; Installer does not write disks; Recovery does not repair filesystems; no full VFS/rootfs activation, service supervision, compositor, or desktop session is proven. The LinuxKoronos binary remains a Linux-hosted adapter and must not be conflated with this native Koronos boot path.
