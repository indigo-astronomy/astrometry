/*
 * sys/stat.h wrapper for MinGW-w64 builds on Windows.
 * Includes the real mingw-w64 sys/stat.h, then defines the small set
 * of POSIX macros it doesn't provide (S_ISLNK/S_IFLNK) as harmless
 * always-false fallbacks, since MinGW's stat() doesn't report symlinks
 * via st_mode the way POSIX systems do.
 */
#ifndef ASTROMETRY_WIN_COMPAT_SYS_STAT_H
#define ASTROMETRY_WIN_COMPAT_SYS_STAT_H

#include_next <sys/stat.h>

#ifdef _WIN32
#ifndef S_IFLNK
#define S_IFLNK 0xA000
#endif
#ifndef S_ISLNK
#define S_ISLNK(m) 0
#endif
#endif

#endif
