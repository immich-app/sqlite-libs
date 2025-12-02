#ifndef INITIALIZE_EXTENSIONS_H
#define INITIALIZE_EXTENSIONS_H

// This function is called automatically during sqlite3_initialize()
// via SQLITE_EXTRA_INIT_MUTEXED - no need to call it manually
int sqlite_extensions_init(const char *unused);

#endif
