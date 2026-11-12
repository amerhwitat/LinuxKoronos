# LinuxKoronos — Linux-hosted Koronos edition

LinuxKoronos is the hosted edition of Koronos, designed to run as an ordinary, unprivileged process on a Linux builder and Linux workstation. Linux remains the operating-system kernel and supplies scheduling, virtual memory, filesystems, networking, and device drivers. This project is **not** the freestanding Koronos microkernel and does not claim bare-metal boot capability.

## Build and test

Requirements: Linux, CMake 3.20+, a C++20 compiler, and Python 3.10+ for future integration tests.

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

The intended builder is Ubuntu 24.04 x86_64. The first milestone is a reproducible host supervisor and process adapter. All commands are executed as the current user; no sudo, raw-device access, filesystem mounting, or bootloader changes are performed.

## Planned components

- **Host supervisor:** reports Linux kernel and machine information.
- **Process adapter:** launches an explicit executable and argument vector without invoking a shell.
- **Host profile:** machine-readable statement of which services remain owned by Linux.
- **Koronos ABI layer:** future, versioned user-space compatibility layer.
- **Desktop/session integration:** future compositor and Aurora/Marine session work.

## Verification policy

Hosted execution is not native Koronos execution. A successful Linux-hosted build does not prove that the Koronos microkernel, Live/Installer/Recovery target init binaries, mobile images, or desktop compositor are complete. Each requires its own build, runtime test, and evidence.

## Current scope

This repository is being bootstrapped in small verifiable increments. The initial commit defines architecture and acceptance boundaries; implementation and CI must pass before a release is called runnable.
