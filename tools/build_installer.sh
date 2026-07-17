#!/bin/bash
#
# Builds the Windows astrometry binaries with MinGW and packages them into
# a Windows installer (installer/astrometry.iss) using Inno Setup.
#
# Run this from a bash shell that has the usual POSIX build tools on PATH
# (awk, install, etc.) - e.g. Git for Windows' bash, or MSYS2.
#
# Usage:
#   ./tools/build_installer.sh [make-args...]
#
# Environment variables:
#   QT_VER      Qt version whose bundled mingw toolchain to use (default: 5.15.2)
#   MINGW_VER   mingw version suffix used by that Qt install    (default: 81)
#   ISCC        full path to ISCC.exe (Inno Setup 6 compiler), if it isn't
#               already on PATH and isn't found in one of the usual
#               "Program Files" locations.
#
# Any extra arguments are passed straight through to `make` (e.g. "clean").

set -e

QT_VER="${QT_VER:-5.15.2}"
MINGW_VER="${MINGW_VER:-81}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Make sure the Qt-bundled mingw toolchain (gcc/ar/mingw32-make) is on PATH.
MINGW_BIN="/c/Qt/${QT_VER}/mingw${MINGW_VER}_64/bin"
MINGW_TOOLS_BIN="/c/Qt/Tools/mingw${MINGW_VER}0_64/bin"
if [ -d "$MINGW_BIN" ]; then
    PATH="$MINGW_BIN:$MINGW_TOOLS_BIN:$PATH"
fi

if ! command -v gcc >/dev/null 2>&1; then
    echo "error: no mingw gcc found on PATH." >&2
    echo "       Set QT_VER/MINGW_VER to match your Qt install, or add your" >&2
    echo "       mingw bin directory to PATH yourself." >&2
    exit 1
fi

MAKE=mingw32-make
if ! command -v "$MAKE" >/dev/null 2>&1; then
    if command -v make >/dev/null 2>&1; then
        MAKE=make
    else
        echo "error: neither mingw32-make nor make found on PATH." >&2
        exit 1
    fi
fi

echo "==> Building astrometry binaries with $(command -v gcc)"
cd "$REPO_ROOT"
"$MAKE" "$@"

echo "==> Locating Inno Setup compiler (ISCC.exe)"
if [ -z "$ISCC" ]; then
    for candidate in \
        "/c/Program Files (x86)/Inno Setup 6/ISCC.exe" \
        "/c/Program Files/Inno Setup 6/ISCC.exe"; do
        if [ -x "$candidate" ]; then
            ISCC="$candidate"
            break
        fi
    done
fi
if [ -z "$ISCC" ] && command -v iscc >/dev/null 2>&1; then
    ISCC="$(command -v iscc)"
fi
if [ -z "$ISCC" ]; then
    echo "error: couldn't find ISCC.exe (Inno Setup 6)." >&2
    echo "       Install it from https://jrsoftware.org/isinfo.php, or set" >&2
    echo "       ISCC=/path/to/ISCC.exe and re-run this script." >&2
    exit 1
fi

echo "==> Building installer with $ISCC"
"$ISCC" "$REPO_ROOT/installer/astrometry.iss"

echo "==> Done. Installer written to $REPO_ROOT/dist/"
