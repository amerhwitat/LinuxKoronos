# Linux kernel build integration

LinuxKoronos is a userspace runtime on a Linux host. This pipeline builds upstream Linux as its host-kernel reference; it does not replace Linux with the Koronos kernel.

## Pinned upstream baseline
- Source browser: https://elixir.bootlin.com/linux/v7.2.2/source
- Official archive: https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.2.2.tar.xz
- Detached signature: https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.2.2.tar.sign
- The build verifies the detached signature before extraction.
- Version 7.2.2 is pinned for reproducibility; newer stable releases are not silently substituted.

## Build coverage
- x86: bzImage, modules, DTB outputs, exported userspace headers.
- arm64: Image, modules, DTB outputs, exported userspace headers.
- Artifacts include kernel image, installed modules, DTBs where emitted by defconfig, exported headers, config, System.map, Module.symvers and SHA-256 sidecar.

## Local build
Install the dependencies listed in the GitHub Actions workflow, then run:

    ARCH=x86 JOBS=2 bash kernel/build-linux-kernel.sh
    ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- JOBS=2 bash kernel/build-linux-kernel.sh

Outputs are written to kernel-out/. The script does not install the kernel on the running host, alter bootloader entries, load modules or write disks.

## Scope boundaries
A successful compile does not certify Koronos Live/Installer/Recovery handoffs, phone boot compatibility, device-specific Android images or the ChimeraIIOS ISO. Those retain separate runtime acceptance gates.
