#!/usr/bin/env bash

set -eu

# renovate: datasource=github-tags depName=sqlite/sqlite
SQLITE_COMMIT="${SQLITE_COMMIT:-ba76c160c735437de974c6ea24c890a663214c6b}" # version-3.51.2

# renovate: datasource=github-tags depName=groue/GRDB.swift
GRDB_COMMIT="${GRDB_COMMIT:-36e30a6f1ef10e4194f6af0cff90888526f0c115}" # v7.10.0

# renovate: datasource=github-tags depName=pointfreeco/sqlite-data
SQLITEDATA_COMMIT="${SQLITEDATA_COMMIT:-5de18896e7a0358084bb4e3c83f7227500ba029b}" # 1.5.2

# renovate: datasource=github-tags depName=unum-cloud/USearch
USEARCH_COMMIT="${USEARCH_COMMIT:-40d127f472e9073875566f0e9308c0302b89100a}" # v2.24.0

# renovate: datasource=github-tags depName=nalgeon/sqlean
SQLEAN_COMMIT="${SQLEAN_COMMIT:-0e2985467a5da3d7641447616609f8a8b8665b0a}" # 0.28.1

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
