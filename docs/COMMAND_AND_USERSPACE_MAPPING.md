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
