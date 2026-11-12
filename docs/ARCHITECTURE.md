# Linux hosted architecture

LinuxKoronos is a hosted Koronos environment, not a second kernel. Linux remains the sole kernel and owns scheduling, address spaces, VFS, networking, drivers, and security policy. The Koronos supervisor is an unprivileged process.

## Layers

1. Host discovery and capability reporting.
2. Process adapter (initial milestone: fork/exec/wait).
3. Filesystem adapter (future; preserve Linux permissions and mount boundaries).
4. Network adapter (future; no privileged interface changes by default).
5. Versioned Koronos user-space ABI shim (future).
6. Desktop/session adapter (future; compositor integration is not implemented).

## Safety

The bootstrap does not invoke a shell for child processes, use sudo, write boot sectors, mount disks, flash phones, download proprietary OS binaries, or bypass host permissions. A hosted program is not a native Koronos ELF/EFI target. Bare-metal Koronos boot and target-init acceptance remain separate projects.
