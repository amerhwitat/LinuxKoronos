#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
VERSION="${VERSION:-0.1.0}"
ARCH="$(uname -m)"
BIN="$BUILD_DIR/koronos-host"
[[ -x "$BIN" ]] || { echo "missing built runtime: $BIN" >&2; exit 1; }
OUT="$ROOT/dist"
STAGE="$OUT/LinuxKoronos-$VERSION-linux-$ARCH"
rm -rf "$STAGE"
install -d "$STAGE/bin" "$STAGE/share/doc/LinuxKoronos"
install -m 0755 "$BIN" "$STAGE/bin/koronos-host"
install -m 0644 "$ROOT/README.md" "$STAGE/share/doc/LinuxKoronos/README.md"
install -m 0644 "$ROOT/LICENSE" "$STAGE/share/doc/LinuxKoronos/LICENSE"
cat > "$STAGE/README-INSTALL.txt" <<'EOF'
LinuxKoronos hosted runtime
---------------------------
Run: ./bin/koronos-host info
     ./bin/koronos-host profile
     ./bin/koronos-host run -- PROGRAM [ARG ...]

This is an unprivileged Linux-hosted process adapter. Linux remains the kernel.
It does not boot bare-metal Koronos or install/flash a mobile operating system.
EOF
tar -C "$OUT" -czf "$STAGE.tar.gz" "$(basename "$STAGE")"
sha256sum "$STAGE.tar.gz" > "$STAGE.tar.gz.sha256"
printf 'Package: %s\nChecksum: %s\n' "$STAGE.tar.gz" "$STAGE.tar.gz.sha256"
