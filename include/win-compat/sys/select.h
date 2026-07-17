/*
 * Empty sys/select.h stub for MinGW-w64 builds on Windows.
 * The only user of select()/fd_set in this project (the POSIX branch
 * of run_command_get_outputs() in ioutils.c) is compiled out entirely
 * on Windows in favor of a CreateProcess()-based implementation, so
 * this file just needs to exist to satisfy the #include.
 */
#ifndef ASTROMETRY_WIN_COMPAT_SYS_SELECT_H
#define ASTROMETRY_WIN_COMPAT_SYS_SELECT_H
#endif
