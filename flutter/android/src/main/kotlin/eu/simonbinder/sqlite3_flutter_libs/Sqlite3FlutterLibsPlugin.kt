package eu.simonbinder.sqlite3_flutter_libs

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Flutter plugin that bundles custom SQLite with extensions.
 *
 * This plugin ensures the custom SQLite library (with FTS5, USearch, SQLean extensions)
 * is bundled with the app via the sqlite-android dependency. The plugin class itself
 * is a no-op required by Flutter's plugin system.
 */
class Sqlite3FlutterLibsPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
