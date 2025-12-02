#!/usr/bin/env bash

set -eu

SQLITE_TAG="${SQLITE_TAG:-3.51.1}"
SQLITE_VERSION="${SQLITE_VERSION:-3510100}"
SQLITE_YEAR="${SQLITE_YEAR:-2025}"
SQLITE_SHA3="${SQLITE_SHA3:-856b52ffe7383d779bb86a0ed1ddc19c41b0e5751fa14ce6312f27534e629b64}"

# renovate: datasource=github-tags depName=groue/GRDB.swift
GRDB_COMMIT="${GRDB_COMMIT:-18497b68fdbb3a09528d260a0a0e1e7e61c8c53d}" # v7.8.0

# renovate: datasource=github-tags depName=pointfreeco/sqlite-data
SQLITEDATA_COMMIT="${SQLITEDATA_COMMIT:-b66b894b9a5710f1072c8eb6448a7edfc2d743d9}" # 1.3.0

# renovate: datasource=github-tags depName=unum-cloud/USearch
USEARCH_COMMIT="${USEARCH_COMMIT:-aaf4949515d30f5f466e65f8f29316db84a59541}" # v2.21.3

# renovate: datasource=github-tags depName=nalgeon/sqlean
SQLEAN_COMMIT="${SQLEAN_COMMIT:-94d8934683ee079a3e8639a7d8445f8b1ea52e36}" # 0.27.1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${1:-$ROOT_DIR}"
TEMPLATES_DIR="${SCRIPT_DIR}/ios"

if [ ! -d "${TEMPLATES_DIR}" ]; then
    echo "Error: ios/ templates directory not found at ${TEMPLATES_DIR}"
    exit 1
fi

echo "Creating GRDB + SQLiteData package..."
echo "  GRDB: ${GRDB_COMMIT}"
echo "  SQLite: ${SQLITE_VERSION}"
echo "  SQLiteData: ${SQLITEDATA_COMMIT}"
echo "  USearch: ${USEARCH_COMMIT}"
echo "  SQLean: ${SQLEAN_COMMIT}"

rm -rf "${OUTPUT_DIR}/Sources"
mkdir -p "${OUTPUT_DIR}/Sources"/{GRDB,SQLiteCustom,SQLiteData,SQLiteExtensions/include,SQLiteExtensions/sqlean}
mkdir -p "${OUTPUT_DIR}/Sources"/SQLiteExtensions/usearch/{include/usearch,stringzilla/include/stringzilla,stringzilla/c,simsimd/include/simsimd,fp16/include/fp16}
cd "${OUTPUT_DIR}"

TEMP=$(mktemp -d)
trap "rm -rf ${TEMP}" EXIT

echo "Downloading GRDB..."
curl -sL "https://github.com/groue/GRDB.swift/archive/${GRDB_COMMIT}.tar.gz" \
    | tar -xz -C "${TEMP}"
cp -R "${TEMP}"/GRDB.swift-*/GRDB/. Sources/GRDB/
cp "${TEMP}"/GRDB.swift-*/LICENSE Sources/GRDB/LICENSE

echo "Downloading SQLite..."
curl -sL "https://www.sqlite.org/${SQLITE_YEAR}/sqlite-amalgamation-${SQLITE_VERSION}.zip" \
    -o "${TEMP}/sqlite.zip"
openssl dgst -sha3-256 "${TEMP}/sqlite.zip" | grep -q "${SQLITE_SHA3}" \
    || { echo "Error: SQLite SHA3-256 mismatch!"; exit 1; }
unzip -q "${TEMP}/sqlite.zip" -d "${TEMP}"
SQLITE_DIR=$(find "${TEMP}" -type d -name "sqlite-amalgamation-*" | head -1)
cp "${SQLITE_DIR}/sqlite3.c" Sources/SQLiteCustom/
cp "${SQLITE_DIR}/sqlite3.h" Sources/SQLiteCustom/
cp "${SQLITE_DIR}/sqlite3ext.h" Sources/SQLiteCustom/

echo "Downloading SQLite series extension..."
curl -sL "https://www.sqlite.org/src/raw/ext/misc/series.c?ci=${SQLITE_TAG}" \
    -o Sources/SQLiteExtensions/series.c

echo "Downloading SQLiteData..."
curl -sL "https://github.com/pointfreeco/sqlite-data/archive/${SQLITEDATA_COMMIT}.tar.gz" \
    | tar -xz -C "${TEMP}"
cp -R "${TEMP}"/sqlite-data-*/Sources/SQLiteData/. Sources/SQLiteData/
cp "${TEMP}"/sqlite-data-*/LICENSE Sources/SQLiteData/LICENSE
rm -rf Sources/SQLiteData/CloudKit Sources/SQLiteData/Documentation.docc 2>/dev/null || true

echo "Downloading USearch..."
git clone --quiet --depth 1 --recursive --shallow-submodules \
    https://github.com/unum-cloud/USearch.git "${TEMP}/usearch"
git -C "${TEMP}/usearch" fetch --quiet --depth 1 origin "${USEARCH_COMMIT}"
git -C "${TEMP}/usearch" checkout --quiet "${USEARCH_COMMIT}"
git -C "${TEMP}/usearch" submodule update --quiet --recursive
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
curl -sL "https://github.com/nalgeon/sqlean/archive/${SQLEAN_COMMIT}.tar.gz" \
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
