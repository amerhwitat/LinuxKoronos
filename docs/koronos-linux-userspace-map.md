# Linux-to-Koronos userspace reference map

This map is the implementation contract for the Linux-hosted Koronos edition. It deliberately distinguishes (a) Linux components that can be reused as hosted providers, (b) Koronos-native ABI/services that must be implemented, and (c) boot/runtime features that cannot be inferred from a hosted Linux process.

## Layer map

| Koronos subsystem | Linux reference/provider | Hosted LinuxKoronos integration | Freestanding Koronos requirement |
|---|---|---|---|
| Process creation and supervision | Linux `fork/execve/waitid`, systemd service model | Existing unprivileged process adapter; preserve argv boundaries, exit status and signals | CPL3 process loader, address-space isolation, scheduler, syscall ABI |
| Filesystem namespace and mounts | Linux VFS, FHS, mount namespaces, util-linux | Map user-selected host paths; never mount or write block devices implicitly | Koronos VFS, block layer, filesystem drivers, permissions |
| Core command environment | GNU coreutils, BusyBox, util-linux, findutils, grep, sed, awk, procps-ng | Discover host providers and expose explicit command adapters; do not bundle proprietary binaries | Native command implementations or verified, ABI-compatible provider packages |
| Shells and terminals | Bash, Dash, Zsh, Fish, Readline, ncurses | Launch as child processes through argv-based adapter; PTY support is a separate milestone | PTY/TTY, terminal discipline, job control, signal delivery |
| Networking | iproute2, NetworkManager, systemd-networkd, nftables, OpenSSH | Query host capabilities; privileged changes remain opt-in and host-policy-controlled | Native sockets, network drivers, TCP/IP, firewall |
| Service manager | systemd units, SysV init conventions, D-Bus activation | Translate declared Koronos service descriptors to user-level systemd units where safe | Koronos service manager, dependency graph, supervision and recovery |
| Devices | udev, sysfs, libudev | Read-only discovery by default; explicit capability grant for device operations | PCI/USB enumeration, driver model, device nodes, permissions |
| Graphics and desktop | Wayland, wlroots, X.Org, Mesa, GTK/Qt, XDG portals | Hosted desktop sessions only when a display/socket is available; use host compositor | Native display server/compositor, DRM/KMS, input, GPU drivers |
| Graphics APIs / vision | Mesa OpenGL/Vulkan, OpenCV | Link against distro packages; runtime-detect capabilities and versions | Native graphics stack or a documented hosted ABI |
| Compilers and binary tools | LLVM/Clang, GCC, binutils, GDB, LLDB, QEMU | Invoke installed tools as isolated child processes; report absent tools accurately | Cross toolchains and architecture-specific emulation/decoding |
| Compatibility | binfmt_misc, Wine, QEMU user/system emulation | Optional host providers; no silent downloading or execution of untrusted binaries | Format detection, loader, syscall translation, emulator sandbox |
| Packaging | dpkg/apt, rpm/dnf, apk, pkg | Host package managers remain host-owned; LinuxKoronos can report availability | Koronos package format, signatures, dependency solver |
| Boot and target handoff | systemd initramfs, dracut, initramfs-tools, GRUB | Linux host boot is not a Koronos boot | Native ELF/EFI init, signed target manifests, static recovery path |

## Command-provider mapping

Use the upstream projects as source references, not as a promise that every Linux command is already a Koronos command:

- POSIX shell and text: Bash, Dash, coreutils, findutils, grep, sed, gawk, diffutils.
- Files and storage: util-linux, e2fsprogs, dosfstools, xfsprogs, btrfs-progs, smartmontools.
- Processes and diagnostics: procps-ng, psmisc, lsof, strace, ltrace.
- Networking and remote access: iproute2, iputils, ethtool, nftables, OpenSSH, curl, wget.
- Build and debug: GCC, LLVM/Clang, binutils, CMake, Ninja, Make, GDB, LLDB, QEMU.
- Desktop: Wayland, wlroots, X.Org Server, Mesa, GTK, Qt, PipeWire, PulseAudio compatibility, D-Bus, XDG portals.
- Archive and compression: tar, gzip, xz, zstd, bzip2, unzip, zip.

Each provider needs a recorded upstream URL, version, license, source hash, target ABI, build recipe, test result, and provenance. Do not copy proprietary Windows/macOS binaries or claim ABI compatibility without a tested loader/runtime.

## Build and verification sequence

1. Build the hosted Koronos supervisor with warnings-as-errors and run CTest plus the process-adapter smoke tests.
2. Add host capability discovery and a versioned provider manifest. Host tools are discovered, never assumed.
3. Add PTY-backed terminal sessions, with explicit executable allowlists and no shell-string interpolation in the supervisor.
4. Add read-only host filesystem views first; preserve UID/GID, mode bits, symlink behavior, mount boundaries and path traversal protections.
5. Add optional user-session integrations for D-Bus, Wayland/X11, Mesa, OpenCV and developer tools.
6. Keep freestanding Koronos work on a separate acceptance track: kernel syscall ABI, ELF loader, scheduler, VFS, init, services, graphics, and boot tests.
7. Only mark a feature complete after a reproducible build and a test against the actual runtime path.

## Release boundary

A passing hosted-runtime test does not prove a native Koronos kernel, BIOS/UEFI boot, Live/Installer/Recovery handoff, or a flashable mobile image. Those require separate artifacts and hardware/VM acceptance evidence.
