#!/usr/bin/env bash
set -Eeuo pipefail
KERNEL_VERSION="${KERNEL_VERSION:-7.2.2}"
ARCH="${ARCH:-x86}"
CROSS_COMPILE="${CROSS_COMPILE:-}"
JOBS="${JOBS:-2}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.kernel-work}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/kernel-out}"
SRC_DIR="$WORK_DIR/linux-$KERNEL_VERSION"
ARCHIVE="$WORK_DIR/linux-$KERNEL_VERSION.tar.xz"
SIGNATURE="$ARCHIVE.sign"
BASE_URL="https://cdn.kernel.org/pub/linux/kernel/v7.x"
case "$ARCH" in
  x86) IMAGE_TARGET=bzImage; IMAGE_REL=arch/x86/boot/bzImage ;;
  arm64) IMAGE_TARGET=Image; IMAGE_REL=arch/arm64/boot/Image ;;
  *) echo "Unsupported ARCH=$ARCH (supported: x86, arm64)" >&2; exit 2 ;;
esac
mkdir -p "$WORK_DIR" "$OUT_DIR"
[[ -f "$ARCHIVE" ]] || curl --fail --location --retry 3 "$BASE_URL/linux-$KERNEL_VERSION.tar.xz" -o "$ARCHIVE"
[[ -f "$SIGNATURE" ]] || curl --fail --location --retry 3 "$BASE_URL/linux-$KERNEL_VERSION.tar.sign" -o "$SIGNATURE"
GNUPGHOME="$WORK_DIR/gnupg"; mkdir -p "$GNUPGHOME"; chmod 700 "$GNUPGHOME"; export GNUPGHOME
KERNEL_SIGNING_KEY=647F28654894E3BD457199BE38DBBDC86092693E
# Kernel.org signs the uncompressed .tar stream, not the downloaded .tar.xz.
# Fetch the release key through kernel.org WKD (TLS-authenticated), pin its
# full fingerprint, then verify the decompressed stream before extraction.
gpg --batch --locate-keys gregkh@kernel.org
ACTUAL_FINGERPRINT="$(gpg --batch --with-colons --fingerprint gregkh@kernel.org | awk -F: '$1 == "fpr" { print $10; exit }')"
[[ "$ACTUAL_FINGERPRINT" == "$KERNEL_SIGNING_KEY" ]] || { echo "Unexpected Linux kernel signing-key fingerprint: $ACTUAL_FINGERPRINT" >&2; exit 1; }
xz --decompress --stdout "$ARCHIVE" | gpg --batch --verify "$SIGNATURE" -
[[ -d "$SRC_DIR" ]] || tar -C "$WORK_DIR" -xf "$ARCHIVE"
BUILD_DIR="$WORK_DIR/build-$ARCH"; STAGE_DIR="$WORK_DIR/stage-$ARCH"
rm -rf "$BUILD_DIR" "$STAGE_DIR"; mkdir -p "$BUILD_DIR" "$STAGE_DIR"
make -C "$SRC_DIR" O="$BUILD_DIR" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" defconfig
make -C "$SRC_DIR" O="$BUILD_DIR" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" -j"$JOBS" "$IMAGE_TARGET" modules dtbs
make -C "$SRC_DIR" O="$BUILD_DIR" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" modules_install INSTALL_MOD_PATH="$STAGE_DIR/rootfs"
make -C "$SRC_DIR" O="$BUILD_DIR" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" headers_install INSTALL_HDR_PATH="$STAGE_DIR/headers"
install -D "$BUILD_DIR/$IMAGE_REL" "$STAGE_DIR/boot/$([[ "$ARCH" == arm64 ]] && echo Image || echo bzImage)"
if [[ -d "$BUILD_DIR/arch/$ARCH/boot/dts" ]]; then mkdir -p "$STAGE_DIR/boot/dtbs"; cp -a "$BUILD_DIR/arch/$ARCH/boot/dts/." "$STAGE_DIR/boot/dtbs/"; fi
for f in .config System.map Module.symvers; do [[ ! -f "$BUILD_DIR/$f" ]] || install -D "$BUILD_DIR/$f" "$STAGE_DIR/build-metadata/$f"; done
printf "Linux %s\nARCH=%s\nCROSS_COMPILE=%s\n" "$KERNEL_VERSION" "$ARCH" "$CROSS_COMPILE" > "$STAGE_DIR/BUILD-INFO.txt"
mkdir -p "$OUT_DIR"; tar -C "$STAGE_DIR" -czf "$OUT_DIR/linux-$KERNEL_VERSION-$ARCH.tar.gz" .
sha256sum "$OUT_DIR/linux-$KERNEL_VERSION-$ARCH.tar.gz" > "$OUT_DIR/linux-$KERNEL_VERSION-$ARCH.tar.gz.sha256"
echo "Kernel package: $OUT_DIR/linux-$KERNEL_VERSION-$ARCH.tar.gz"
