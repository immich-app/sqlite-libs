#ifndef GRDBSQLITE_H
#define GRDBSQLITE_H

// Umbrella header for the GRDBSQLite module
// This header exposes SQLite and the GRDB shim to Swift

// SQLITE_CORE must be defined before including sqlite3ext.h
// to prevent it from redefining functions to use sqlite3_api
#ifndef SQLITE_CORE
#define SQLITE_CORE 1
#endif

#include "sqlite3.h"
#include "sqlite3ext.h"
#include "shim.h"

#endif /* GRDBSQLITE_H */
