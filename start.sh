#!/bin/sh
#
# NetHack start script - run from build directory without installing.
# Ensures prerequisites exist, builds if needed, then runs the game.
# All arguments are passed through to the nethack executable.
#
# See RUN_LOCALLY.md for details on the playground configuration.

set -e

# Run from the directory containing this script (project root)
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# Ensure required directories and files exist
mkdir -p dat/save
# touch dat/perm dat/record dat/logfile dat/xlogfile  # uncomment to fix "Cannot open file perm"
if [ ! -f dat/sysconf ]; then
    cp -n sys/unix/sysconf dat/sysconf 2>/dev/null || true
fi

# Build (make will skip if already up to date)
# If Makefile is missing (fresh checkout), configure first
if [ ! -f Makefile ]; then
    (cd sys/unix && sh setup.sh hints/linux-playground)
fi
make all

# Run nethack, passing through all arguments
exec ./src/nethack "$@"
