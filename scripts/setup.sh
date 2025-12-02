#!/usr/bin/env bash

set -eu

# renovate: datasource=github-tags depName=sqlite/sqlite
SQLITE_COMMIT="${SQLITE_COMMIT:-a1de06a4c639a5d741b2b424e5dfea45eaa30e70}" # version-3.51.1

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
echo "  SQLite: ${SQLITE_COMMIT}"
echo "  GRDB: ${GRDB_COMMIT}"
echo "  SQLiteData: ${SQLITEDATA_COMMIT}"
echo "  USearch: ${USEARCH_COMMIT}"
echo "  SQLean: ${SQLEAN_COMMIT}"

rm -rf "${OUTPUT_DIR}/Sources"
mkdir -p "${OUTPUT_DIR}/Sources"/{GRDB,SQLiteCustom/include,SQLiteData,SQLiteExtensions/include}
mkdir -p "${OUTPUT_DIR}/Sources"/SQLiteExtensions/usearch/{include/usearch,stringzilla/include/stringzilla,stringzilla/c,simsimd/include/simsimd,fp16/include/fp16}
cd "${OUTPUT_DIR}"

TEMP=$(mktemp -d)
trap "rm -rf ${TEMP}" EXIT

echo "Downloading GRDB..."
curl -sL "https://github.com/groue/GRDB.swift/archive/${GRDB_COMMIT}.tar.gz" \
    | tar -xz -C "${TEMP}"
cp -R "${TEMP}"/GRDB.swift-*/GRDB/. Sources/GRDB/
cp "${TEMP}"/GRDB.swift-*/LICENSE Sources/GRDB/LICENSE

echo "Building SQLite amalgamation..."
curl -sL "https://github.com/sqlite/sqlite/archive/${SQLITE_COMMIT}.tar.gz" \
    | tar -xz -C "${TEMP}"
SQLITE_SRC="${TEMP}/sqlite-${SQLITE_COMMIT}"
(cd "${SQLITE_SRC}" && ./configure --quiet --enable-update-limit && make -j sqlite3.c)
cp "${SQLITE_SRC}/sqlite3.c" Sources/SQLiteCustom/
cp "${SQLITE_SRC}/sqlite3.h" Sources/SQLiteCustom/include/
cp "${SQLITE_SRC}/sqlite3ext.h" Sources/SQLiteCustom/include/
cp "${SQLITE_SRC}/ext/misc/series.c" Sources/SQLiteCustom/

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
mkdir -p Sources/SQLiteCustom/sqlean
cp "${TEMP}"/sqlean-*/src/sqlean.h Sources/SQLiteCustom/sqlean/
cp "${TEMP}"/sqlean-*/src/sqlite3-uuid.c Sources/SQLiteCustom/sqlean/
cp -R "${TEMP}"/sqlean-*/src/uuid Sources/SQLiteCustom/sqlean/
cp "${TEMP}"/sqlean-*/src/sqlite3-text.c Sources/SQLiteCustom/sqlean/
cp -R "${TEMP}"/sqlean-*/src/text Sources/SQLiteCustom/sqlean/
cp "${TEMP}"/sqlean-*/LICENSE Sources/SQLiteCustom/sqlean/LICENSE

cp "${TEMPLATES_DIR}/shim.h" Sources/SQLiteCustom/include/
cp "${TEMPLATES_DIR}/GRDBSQLite.h" Sources/SQLiteCustom/include/
cp "${TEMPLATES_DIR}/SQLiteExtensions/initialize-extensions.c" Sources/SQLiteExtensions/
cp "${TEMPLATES_DIR}/SQLiteExtensions/include/initialize-extensions.h" Sources/SQLiteExtensions/include/

echo ""
echo "Setting up Android build..."
"${SCRIPT_DIR}/setup-android.sh"
