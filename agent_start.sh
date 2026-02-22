#!/bin/sh
#
# Start NetHack in a tmux session for agent interaction.
# Blocks until the game is ready (copyright screen detected).
#
# The game runs inside tmux, which acts as a real terminal emulator --
# all cursor movement, screen clears, and redraws are handled properly.
# Use agent_look.sh to read the screen, agent_keypress.sh to send keys.
#
# Usage:
#   ./agent_start.sh          # blocks until game is ready
#   ./agent_look.sh           # read current screen
#   ./agent_keypress.sh y     # send a key
#   ./agent_stop.sh           # stop the game

if [ "$1" = "-h" ]; then
    cat <<'EOF'
Usage: ./agent_start.sh

Start NetHack in a tmux session. Blocks until the game is ready.
Use agent_look.sh to read the screen, agent_keypress.sh to send keys,
and agent_stop.sh to quit.
EOF
    exit 0
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

SCREEN_DUMP="${AGENT_SCREEN_DUMP:-agent_screen_dump.txt}"
PIDFILE="${AGENT_PIDFILE:-agent_pidfile}"
TMUX_SESSION="nethack_agent"

if ! command -v tmux >/dev/null 2>&1; then
    echo "Error: tmux is required but not installed." >&2
    exit 1
fi

if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "Game already running. Use ./agent_stop.sh first." >&2
    exit 1
fi

# Clean up stale background dumper from a previous run
if [ -f "$PIDFILE" ]; then
    old_pid=$(cat "$PIDFILE" 2>/dev/null)
    [ -n "$old_pid" ] && kill "$old_pid" 2>/dev/null
    rm -f "$PIDFILE"
fi

echo 'starting...' > "$SCREEN_DUMP"

# Start the game in a detached tmux session (80x24 standard terminal)
tmux new-session -d -s "$TMUX_SESSION" -x 80 -y 24 "TERM=xterm $ROOT/start.sh $*"

# Background: dump screen to file every second so humans can follow along.
# The agent reads directly from tmux via agent_look.sh; this is just for
# human observers watching agent_screen_dump.txt.
(
    while tmux has-session -t "$TMUX_SESSION" 2>/dev/null; do
        tmux capture-pane -t "$TMUX_SESSION" -p > "$SCREEN_DUMP.tmp" 2>/dev/null \
            && mv -f "$SCREEN_DUMP.tmp" "$SCREEN_DUMP"
        sleep 1
    done
    echo '--- game exited ---' > "$SCREEN_DUMP"
) &
echo $! > "$PIDFILE"

# Block until game is ready (detect copyright screen)
attempts=0
while true; do
    if tmux capture-pane -t "$TMUX_SESSION" -p 2>/dev/null | grep -q "NetHack, Copyright 1985"; then
        tmux capture-pane -t "$TMUX_SESSION" -p > "$SCREEN_DUMP" 2>/dev/null
        exit 0
    fi
    if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        echo "Game exited before becoming ready." >&2
        exit 1
    fi
    attempts=$((attempts + 1))
    if [ "$attempts" -gt 120 ]; then
        echo "Timed out waiting for game to start (60s)." >&2
        exit 1
    fi
    sleep 0.5
done
