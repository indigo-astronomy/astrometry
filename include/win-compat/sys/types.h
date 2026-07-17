/*
 * sys/types.h wrapper for MinGW-w64 builds on Windows.
 * Includes the real mingw-w64 sys/types.h, then adds the BSD/glibc
 * "uint" typedef that astrometry.net's fitsioutils.c relies on (normally
 * pulled in via _DEFAULT_SOURCE/_BSD_SOURCE on Linux/macOS, but MinGW's
 * CRT doesn't provide it under any feature-test macro).
 */
#ifndef ASTROMETRY_WIN_COMPAT_SYS_TYPES_H
#define ASTROMETRY_WIN_COMPAT_SYS_TYPES_H

#include_next <sys/types.h>

#ifdef _WIN32
typedef unsigned int uint;
#endif

#endif
