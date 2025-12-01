import Foundation

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

/// Flutter plugin that provides custom SQLite with extensions.
///
/// This plugin itself is a no-op - its purpose is to ensure the custom SQLite
/// library (with FTS5, USearch, SQLean extensions) is linked into the app.
/// The actual SQLite symbols come from the sqlite-libs SPM package.
public class Sqlite3FlutterLibsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // No method channel needed on iOS/macOS.
        // The plugin just ensures SQLite is linked via the SPM dependency.
    }
}
