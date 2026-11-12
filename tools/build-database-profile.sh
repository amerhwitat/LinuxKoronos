#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${1:-core_embedded}"
OUT="${DATABASE_OUT:-$ROOT/dist/database}"
WORK="${DATABASE_WORK:-$ROOT/.cache/database}"
mkdir -p "$OUT" "$WORK"
case "$PROFILE" in
  core_embedded) ENGINES="sqlite" ;;
  local_analytics) ENGINES="sqlite duckdb" ;;
  server_relational) ENGINES="mariadb postgresql firebird" ;;
  key_value) ENGINES="rocksdb leveldb valkey" ;;
  distributed) ENGINES="cassandra couchdb" ;;
  *) echo "Unknown database profile: $PROFILE" >&2; exit 2 ;;
esac
if [[ "$ENGINES" != "sqlite" ]]; then
  echo "Profile '$PROFILE' is declared but upstream build recipes are not yet pinned/implemented for every engine: $ENGINES" >&2
  echo "No backend is reported as built. Use core_embedded for the verified SQLite build." >&2
  exit 3
fi
VERSION=3.54.1
ARCHIVE="sqlite-autoconf-3540100.tar.gz"
URL="https://www.sqlite.org/2026/$ARCHIVE"
EXPECTED_SHA3="b6ced585c750916b1052667239a12c25a7ff34e7f06e1e6e01ecb0427657d9c4"
SRC="$WORK/$ARCHIVE"
if [[ ! -f "$SRC" ]]; then
  curl --fail --location --retry 3 "$URL" -o "$SRC"
fi
ACTUAL_SHA3="$(python3 - "$SRC" <<'PY'
import hashlib, pathlib, sys
h=hashlib.sha3_256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest()
print(h)
PY
)"
[[ "$ACTUAL_SHA3" == "$EXPECTED_SHA3" ]] || { echo "SQLite SHA3-256 mismatch: $ACTUAL_SHA3" >&2; exit 1; }
rm -rf "$WORK/sqlite-$VERSION" "$WORK/sqlite-prefix"
mkdir -p "$WORK/sqlite-$VERSION"
tar -xzf "$SRC" --strip-components=1 -C "$WORK/sqlite-$VERSION"
(
  cd "$WORK/sqlite-$VERSION"
  ./configure --prefix="$WORK/sqlite-prefix" --enable-fts5
  make -j"${JOBS:-2}"
  make install
)
"$WORK/sqlite-prefix/bin/sqlite3" --version
"$WORK/sqlite-prefix/bin/sqlite3" :memory: 'CREATE TABLE smoke(v INTEGER); INSERT INTO smoke VALUES (42); SELECT v FROM smoke;'
mkdir -p "$OUT/sqlite"
cp "$WORK/sqlite-prefix/bin/sqlite3" "$OUT/sqlite/"
cp "$WORK/sqlite-prefix/lib/libsqlite3."* "$OUT/sqlite/" 2>/dev/null || true
cp "$WORK/sqlite-prefix/include/sqlite3.h" "$OUT/sqlite/"
printf '%s\n' "$ACTUAL_SHA3  $ARCHIVE" > "$OUT/sqlite/SOURCE-SHA3-256.txt"
printf '%s\n' "SQLite $VERSION built and smoke-tested; profile=$PROFILE" > "$OUT/sqlite/BUILD-STATUS.txt"
