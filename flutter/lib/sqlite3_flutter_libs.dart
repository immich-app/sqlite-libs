/// Flutter plugin providing custom SQLite build with extensions.
///
/// This package bundles a custom SQLite build with FTS5, USearch vector search,
/// and SQLean extensions (uuid, text). It serves as a drop-in replacement for
/// the standard sqlite3_flutter_libs package.
library sqlite3_flutter_libs;

/// No-op for API compatibility with sqlite3_flutter_libs.
///
/// The original function worked around a bug in Android 6.0.1's dynamic linker.
/// This is unnecessary for minSdk 26+.
Future<void> applyWorkaroundToOpenSqlite3OnOldAndroidVersions() async {}
