/*
 * Empty netinet/in.h stub for MinGW-w64 builds on Windows.
 * The only thing astrometry.net's ioutils.c needs from this header
 * (htonl/ntohl/etc.) is actually provided by our arpa/inet.h shim; this
 * file just satisfies the #include so compilation succeeds, since no
 * real BSD sockets code is compiled in this project's configuration.
 */
#ifndef ASTROMETRY_WIN_COMPAT_NETINET_IN_H
#define ASTROMETRY_WIN_COMPAT_NETINET_IN_H
#endif
