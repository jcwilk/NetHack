#!/bin/sh
#
# Delete all saved game data: dat/*lock*, dat/save/*, dat/bones*. Use for a
# clean slate when starting fresh or when "Too many hacks running now" appears.
#
# Usage: ./agent_reset.sh
#
# Stop the agent first (./agent_stop.sh) if it is running.

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# Remove lock files (stale locks cause "Too many hacks running now")
rm -f dat/*lock* 2>/dev/null || true

# Remove save files
rm -rf dat/save/* 2>/dev/null || true

# Remove bones (corpses from dead players)
rm -f dat/bones* 2>/dev/null || true

echo "Saved game data cleared."
