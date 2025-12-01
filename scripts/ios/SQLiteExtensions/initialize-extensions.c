#define SQLITE_CORE 1
#include "sqlite3.h"

// USearch SQLite extension entry point
extern int sqlite3_usearchsqlite_init(sqlite3*, char**, const void*);

// SQLean extension entry points
extern int sqlite3_uuid_init(sqlite3*, char**, const void*);
extern int sqlite3_text_init(sqlite3*, char**, const void*);

int initialize_sqlite3_extensions(void) {
    sqlite3_auto_extension((void (*)(void))sqlite3_usearchsqlite_init);
    sqlite3_auto_extension((void (*)(void))sqlite3_uuid_init);
    sqlite3_auto_extension((void (*)(void))sqlite3_text_init);
    return 0;
}
