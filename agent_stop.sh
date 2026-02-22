#!/bin/sh
#
# Stop the NetHack game session started by agent_start.sh.

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PIDFILE="${AGENT_PIDFILE:-agent_pidfile}"
TMUX_SESSION="nethack_agent"

if [ "$1" = "-h" ]; then
    cat <<'EOF'
Usage: ./agent_stop.sh

Stop the running NetHack game and clean up. Kills the tmux session
and the background screen dumper. Safe to run if nothing is running.
EOF
    exit 0
fi

stopped=false

if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    tmux kill-session -t "$TMUX_SESSION"
    echo "Game session stopped."
    stopped=true
fi

if [ -f "$PIDFILE" ]; then
    pid=$(cat "$PIDFILE" 2>/dev/null)
    [ -n "$pid" ] && kill "$pid" 2>/dev/null
    rm -f "$PIDFILE"
fi

if [ "$stopped" = false ]; then
    echo "No game session running."
fi
