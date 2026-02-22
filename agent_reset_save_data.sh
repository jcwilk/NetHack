#!/bin/sh
#
# Delete all NetHack saved game data (locks, saves, bones).

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if [ "$1" = "-h" ]; then
    cat <<'EOF'
Usage: ./agent_reset_save_data.sh -f

Delete all saved game data: lock files, saves, and bones.
The -f flag is REQUIRED to confirm deletion (safety check).

Stop the game first (./agent_stop.sh) if it is running.
EOF
    exit 0
fi

if [ "$1" != "-f" ]; then
    echo "This will permanently delete all saved game data (locks, saves, bones)." >&2
    echo "Run with -f to confirm: ./agent_reset_save_data.sh -f" >&2
    exit 1
fi

rm -f dat/*lock* 2>/dev/null || true
rm -rf dat/save/* 2>/dev/null || true
rm -f dat/bones* 2>/dev/null || true
echo "Saved game data cleared."
