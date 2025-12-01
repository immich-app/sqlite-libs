LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

# Custom SQLite flags
# Note: Some flags differ from iOS to maintain compatibility with requery's JNI code:
#   - SQLITE_OMIT_TRACE: removed (requery uses sqlite3_trace)
#   - SQLITE_OMIT_PROGRESS_CALLBACK: removed (requery uses sqlite3_progress_handler)
#   - SQLITE_OMIT_DEPRECATED: removed (sqlite3_trace/profile are deprecated)
sqlite_flags := \
	-DNDEBUG=1 \
	-DSQLITE_ENABLE_SNAPSHOT \
	-DSQLITE_ENABLE_FTS5 \
	-DSQLITE_ENABLE_PREUPDATE_HOOK \
	-DSQLITE_ENABLE_RTREE \
	-DSQLITE_THREADSAFE=2 \
	-DSQLITE_DQS=0 \
	-DSQLITE_DEFAULT_MEMSTATUS=0 \
	-DSQLITE_LIKE_DOESNT_MATCH_BLOBS \
	-DSQLITE_MAX_EXPR_DEPTH=0 \
	-DSQLITE_OMIT_SHARED_CACHE \
	-DSQLITE_USE_ALLOCA \
	-DSQLITE_OMIT_AUTOINIT \
	-DSQLITE_TEMP_STORE=2 \
	-DSQLITE_ENABLE_STAT4 \
	-DSQLITE_CORE \
	-DSQLITE_DEFAULT_CACHE_SIZE=10000 \
	-DSQLITE_DEFAULT_WAL_SYNCHRONOUS \
	-DSQLITE_ENABLE_PERCENTILE \
	-DSQLITE_ENABLE_MATH_FUNCTIONS \
	-DSQLITE_UNTESTABLE \
	-DSQLITE_OMIT_TCL_VARIABLE \
	-DSQLITE_HAVE_ISNAN \
	-DSQLITE_HAVE_LOCALTIME_R \
	-DSQLITE_HAVE_MALLOC_USABLE_SIZE \
	-DSQLITE_HAVE_STRCHRNUL \
	-DSQLITE_ENABLE_GEOPOLY \
	-DHAVE_USLEEP=1 \
	-DSQLITE_DEFAULT_JOURNAL_SIZE_LIMIT=1048576 \
	-DSQLITE_POWERSAFE_OVERWRITE=1 \
	-DSQLITE_DEFAULT_FILE_FORMAT=4 \
	-DSQLITE_ENABLE_MEMORY_MANAGEMENT=1 \
	-DSQLITE_DEFAULT_FILE_PERMISSIONS=0600 \
	-DSQLITE_ENABLE_BATCH_ATOMIC_WRITE \
	-O3

LOCAL_CFLAGS += $(sqlite_flags)
LOCAL_CFLAGS += -Wno-unused-parameter -Wno-int-to-pointer-cast
LOCAL_CFLAGS += -Wno-uninitialized -Wno-parentheses
LOCAL_CPPFLAGS += -Wno-conversion-null

ifeq ($(TARGET_ARCH), arm)
	LOCAL_CFLAGS += -DPACKED="__attribute__ ((packed))"
else
	LOCAL_CFLAGS += -DPACKED=""
endif

# USearch extension flags
usearch_flags := \
	-DSQLITE_CORE \
	-DUSEARCH_USE_SIMSIMD \
	-DUSEARCH_USE_FP16LIB \
	-O3 \
	-ffast-math

LOCAL_CPPFLAGS += $(usearch_flags)

# Source files
LOCAL_SRC_FILES := \
	android_database_SQLiteCommon.cpp \
	android_database_SQLiteConnection.cpp \
	android_database_SQLiteFunction.cpp \
	android_database_SQLiteGlobal.cpp \
	android_database_SQLiteDebug.cpp \
	android_database_CursorWindow.cpp \
	CursorWindow.cpp \
	JNIHelp.cpp \
	JNIString.cpp \
	sqlite3.c \
	../usearch/lib.cpp \
	../sqlean/sqlite3-uuid.c \
	../sqlean/uuid/extension.c \
	../sqlean/sqlite3-text.c \
	../sqlean/text/bstring.c \
	../sqlean/text/rstring.c \
	../sqlean/text/runes.c \
	../sqlean/text/utf8/case.c \
	../sqlean/text/utf8/rune.c \
	../sqlean/text/utf8/utf8.c

# Include paths
LOCAL_C_INCLUDES += \
	$(LOCAL_PATH) \
	$(LOCAL_PATH)/../usearch/include \
	$(LOCAL_PATH)/../usearch/stringzilla/include \
	$(LOCAL_PATH)/../usearch/simsimd/include \
	$(LOCAL_PATH)/../usearch/fp16/include \
	$(LOCAL_PATH)/../sqlean \
	$(LOCAL_PATH)/../sqlean/uuid \
	$(LOCAL_PATH)/../sqlean/text \
	$(LOCAL_PATH)/../sqlean/text/utf8

# Export include path so usearch can find sqlite3ext.h
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)

LOCAL_MODULE := libsqlite3
LOCAL_LDLIBS += -ldl -llog -latomic

include $(BUILD_SHARED_LIBRARY)
