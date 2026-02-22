#!/bin/sh
#
# Stop the game started by agent_start.sh. Kills the process via the pidfile,
# and also runs pkill on any orphaned agent_start processes. Use when there's
# no clear way to exit via keypresses (e.g. stuck in a menu).
#
# Usage: ./agent_stop.sh

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PIDFILE="${AGENT_PIDFILE:-agent_pidfile}"

if [ ! -f "$PIDFILE" ]; then
    echo "No pidfile found. Game may not be running."
    exit 0
fi

PID=$(cat "$PIDFILE" 2>/dev/null)
if [ -z "$PID" ]; then
    echo "Pidfile empty."
    rm -f "$PIDFILE"
    exit 0
fi

if kill -0 "$PID" 2>/dev/null; then
    pkill -TERM -P "$PID" 2>/dev/null
    kill -TERM "$PID" 2>/dev/null
    echo "Stopped process $PID"
else
    echo "Process $PID not running"
fi
# Also kill any orphaned agent_start processes (e.g. subshell that survived when main was SIGKILL'd)
pkill -TERM -f "agent_start\.sh" 2>/dev/null && echo "Stopped orphaned agent processes" || true
rm -f "$PIDFILE"
