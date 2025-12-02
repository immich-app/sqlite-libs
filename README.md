# SQLite Libraries

This repository bundles a custom SQLite build for use as a dependency in iOS and Android apps via SPM, JitPack, pub and CocoaPods. Included are:

- SQLite amalgamation, built with optimized settings and the following official extensions:
  - snapshot
  - fts5
  - rtree
  - math
  - percentile
  - geopoly
  - carray
- USearch vector extension (SIMD vector search and various distance metrics)
- SQLean's uuid extension (native UUID support, including UUIDv7)
- SQLean's text extension (QoL helpers that exist in PostgreSQL)
- GRDB (Swift SQLite driver, statically linked to custom SQLite)
- SQLiteData (Swift query builder, built on GRDB)

The dependencies are prepared via `scripts/setup.sh`, which downloads and organizes the relevant source code and adds a few shims.

## Installation

### Flutter (Drift)
```yaml
dependency_overrides:
  sqlite3_flutter_libs:
    git:
      url: https://github.com/immich-app/sqlite-libs
      path: flutter
      ref: <version>
```

### Android (Room/Gradle)
```groovy
repositories {
    maven { url 'https://jitpack.io' }
}
dependencies {
    implementation 'com.github.immich-app.sqlite-libs:sqlite-android:<version>'
}
```

To use with Room:
```kotlin
Room.databaseBuilder(context, AppDatabase::class.java, "db")
    .openHelperFactory(RequerySQLiteOpenHelperFactory())
    .build()
```

### iOS (Swift Package Manager)
Add to your `Package.swift` or Xcode project:
```
https://github.com/immich-app/sqlite-libs @ <version>
```
