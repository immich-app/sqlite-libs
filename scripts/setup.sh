#!/usr/bin/env bash

set -eu

GRDB_VERSION="${GRDB_VERSION:-v7.8.0}"
SQLITE_VERSION="${SQLITE_VERSION:-3510100}"
SQLITE_YEAR="${SQLITE_YEAR:-2025}"
SQLITEDATA_VERSION="${SQLITEDATA_VERSION:-1.3.0}"
USEARCH_VERSION="${USEARCH_VERSION:-v2.21.3}"
SQLEAN_VERSION="${SQLEAN_VERSION:-0.27.1}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${1:-$ROOT_DIR}"
TEMPLATES_DIR="${SCRIPT_DIR}/ios"

if [ ! -d "${TEMPLATES_DIR}" ]; then
    echo "Error: ios/ templates directory not found at ${TEMPLATES_DIR}"
    exit 1
fi

echo "Creating GRDB + SQLiteData package..."
echo "  GRDB: ${GRDB_VERSION}"
echo "  SQLite: ${SQLITE_VERSION}"
echo "  SQLiteData: ${SQLITEDATA_VERSION}"
echo "  USearch: ${USEARCH_VERSION}"
echo "  SQLean: ${SQLEAN_VERSION}"

rm -rf "${OUTPUT_DIR}/Sources"
mkdir -p "${OUTPUT_DIR}/Sources"/{GRDB,SQLiteCustom,SQLiteData,SQLiteExtensions/include,SQLiteExtensions/sqlean}
mkdir -p "${OUTPUT_DIR}/Sources"/SQLiteExtensions/usearch/{include/usearch,stringzilla/include/stringzilla,stringzilla/c,simsimd/include/simsimd,fp16/include/fp16}
cd "${OUTPUT_DIR}"

TEMP=$(mktemp -d)
trap "rm -rf ${TEMP}" EXIT

echo "Downloading GRDB..."
curl -sL "https://github.com/groue/GRDB.swift/archive/refs/tags/${GRDB_VERSION}.tar.gz" \
    | tar -xz -C "${TEMP}"
cp -R "${TEMP}"/GRDB.swift-*/GRDB/. Sources/GRDB/
cp "${TEMP}"/GRDB.swift-*/LICENSE Sources/GRDB/LICENSE

echo "Downloading SQLite..."
curl -sL "https://www.sqlite.org/${SQLITE_YEAR}/sqlite-amalgamation-${SQLITE_VERSION}.zip" \
    -o "${TEMP}/sqlite.zip"
unzip -q "${TEMP}/sqlite.zip" -d "${TEMP}"
SQLITE_DIR=$(find "${TEMP}" -type d -name "sqlite-amalgamation-*" | head -1)
cp "${SQLITE_DIR}/sqlite3.c" Sources/SQLiteCustom/
cp "${SQLITE_DIR}/sqlite3.h" Sources/SQLiteCustom/
cp "${SQLITE_DIR}/sqlite3ext.h" Sources/SQLiteCustom/

echo "Downloading SQLiteData..."
curl -sL "https://github.com/pointfreeco/sqlite-data/archive/refs/tags/${SQLITEDATA_VERSION}.tar.gz" \
    | tar -xz -C "${TEMP}"
cp -R "${TEMP}"/sqlite-data-*/Sources/SQLiteData/. Sources/SQLiteData/
cp "${TEMP}"/sqlite-data-*/LICENSE Sources/SQLiteData/LICENSE
rm -rf Sources/SQLiteData/CloudKit Sources/SQLiteData/Documentation.docc 2>/dev/null || true

echo "Downloading USearch..."
git clone --quiet --depth 1 --branch "${USEARCH_VERSION}" --recursive --shallow-submodules \
    https://github.com/unum-cloud/USearch.git "${TEMP}/usearch"
cp "${TEMP}/usearch/include/usearch/"*.hpp Sources/SQLiteExtensions/usearch/include/usearch/
cp "${TEMP}/usearch/sqlite/lib.cpp" Sources/SQLiteExtensions/usearch/
cp "${TEMP}/usearch/LICENSE" Sources/SQLiteExtensions/usearch/LICENSE
cp "${TEMP}/usearch/stringzilla/include/stringzilla/"*.h Sources/SQLiteExtensions/usearch/stringzilla/include/stringzilla/
cp "${TEMP}/usearch/stringzilla/include/stringzilla/"*.hpp Sources/SQLiteExtensions/usearch/stringzilla/include/stringzilla/
cp "${TEMP}/usearch/stringzilla/c/lib.c" Sources/SQLiteExtensions/usearch/stringzilla/c/
cp "${TEMP}/usearch/stringzilla/LICENSE" Sources/SQLiteExtensions/usearch/stringzilla/LICENSE
cp "${TEMP}/usearch/simsimd/include/simsimd/"*.h Sources/SQLiteExtensions/usearch/simsimd/include/simsimd/
cp "${TEMP}/usearch/simsimd/LICENSE" Sources/SQLiteExtensions/usearch/simsimd/LICENSE
cp "${TEMP}/usearch/fp16/include/fp16/"*.h Sources/SQLiteExtensions/usearch/fp16/include/fp16/
cp "${TEMP}/usearch/fp16/LICENSE" Sources/SQLiteExtensions/usearch/fp16/LICENSE

echo "Downloading SQLean..."
curl -sL "https://github.com/nalgeon/sqlean/archive/refs/tags/${SQLEAN_VERSION}.tar.gz" \
    | tar -xz -C "${TEMP}"
cp "${TEMP}"/sqlean-*/src/sqlean.h Sources/SQLiteExtensions/sqlean/
cp "${TEMP}"/sqlean-*/src/sqlite3-uuid.c Sources/SQLiteExtensions/sqlean/
cp -R "${TEMP}"/sqlean-*/src/uuid Sources/SQLiteExtensions/sqlean/
cp "${TEMP}"/sqlean-*/src/sqlite3-text.c Sources/SQLiteExtensions/sqlean/
cp -R "${TEMP}"/sqlean-*/src/text Sources/SQLiteExtensions/sqlean/
cp "${TEMP}"/sqlean-*/LICENSE Sources/SQLiteExtensions/sqlean/LICENSE

cp "${TEMPLATES_DIR}/shim.h" Sources/SQLiteCustom/
cp "${TEMPLATES_DIR}/GRDBSQLite.h" Sources/SQLiteCustom/
cp "${TEMPLATES_DIR}/SQLiteExtensions/initialize-extensions.c" Sources/SQLiteExtensions/
cp "${TEMPLATES_DIR}/SQLiteExtensions/include/initialize-extensions.h" Sources/SQLiteExtensions/include/

echo ""
echo "Setting up Android build..."
"${SCRIPT_DIR}/setup-android.sh"
