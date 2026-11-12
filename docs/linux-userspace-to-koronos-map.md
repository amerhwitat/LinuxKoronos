# Linux userspace to Koronos userspace mapping

Status: architecture plan and porting contract. This document does not claim that the listed Linux projects have already been ported, compiled, or validated on the freestanding Koronos kernel.

## 1. Two execution profiles

| Profile | Kernel owner | What it validates |
|---|---|---|
| LinuxKoronos hosted | Linux | Koronos supervisor, Linux process adapter, host filesystem/process/network integration |
| Koronos native | Koronos | Koronos ELF ABI, syscalls, VFS, process scheduler, devices, target init and native services |

A Linux-hosted executable is not a native Koronos ELF. Linux packages must not be copied into a Koronos root filesystem and marked native without ABI, dependency, and runtime validation.

## 2. Subsystem mapping

| Linux userspace reference | Koronos destination / contract | Required Koronos foundation | Porting and acceptance evidence |
|---|---|---|---|
| systemd (PID 1, units, targets) | Koronos service manager and target graph | native init, process lifecycle, signals, wait, mount API, dependency ordering | boot to multi-user/graphical target; ordered start/stop; failure recovery |
| udev / systemd-udevd | device event manager | device model, sysfs-like metadata, hotplug events, driver discovery | enumerate, add/remove, permission policy |
| logind | session and seat manager | sessions, credentials, input, VT/seat model, IPC | login/logout, seat ownership, suspend/lock contracts |
| D-Bus | system message bus | local sockets or equivalent IPC, credentials, activation | daemon/client interoperability and policy tests |
| glibc / musl | native C library and syscall ABI | stable syscall numbers, TLS, mmap, signals, threads, futex-equivalent primitives | ABI tests, libc testsuite subset, dynamic loader and relocation tests |
| coreutils | native command providers | libc, VFS, process and file metadata syscalls | per-command option tests and documented unsupported options |
| util-linux | mount, lsblk, fdisk, blkid, login utilities | block layer, partition parser, mount namespace, ioctl contracts | loop/block-device tests; no destructive device writes in unit tests |
| procps-ng | process and resource tools | process table, procfs-like view, scheduler and memory accounting | compare process/CPU/memory output to kernel test fixtures |
| iproute2 / iputils | network administration and diagnostics | sockets, netlink-like control plane, NIC drivers, routing | namespace and virtual-NIC integration tests |
| e2fsprogs | ext2/3/4 tools and filesystem checking | block layer, VFS, journaling and locking | image-backed read/write/fsck tests with corruption fixtures |
| OpenSSH | remote access | sockets, crypto, credentials, entropy, process isolation | loopback client/server tests and privilege-separation review |
| bash / dash / BusyBox ash | native shells | process groups, pipes, redirection, signals, terminal/PTY | shell conformance suites and interactive PTY tests |
| Xorg / Wayland / wlroots | native display server/compositor | DRM/KMS or framebuffer, input, shared memory, IPC, GPU | QEMU display test plus real hardware matrix |
| Mesa / OpenGL | graphics stack | DRM, GPU drivers, shader compiler, memory mapping | renderer tests, conformance tests per GPU backend |
| PipeWire / ALSA | audio services | audio device model, DMA, clocks, IPC | loopback capture/playback and latency tests |
| NetworkManager | network configuration service | device events, sockets, DHCP, DNS, routing | virtual NIC DHCP/DNS and reconnect tests |
| PAM / shadow-utils | authentication and account tools | credential store, secure password hashing, ACLs, sessions | account lifecycle, authentication and permission tests |
| package managers (APT, apk, dnf) | Koronos package manager | signed repository metadata, dependency solver, atomic install/rollback | reproducible package install/remove/upgrade and signature rejection |
| FreeBSD rc.d / OpenRC | alternate service-script compatibility | service lifecycle and process supervision | script compatibility tests; no shell-based privileged execution |
| Solaris SMF concepts | declarative service dependency model | service state database and dependency engine | fault containment and restart-policy tests |

## 3. Porting order and dependency gates

1. ABI baseline: document ELF class/machine/ABI, syscall table, calling convention, TLS, signals, mmap, file descriptors, process/thread semantics and dynamic-loader contract.
2. Kernel substrate: finish VFS, block layer, page cache, poll/select, pipes, PTYs, sockets, credentials, timers, signals, process groups and SMP.
3. C runtime: build a minimal musl-based Koronos sysroot only after the ABI substrate passes. Keep the Linux host sysroot separate.
4. Base utilities: port selected coreutils, BusyBox applets, util-linux and procps-ng against the Koronos sysroot. Generate a per-command manifest containing source revision, license, configure flags, binary hash, dependencies, options tested and test results.
5. Service layer: add service manager, device manager, IPC bus, logging, login/session management, networking and package management.
6. Graphics/audio: bring up framebuffer/DRM, input, compositor, Mesa/OpenGL, audio and desktop session services before declaring Aurora Glass or Marine Blue production-ready.
7. Installer/recovery: implement block-device installation, persistent boot configuration, rollback, filesystem checks and repair before promoting Installer or Recovery targets.

Each stage blocks promotion of dependent stages. A compile-only result is not a runtime pass.

## 4. Source and licensing policy

- Prefer upstream source releases and distribution build recipes from Linux, FreeBSD, OpenBSD and illumos/Solaris communities.
- Pin immutable source versions and cryptographic hashes; verify signatures where upstream publishes them.
- Preserve upstream license texts, notices, source-offer obligations and attribution.
- Build from source for the Koronos ABI. Do not bundle proprietary Windows or macOS system binaries or redistribute OS images.
- Windows/macOS compatibility should use documented executable-format inspection and independently licensed compatibility/emulation implementations, not copied OS binaries.

## 5. Per-command / per-provider manifest

Every catalogue entry should have a machine-readable record with at least:

- canonical command name, aliases, category and supported options;
- upstream project, exact source version, source URL, license and source hash;
- target architecture and ABI;
- build recipe, compiler, sysroot and dependency closure;
- output binary path and SHA-256;
- native / hosted / compatibility / emulation execution classification;
- unit, integration and runtime test evidence;
- known unsupported options and manual-page source.

A catalogue entry remains missing until a real provider binary or native implementation and its tests are present. Do not generate placeholder executables to satisfy inventory counts.

## 6. Current implementation boundary

LinuxKoronos 0.1.x is a Linux-hosted process runtime. Linux continues to provide its kernel, scheduler, VFS, networking and device drivers. The Linux 7.2.2 workflow is a separate upstream-kernel reference build. Neither one establishes native Koronos ABI compatibility or completes ChimeraIIOS Live/Installer/Recovery.

The Koronos target-init payloads currently identified by the ISO work are readiness probes: Live is a text-console probe, Installer is a storage-plan dry run, and Recovery is diagnostics-only. They must remain marked non-production until their respective real session, disk-writing and repair backends pass runtime tests.
