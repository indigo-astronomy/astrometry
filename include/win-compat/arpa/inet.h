/*
 * Minimal arpa/inet.h replacement for MinGW-w64 builds on Windows.
 * Only provides the network byte-order conversion functions that
 * astrometry.net's ioutils.c uses (no real sockets are compiled in
 * this project's CFITSIO/astrometry.net configuration).
 */
#ifndef ASTROMETRY_WIN_COMPAT_ARPA_INET_H
#define ASTROMETRY_WIN_COMPAT_ARPA_INET_H

#ifdef _WIN32

#include <stdint.h>

static __inline uint32_t htonl(uint32_t x) {
    return ((x & 0x000000ffu) << 24) |
           ((x & 0x0000ff00u) << 8)  |
           ((x & 0x00ff0000u) >> 8)  |
           ((x & 0xff000000u) >> 24);
}

static __inline uint32_t ntohl(uint32_t x) {
    return htonl(x);
}

static __inline uint16_t htons(uint16_t x) {
    return (uint16_t)(((x & 0x00ffu) << 8) | ((x & 0xff00u) >> 8));
}

static __inline uint16_t ntohs(uint16_t x) {
    return htons(x);
}

#endif /* _WIN32 */

#endif
