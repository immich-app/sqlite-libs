Pod::Spec.new do |s|
  s.name             = 'sqlite3_flutter_libs'
  s.version          = '0.1.1' # x-release-please-version
  s.summary          = 'Custom SQLite build with extensions for Flutter'
  s.description      = <<-DESC
Flutter plugin providing a custom SQLite build with FTS5, USearch vector search,
and SQLean extensions (uuid, text). The native library is provided by the
sqlite-libs Swift Package.
                       DESC
  s.homepage         = 'https://github.com/immich-app/sqlite-libs'
  s.license          = { :type => 'AGPLv3' }
  s.author           = { 'Mert Alev' => '' }
  s.source           = { :path => '.' }

  s.source_files = 'sqlite3_flutter_libs/Sources/sqlite3_flutter_libs/**/*.swift'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.swift_version = '5.0'

  # The actual SQLite library comes from the sqlite-libs SPM package,
  # which is added to the iOS/macOS app via SPM or through the podspec's
  # script phase below.

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    # Ensure we can find the SQLite symbols from the parent SPM package
    'OTHER_LDFLAGS' => '-lsqlite3',
  }
end
