#define SQLITE_CORE 1
#include "sqlite3.h"

// Extension entry points (C extensions in GRDBSQLite, USearch in SQLiteExtensions)
extern int sqlite3_series_init(sqlite3*, char**, const void*);
extern int sqlite3_uuid_init(sqlite3*, char**, const void*);
extern int sqlite3_text_init(sqlite3*, char**, const void*);
extern int sqlite3_usearchsqlite_init(sqlite3*, char**, const void*);

// Called automatically during sqlite3_initialize() via SQLITE_EXTRA_INIT_MUTEXED
// Runs under the init mutex, so thread-safe
int sqlite_extensions_init(const char *unused) {
    (void)unused;
    sqlite3_auto_extension((void (*)(void))sqlite3_series_init);
    sqlite3_auto_extension((void (*)(void))sqlite3_uuid_init);
    sqlite3_auto_extension((void (*)(void))sqlite3_text_init);
    sqlite3_auto_extension((void (*)(void))sqlite3_usearchsqlite_init);
    return SQLITE_OK;
}
