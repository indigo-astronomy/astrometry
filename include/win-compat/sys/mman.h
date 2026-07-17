/*
 * Minimal sys/mman.h replacement for MinGW-w64 builds on Windows.
 * Only the subset of mmap()/munmap() semantics used by astrometry.net
 * and cfitsio is implemented (PROT_READ/PROT_WRITE, MAP_SHARED/MAP_PRIVATE).
 */
#ifndef ASTROMETRY_WIN_COMPAT_SYS_MMAN_H
#define ASTROMETRY_WIN_COMPAT_SYS_MMAN_H

#ifdef _WIN32

#include <errno.h>
#include <io.h>
#include <stdio.h>
#include <sys/types.h>
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOGDI
#define NOGDI  /* avoid wingdi.h's ERROR macro clashing with astrometry.net's ERROR() */
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#define PROT_READ   0x1
#define PROT_WRITE  0x2
#define MAP_SHARED  0x01
#define MAP_PRIVATE 0x02
#define MAP_FAILED  ((void*)-1)

/*
 * POSIX mmap() requires the offset argument to be a multiple of the
 * page size.  Windows' MapViewOfFile() requires the offset to be a
 * multiple of the system's memory allocation granularity instead,
 * which is typically 64KB (larger than the 4KB page size).  The
 * astrometry.net code always page-aligns offsets via getpagesize()
 * before calling mmap() (see get_mmap_size() in ioutils.c), so making
 * getpagesize() return the true allocation granularity here keeps
 * that existing alignment logic correct on Windows too.
 */
static __inline int getpagesize(void) {
    static int pagesize = 0;
    if (!pagesize) {
        SYSTEM_INFO si;
        GetSystemInfo(&si);
        pagesize = (int)si.dwAllocationGranularity;
    }
    return pagesize;
}

static __inline void* mmap(void* addr, size_t length, int prot, int flags, int fd, off_t offset) {
    HANDLE fh;
    HANDLE mh;
    DWORD protect;
    DWORD access;
    LARGE_INTEGER off;
    void* ptr;
    (void)addr;

    fh = (HANDLE)_get_osfhandle(fd);
    if (fh == INVALID_HANDLE_VALUE) {
        errno = EBADF;
        return MAP_FAILED;
    }

    if (flags & MAP_PRIVATE) {
        protect = (prot & PROT_WRITE) ? PAGE_WRITECOPY : PAGE_READONLY;
        access  = (prot & PROT_WRITE) ? FILE_MAP_COPY  : FILE_MAP_READ;
    } else {
        protect = (prot & PROT_WRITE) ? PAGE_READWRITE : PAGE_READONLY;
        access  = (prot & PROT_WRITE) ? FILE_MAP_WRITE : FILE_MAP_READ;
    }

    mh = CreateFileMappingA(fh, NULL, protect, 0, 0, NULL);
    if (!mh) {
        errno = EINVAL;
        return MAP_FAILED;
    }

    off.QuadPart = offset;
    ptr = MapViewOfFile(mh, access, off.HighPart, off.LowPart, length);
    /* The mapping object handle isn't needed once the view is mapped;
       Windows keeps the underlying mapping alive until the view is
       unmapped with UnmapViewOfFile(). */
    CloseHandle(mh);
    if (!ptr) {
        errno = EINVAL;
        return MAP_FAILED;
    }
    return ptr;
}

static __inline int munmap(void* addr, size_t length) {
    (void)length;
    return UnmapViewOfFile(addr) ? 0 : -1;
}

static __inline int msync(void* addr, size_t length, int flags) {
    (void)flags;
    return FlushViewOfFile(addr, length) ? 0 : -1;
}

#endif /* _WIN32 */

#endif
