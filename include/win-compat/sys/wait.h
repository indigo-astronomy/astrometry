/*
 * Minimal sys/wait.h replacement for MinGW-w64 builds on Windows.
 *
 * Windows' system() (and _cwait()) return the child process's raw exit
 * code directly, not a POSIX wait-status encoding, and there is no
 * signal-based termination status to decode.  These macros are defined
 * to match that convention so existing call sites (e.g. run_command()
 * in solve-field.c) keep working unmodified.
 */
#ifndef ASTROMETRY_WIN_COMPAT_SYS_WAIT_H
#define ASTROMETRY_WIN_COMPAT_SYS_WAIT_H

#ifdef _WIN32

#define WIFEXITED(status)   (1)
#define WEXITSTATUS(status) (status)
#define WIFSIGNALED(status) (0)
#define WTERMSIG(status)    (0)

#endif /* _WIN32 */

#endif
