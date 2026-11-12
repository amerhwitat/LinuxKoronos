# LinuxKoronos — Linux-hosted Koronos edition

LinuxKoronos is a hosted Koronos runtime for Linux builders and Linux workstations. It runs as an ordinary, unprivileged Linux process. **Linux remains the operating-system kernel** and continues to provide scheduling, virtual memory, filesystems, networking, and hardware drivers. This edition is not the freestanding Koronos microkernel and does not claim bare-metal boot capability.

## Implemented runtime (0.1.0)

- **Host discovery:** reports the Linux kernel release and host machine architecture using `uname(2)`.
- **Host profile:** explicitly identifies host-managed services and states that bare-metal kernel execution is not active.
- **Process adapter:** starts a named executable with an explicit argument vector using `fork(2)` and `execvp(3)`; it does not invoke a shell.
- **Exit propagation:** waits for the child, retries interrupted waits, and propagates exit status or signal-derived status.
- **Unprivileged by default:** no sudo, raw-device writes, filesystem mounts, bootloader changes, or implicit device permissions.

## Build and test

Requirements: Linux, CMake 3.20+, a C++20 compiler, GNU Make, and Bash.

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
cmake --build build --parallel
ctest --test-dir build --output-on-failure
bash tests/smoke.sh ./build/koronos-host
BUILD_DIR=build bash tools/package-linux.sh
```

The Linux builder workflow uses Ubuntu 24.04, warnings-as-errors, CTest, process-adapter smoke tests, and publishes a compressed Linux runtime package plus its SHA-256 file as workflow artifacts.

## Upstream Linux kernel build

The `feat/linux-7.2.2-kernel-build` branch also adds a separately verified upstream Linux 7.2.2 build pipeline for x86 and arm64. It produces kernel images, modules, device-tree outputs, exported headers, and checksummed packages when its CI jobs complete. This kernel build is a host-kernel reference and is not a Koronos bare-metal boot image.

## Usage

```sh
koronos-host info
koronos-host profile
koronos-host run -- /usr/bin/id -u
```

Install the binary under `~/.local/bin` or `/usr/local/bin`. An optional user systemd probe unit is provided at `packaging/systemd/koronos-host-info.service`; it reports host runtime information and is not a long-running init replacement.

## Architecture and boundaries

```text
Linux bootloader → Linux kernel → systemd / user session
                                  │
                                  ▼
                         koronos-host supervisor
                                  │
                         explicit process adapter
                                  │
                         Linux-managed processes
```

The current host runtime does not replace Linux's kernel, scheduler, VFS, networking stack, device drivers, or systemd. A future Koronos host ABI/service layer can be added behind this boundary with separately versioned contracts.

## Not yet implemented

- Freestanding Koronos kernel boot, UEFI/BIOS boot, and native Live/Installer/Recovery init.
- Production installer disk-writing backend and recovery repair operations.
- Aurora Glass / Marine Blue native compositor and desktop session.
- Android/mobile OS image, device-specific signed boot bundles, and phone flashing.
- Full command/ISA provider catalogue, compatibility emulators, or multi-architecture bare-metal boot.

A successful Linux-hosted build validates only this Linux process runtime. It is not evidence that the separate ChimeraIIOS ISO or a phone-flashable image has passed its own runtime acceptance gates.
