#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
cmake -S "$ROOT" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}" -DBUILD_TESTING=ON
cmake --build "$BUILD_DIR" --parallel "${BUILD_JOBS:-2}"
ctest --test-dir "$BUILD_DIR" --output-on-failure
"$BUILD_DIR/koronos-host" info
