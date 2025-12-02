#!/usr/bin/env bash

set -eu

# Setup script for Android SQLite build
# This regenerates the sqlite-android fork with custom SQLite and USearch extension

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ANDROID_DIR="$ROOT_DIR/sqlite-android-custom"
TEMPLATE_DIR="$SCRIPT_DIR/android"
SQLITE_ANDROID_REPO="https://github.com/requery/sqlite-android.git"

echo "=== SQLite Android Setup ==="
echo "Root directory: $ROOT_DIR"
echo "Android directory: $ANDROID_DIR"

echo "Cloning sqlite-android..."
rm -rf "$ANDROID_DIR"
git clone "$SQLITE_ANDROID_REPO" "$ANDROID_DIR"
rm -rf "$ANDROID_DIR/.git"

JNI_DIR="$ANDROID_DIR/sqlite-android/src/main/jni"
SQLITE_DIR="$JNI_DIR/sqlite"
USEARCH_DIR="$JNI_DIR/usearch"
SQLEAN_DIR="$JNI_DIR/sqlean"

# Copy SQLite source files
echo "Copying SQLite source files..."
cp "$ROOT_DIR/Sources/SQLiteCustom/sqlite3.c" "$SQLITE_DIR/"
cp "$ROOT_DIR/Sources/SQLiteCustom/sqlite3.h" "$SQLITE_DIR/"
cp "$ROOT_DIR/Sources/SQLiteCustom/sqlite3ext.h" "$SQLITE_DIR/"

# Copy USearch extension
echo "Copying USearch extension..."
rm -rf "$USEARCH_DIR"
mkdir -p "$USEARCH_DIR"
cp -r "$ROOT_DIR/Sources/SQLiteExtensions/usearch/include" "$USEARCH_DIR/"
cp -r "$ROOT_DIR/Sources/SQLiteExtensions/usearch/stringzilla" "$USEARCH_DIR/"
cp -r "$ROOT_DIR/Sources/SQLiteExtensions/usearch/simsimd" "$USEARCH_DIR/"
cp -r "$ROOT_DIR/Sources/SQLiteExtensions/usearch/fp16" "$USEARCH_DIR/"
cp "$ROOT_DIR/Sources/SQLiteExtensions/usearch/lib.cpp" "$USEARCH_DIR/"
cp "$ROOT_DIR/Sources/SQLiteExtensions/usearch/LICENSE" "$USEARCH_DIR/"

# Copy SQLean extensions (uuid and text)
echo "Copying SQLean extensions..."
rm -rf "$SQLEAN_DIR"
mkdir -p "$SQLEAN_DIR"
cp -r "$ROOT_DIR/Sources/SQLiteExtensions/sqlean/"* "$SQLEAN_DIR/"

# Patch SQLean uuid for Android (timespec_get is not available in Bionic libc)
echo "Patching SQLean uuid for Android..."
UUID_EXT="$SQLEAN_DIR/uuid/extension.c"
sed -i.bak 's/timespec_get(&ts, TIME_UTC)/clock_gettime(CLOCK_REALTIME, \&ts)/' "$UUID_EXT" && rm "$UUID_EXT.bak"

# Copy build configuration files from templates
echo "Copying build configuration files..."
cp "$TEMPLATE_DIR/Application.mk" "$JNI_DIR/"
cp "$TEMPLATE_DIR/Android.mk" "$JNI_DIR/"
cp "$TEMPLATE_DIR/sqlite/Android.mk" "$SQLITE_DIR/"

# Patch android_database_SQLiteConnection.cpp to register extensions
echo "Patching SQLiteConnection for extensions..."
CONNECTION_FILE="$SQLITE_DIR/android_database_SQLiteConnection.cpp"

if grep -q "sqlite3_usearch_sqlite_init" "$CONNECTION_FILE"; then
    echo "  Already patched"
else
    awk '
    /^} \/\/ namespace android/ {
        print
        print ""
        print "// USearch extension init function (defined in usearch/lib.cpp)"
        print "extern \"C\" int sqlite3_usearch_sqlite_init(sqlite3*, char**, const sqlite3_api_routines*);"
        print ""
        print "// SQLean extension init functions (defined in sqlean/)"
        print "extern \"C\" int sqlite3_uuid_init(sqlite3*, char**, const sqlite3_api_routines*);"
        print "extern \"C\" int sqlite3_text_init(sqlite3*, char**, const sqlite3_api_routines*);"
        next
    }
    /android::gpJavaVM = vm;/ {
        print
        getline
        print
        print ""
        print "  // Register extensions to be auto-loaded for all connections"
        print "  sqlite3_auto_extension((void(*)(void))sqlite3_usearch_sqlite_init);"
        print "  sqlite3_auto_extension((void(*)(void))sqlite3_uuid_init);"
        print "  sqlite3_auto_extension((void(*)(void))sqlite3_text_init);"
        next
    }
    { print }
    ' "$CONNECTION_FILE" > "$CONNECTION_FILE.tmp" && mv "$CONNECTION_FILE.tmp" "$CONNECTION_FILE"
    echo "  Patched successfully"
fi

# Patch library name from sqlite3x to sqlite3
echo "Patching library name..."
SQLITE_DB_FILE="$ANDROID_DIR/sqlite-android/src/main/java/io/requery/android/database/sqlite/SQLiteDatabase.java"
sed -i.bak 's/LIBRARY_NAME = "sqlite3x"/LIBRARY_NAME = "sqlite3"/' "$SQLITE_DB_FILE" && rm "$SQLITE_DB_FILE.bak"

# Patch build.gradle
echo "Patching build.gradle..."
BUILD_GRADLE="$ANDROID_DIR/sqlite-android/build.gradle"

awk '
/abiFilters "armeabi-v7a", "arm64-v8a", "x86", "x86_64"/ {
    sub(/abiFilters "armeabi-v7a", "arm64-v8a", "x86", "x86_64"/, "abiFilters \"arm64-v8a\", \"x86_64\"")
}
/^ext \{/,/^preBuild.dependsOn installSqlite/ {
    next
}
{ print }
' "$BUILD_GRADLE" > "$BUILD_GRADLE.tmp" && mv "$BUILD_GRADLE.tmp" "$BUILD_GRADLE"

# Patch gradle.properties for JitPack
echo "Patching gradle.properties for JitPack..."
GRADLE_PROPS="$ANDROID_DIR/gradle.properties"
sed -i.bak 's/^GROUP=.*/GROUP=com.github.immich-app.sqlite-libs/' "$GRADLE_PROPS" && rm "$GRADLE_PROPS.bak"

echo ""
echo "=== Setup complete ==="
echo ""
echo "To build the Android library:"
echo "  cd $ANDROID_DIR"
echo "  ./gradlew :sqlite-android:assembleRelease"
echo ""
echo "To publish to local Maven:"
echo "  ./gradlew :sqlite-android:publishToMavenLocal"
echo ""
echo "The AAR will be at:"
echo "  $ANDROID_DIR/sqlite-android/build/outputs/aar/sqlite-android-release.aar"
