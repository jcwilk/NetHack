#!/bin/sh
#
# Agent-friendly NetHack launcher - wraps start.sh and runs it through
# script(1) so output can be captured. No timeout; agent sends keypresses
# by writing to agent_keypress.txt. A loop pipes keypresses to script's stdin.
#
# Usage:
#   ./agent_start.sh &                    # Start in background
#   cat agent_screen_dump.txt             # Read current screen (updated ~1s)
#   echo -n ' ' > agent_keypress.txt      # Send space key
#   wait                                  # Wait for game to exit
#
# Files: agent_screen_dump.txt (read), agent_keypress.txt (write), agent_pidfile

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

LOGFILE="${AGENT_LOGFILE:-agent_session.log}"
SCREEN_DUMP="${AGENT_SCREEN_DUMP:-agent_screen_dump.txt}"
KEYPRESS_FILE="${AGENT_KEYPRESS:-agent_keypress.txt}"
PIDFILE="${AGENT_PIDFILE:-agent_pidfile}"

: > "$SCREEN_DUMP"

# Loop feeds keypresses to script's stdin; script forwards to game's PTY.
# Loop also updates screen_dump from logfile. Pipeline runs until game exits.
(
    while true; do
        [ -f "$LOGFILE" ] && sed 's/\x1b\[[0-9;]*[a-zA-Z]//g;s/\x1b[=>]//g' "$LOGFILE" 2>/dev/null | col -b 2>/dev/null > "$SCREEN_DUMP"
        [ -f "$KEYPRESS_FILE" ] && cat "$KEYPRESS_FILE" && rm -f "$KEYPRESS_FILE"
        sleep 1
    done
) | script -q -f -m classic -c "TERM=xterm ./start.sh $*" -O "$LOGFILE" 2>/dev/null &
SCRIPTPID=$!
echo $SCRIPTPID > "$PIDFILE"

# Wait for game to exit
wait $SCRIPTPID 2>/dev/null || true

# Final dump
echo "--- Game output ---"
cat "$SCREEN_DUMP"
echo "--- End of output ---"

rm -f "$PIDFILE"
