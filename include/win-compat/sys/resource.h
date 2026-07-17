/*
 * Minimal sys/resource.h replacement for MinGW-w64 builds on Windows.
 * Only implements the small subset (getrusage/RUSAGE_SELF) used by
 * get_cpu_usage() in astrometry.net's ioutils.c.
 */
#ifndef ASTROMETRY_WIN_COMPAT_SYS_RESOURCE_H
#define ASTROMETRY_WIN_COMPAT_SYS_RESOURCE_H

#ifdef _WIN32

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOGDI
#define NOGDI
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <psapi.h>

#define RUSAGE_SELF 0

struct rusage {
    struct {
        long tv_sec;
        long tv_usec;
    } ru_utime, ru_stime;
    long ru_maxrss; /* peak working set size, in KB (to match Linux's units) */
};

static __inline int getrusage(int who, struct rusage* r) {
    FILETIME creation, exit_time, kernel, user;
    ULARGE_INTEGER uk, uu;
    PROCESS_MEMORY_COUNTERS pmc;
    (void)who;

    if (!GetProcessTimes(GetCurrentProcess(), &creation, &exit_time, &kernel, &user))
        return -1;

    uk.LowPart = kernel.dwLowDateTime;
    uk.HighPart = kernel.dwHighDateTime;
    uu.LowPart = user.dwLowDateTime;
    uu.HighPart = user.dwHighDateTime;

    /* FILETIME units are 100ns. */
    r->ru_stime.tv_sec  = (long)(uk.QuadPart / 10000000ULL);
    r->ru_stime.tv_usec = (long)((uk.QuadPart % 10000000ULL) / 10);
    r->ru_utime.tv_sec  = (long)(uu.QuadPart / 10000000ULL);
    r->ru_utime.tv_usec = (long)((uu.QuadPart % 10000000ULL) / 10);

    r->ru_maxrss = 0;
    if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc)))
        r->ru_maxrss = (long)(pmc.PeakWorkingSetSize / 1024);

    return 0;
}

#endif /* _WIN32 */

#endif
