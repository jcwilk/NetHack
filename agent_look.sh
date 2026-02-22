#!/bin/sh
#
# Capture the current game screen from the tmux session.
# Outputs to stdout (for agent use) and writes to agent_screen_dump.txt
# (for human viewing).

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

SCREEN_DUMP="${AGENT_SCREEN_DUMP:-agent_screen_dump.txt}"
TMUX_SESSION="nethack_agent"

if [ "$1" = "-h" ]; then
    cat <<'EOF'
Usage: ./agent_look.sh

Capture the current NetHack screen. Output goes to stdout and
is also written to agent_screen_dump.txt.

The screen is read directly from the tmux session, so it shows
exactly what a human player would see (80x24 terminal).
EOF
    exit 0
fi

if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "No game running. Start one with ./agent_start.sh" >&2
    exit 1
fi

tmux capture-pane -t "$TMUX_SESSION" -p | tee "$SCREEN_DUMP"
