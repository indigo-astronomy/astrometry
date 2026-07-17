/*
 * time.h wrapper for MinGW-w64 builds on Windows.
 * Includes the real mingw-w64 time.h, then provides our own
 * guaranteed-out-of-line-safe (static inline) gmtime_r()/localtime_r()
 * wrappers around gmtime_s()/localtime_s(). MinGW-w64 does define these
 * itself under _POSIX_THREAD_SAFE_FUNCTIONS, but as plain (non-static)
 * "__forceinline" functions, which under C99/gnu11 inline semantics can
 * result in "undefined reference" link errors since no out-of-line
 * definition is ever emitted. Defining them ourselves as "static
 * inline" avoids that pitfall.
 */
#ifndef ASTROMETRY_WIN_COMPAT_TIME_H
#define ASTROMETRY_WIN_COMPAT_TIME_H

#include_next <time.h>

#ifdef _WIN32
#ifndef ASTROMETRY_WIN_HAVE_TIME_R
#define ASTROMETRY_WIN_HAVE_TIME_R

static __inline struct tm* gmtime_r(const time_t* t, struct tm* result) {
    return gmtime_s(result, t) ? NULL : result;
}

static __inline struct tm* localtime_r(const time_t* t, struct tm* result) {
    return localtime_s(result, t) ? NULL : result;
}

#endif
#endif

#endif
