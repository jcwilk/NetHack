#!/bin/sh
#
# Stop the game started by agent_start.sh. Kills the process via the pidfile.
# Use when there's no clear way to exit via keypresses (e.g. stuck in a menu).
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
    kill "$PID" 2>/dev/null
    echo "Stopped process $PID"
else
    echo "Process $PID not running"
fi
rm -f "$PIDFILE"
