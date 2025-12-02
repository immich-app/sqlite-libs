#ifndef GRDB_SHIM_H
#define GRDB_SHIM_H

#include "sqlite3.h"

// MARK: - Variadic Functions Support

// sqlite3_config() is a variadic function that can't be directly called from
// Swift. This shim provides a typed wrapper for the specific use case needed.

static inline void _registerErrorLogCallback(void (*callback)(void *pArg, int iErrCode, const char *zMsg)) {
    sqlite3_config(SQLITE_CONFIG_LOG, callback, 0);
}

// sqlite3_db_config() is also variadic. These helpers provide typed access.

static inline void _enableDoubleQuotedStringLiterals(sqlite3 *db) {
    sqlite3_db_config(db, SQLITE_DBCONFIG_DQS_DML, 1, (void *)0);
    sqlite3_db_config(db, SQLITE_DBCONFIG_DQS_DDL, 1, (void *)0);
}

static inline void _disableDoubleQuotedStringLiterals(sqlite3 *db) {
    sqlite3_db_config(db, SQLITE_DBCONFIG_DQS_DML, 0, (void *)0);
    sqlite3_db_config(db, SQLITE_DBCONFIG_DQS_DDL, 0, (void *)0);
}

static inline void _disableDefensiveMode(sqlite3 *db) {
    sqlite3_db_config(db, SQLITE_DBCONFIG_DEFENSIVE, 0, (void *)0);
}

// MARK: - Preupdate Hook Functions

// These functions are always declared since they're compiled into our custom
// SQLite build with SQLITE_ENABLE_PREUPDATE_HOOK defined.
// Note: We cannot use #ifdef here because SPM cSettings don't propagate
// to header preprocessing.

SQLITE_API void *sqlite3_preupdate_hook(
  sqlite3 *db,
  void(*xPreUpdate)(
    void *pCtx,
    sqlite3 *db,
    int op,
    char const *zDb,
    char const *zName,
    sqlite3_int64 iKey1,
    sqlite3_int64 iKey2
  ),
  void*
);
SQLITE_API int sqlite3_preupdate_old(sqlite3 *, int, sqlite3_value **);
SQLITE_API int sqlite3_preupdate_count(sqlite3 *);
SQLITE_API int sqlite3_preupdate_depth(sqlite3 *);
SQLITE_API int sqlite3_preupdate_new(sqlite3 *, int, sqlite3_value **);

// MARK: - Snapshot Functions

SQLITE_API SQLITE_EXPERIMENTAL int sqlite3_snapshot_get(
  sqlite3 *db,
  const char *zSchema,
  sqlite3_snapshot **ppSnapshot
);

SQLITE_API SQLITE_EXPERIMENTAL int sqlite3_snapshot_open(
  sqlite3 *db,
  const char *zSchema,
  sqlite3_snapshot *pSnapshot
);

SQLITE_API SQLITE_EXPERIMENTAL void sqlite3_snapshot_free(sqlite3_snapshot*);

SQLITE_API SQLITE_EXPERIMENTAL int sqlite3_snapshot_cmp(
  sqlite3_snapshot *p1,
  sqlite3_snapshot *p2
);

SQLITE_API SQLITE_EXPERIMENTAL int sqlite3_snapshot_recover(sqlite3 *db, const char *zDb);

#endif /* GRDB_SHIM_H */
