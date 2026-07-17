/*
 * Minimal glob.h replacement for MinGW-w64 builds on Windows.
 *
 * Only supports simple filename-wildcard expansion (the '*'/'?'
 * patterns natively understood by Windows' FindFirstFile/FindNextFile),
 * which is all that astrometry-engine's "-i index-*.fits" style option
 * needs. Brace-expansion (GLOB_BRACE) and tilde-expansion (GLOB_TILDE)
 * are not implemented; engine-main.c already falls back to treating
 * those flags as no-ops when they aren't defined.
 */
#ifndef ASTROMETRY_WIN_COMPAT_GLOB_H
#define ASTROMETRY_WIN_COMPAT_GLOB_H

#ifdef _WIN32

#include <stdlib.h>
#include <string.h>
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

#define GLOB_NOSPACE  1
#define GLOB_ABORTED  2
#define GLOB_NOMATCH  3

typedef struct {
    size_t gl_pathc;
    char** gl_pathv;
} glob_t;

static __inline int glob(const char* pattern, int flags, void* errfunc, glob_t* pglob) {
    WIN32_FIND_DATAA fd;
    HANDLE h;
    char dir[MAX_PATH];
    const char* slash;
    size_t dirlen;
    size_t cap = 8;

    (void)flags;
    (void)errfunc;

    slash = strrchr(pattern, '/');
    if (!slash)
        slash = strrchr(pattern, '\\');
    dirlen = slash ? (size_t)(slash - pattern + 1) : 0;
    if (dirlen >= sizeof(dir))
        return GLOB_ABORTED;
    memcpy(dir, pattern, dirlen);
    dir[dirlen] = '\0';

    pglob->gl_pathc = 0;
    pglob->gl_pathv = (char**)malloc(cap * sizeof(char*));
    if (!pglob->gl_pathv)
        return GLOB_NOSPACE;

    h = FindFirstFileA(pattern, &fd);
    if (h == INVALID_HANDLE_VALUE) {
        free(pglob->gl_pathv);
        pglob->gl_pathv = NULL;
        return GLOB_NOMATCH;
    }
    do {
        char* full;
        size_t len;
        if (!strcmp(fd.cFileName, ".") || !strcmp(fd.cFileName, ".."))
            continue;
        if (pglob->gl_pathc + 1 >= cap) {
            cap *= 2;
            pglob->gl_pathv = (char**)realloc(pglob->gl_pathv, cap * sizeof(char*));
        }
        len = dirlen + strlen(fd.cFileName);
        full = (char*)malloc(len + 1);
        memcpy(full, dir, dirlen);
        strcpy(full + dirlen, fd.cFileName);
        pglob->gl_pathv[pglob->gl_pathc++] = full;
    } while (FindNextFileA(h, &fd));
    FindClose(h);
    pglob->gl_pathv[pglob->gl_pathc] = NULL;

    if (pglob->gl_pathc == 0) {
        free(pglob->gl_pathv);
        pglob->gl_pathv = NULL;
        return GLOB_NOMATCH;
    }
    return 0;
}

static __inline void globfree(glob_t* pglob) {
    size_t i;
    if (!pglob || !pglob->gl_pathv)
        return;
    for (i = 0; i < pglob->gl_pathc; i++)
        free(pglob->gl_pathv[i]);
    free(pglob->gl_pathv);
    pglob->gl_pathv = NULL;
    pglob->gl_pathc = 0;
}

#endif /* _WIN32 */

#endif
