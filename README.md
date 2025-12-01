# SQLite Libraries

This repository bundles a custom SQLite build for use as a dependency in iOS and Android apps via SPM, JitPack, pub and CocoaPods. Included are:

- SQLite amalgamation, built with optimized settings and the following official extensions:
  - snapshot
  - fts5
  - rtree
  - math
  - percentile
  - geopoly
- USearch vector extension (SIMD vector search and various distance metrics)
- SQLean's uuid extension (native UUID support, including UUIDv7)
- SQLean's text extension (QoL helpers that exist in PostgreSQL)
- GRDB (Swift SQLite driver, statically linked to custom SQLite)
- SQLiteData (Swift query builder, built on GRDB)

The dependencies are prepared via `scripts/setup.sh`, which downloads and organizes the relevant source code and adds a few shims.