# Database backend build and integration matrix

The database service boundary is userspace IPC; the kernel does not embed SQL engines.

## Profiles

- `core_embedded`: SQLite (default, low-footprint, public-domain source)
- `local_analytics`: SQLite + DuckDB
- `server_relational`: MariaDB + PostgreSQL + Firebird
- `key_value`: RocksDB + LevelDB + Valkey
- `distributed`: Cassandra + CouchDB

The default LinuxKoronos CI builds SQLite from its pinned official source archive,
verifies the published SHA3-256 before extraction, installs it into a temporary
prefix, and runs an in-memory SQL smoke test. Other backends are selectable
profiles; their source/build/runtime integration must be validated before
claiming they are bundled in an OS image.

## Backend inventory

See `config/database-backend-matrix.json` for each engine's upstream source,
license, Linux/Windows/macOS acquisition/build path, build system, and smoke
test. Source-available projects under SSPL or BSL are listed separately and
excluded from the open-source-only set.

## Reproducible SQLite build

```sh
bash tools/build-database-profile.sh core_embedded
```

Build artifacts are staged under `dist/database/`. The script verifies source
integrity before compiling and does not download prebuilt third-party binaries.
