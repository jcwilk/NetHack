#!/bin/sh
#
# Agent-friendly NetHack launcher. Wraps start.sh (which builds automatically)
# and runs it through script(1) so output can be captured.
#
# Usage:
#   ./agent_start.sh                      # Blocks until game is ready, then returns
#   cat agent_screen_dump.txt             # Read current screen (updated ~1s)
#   echo -n ' ' > agent_keypress.txt      # Send space key
#   wait                                  # Wait for game to exit (optional)
#
# How it works: Backgrounds a daemon that runs the game. Parent polls
# agent_screen_dump.txt for "NetHack, Copyright 1985" and returns when found
# (game ready). Daemon: loop feeds keypresses to script's stdin; raw capture
# processed into agent_screen_dump.txt ~1s. Single instance: flock on pidfile.
#
# Files: agent_screen_dump.txt (read), agent_keypress.txt (write), agent_pidfile
# Env (optional): AGENT_SCREEN_DUMP, AGENT_KEYPRESS, AGENT_PIDFILE

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

SCREEN_DUMP="${AGENT_SCREEN_DUMP:-agent_screen_dump.txt}"
KEYPRESS_FILE="${AGENT_KEYPRESS:-agent_keypress.txt}"
PIDFILE="${AGENT_PIDFILE:-agent_pidfile}"

# Background ourselves; parent polls until game is ready
if [ "$1" != "__agent_daemon__" ]; then
    "$0" __agent_daemon__ "$@" &
    daemon_pid=$!
    while true; do
        if grep -q "NetHack, Copyright 1985" "$SCREEN_DUMP" 2>/dev/null; then
            exit 0
        fi
        if ! kill -0 $daemon_pid 2>/dev/null; then
            exit 1
        fi
        sleep 0.5
    done
fi
shift

# Detect orphaned agent processes from a previous run (e.g. main was SIGKILL'd, subshell survived).
# Only flag processes whose parent is init (PID 1) - those are true orphans. This avoids
# false positives from the invoking shell (which has "agent_start" in its cmdline).
others=$(pgrep -f "agent_start\.sh" 2>/dev/null | while read pid; do
    [ "$pid" = "$$" ] && continue
    ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    [ "$ppid" = "1" ] && echo "$pid"
done)
if [ -n "$others" ]; then
    echo "Other agent processes detected (orphaned from previous run): $others. Use ./agent_stop.sh to clean up, then try again." >&2
    exit 1
fi

# Acquire exclusive lock on pidfile; refuse to start if another agent holds it.
# Use append mode so we don't truncate the file (and wipe the PID) before checking.
exec 9>>"$PIDFILE"
if ! flock -n -x 9 2>/dev/null; then
    echo "Agent already running (PID $(cat "$PIDFILE" 2>/dev/null)). Use ./agent_stop.sh first." >&2
    exit 1
fi
# Stale pidfile: we got the lock (previous holder is dead) but a process from that
# run may still be running (orphaned). Abort so the agent can decide what to do.
old_pid=$(cat "$PIDFILE" 2>/dev/null)
if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
    echo "Stale pidfile: process $old_pid still running (orphaned from previous run). Use ./agent_stop.sh to clean up, then try again." >&2
    exit 1
fi
# We hold the lock; truncate and we'll write our PID after starting the script
: > "$PIDFILE"

echo 'starting agent script...' > "$SCREEN_DUMP"

# Temp file for raw capture; script(1) requires a file to write to
RAWCAPTURE="$(mktemp -t agent_nethack.XXXXXX)"
# On exit, kill script and its children (nethack) so we don't leave orphans when e.g. terminal closes
trap '[ -n "$SCRIPTPID" ] && pkill -TERM -P $SCRIPTPID 2>/dev/null; [ -n "$SCRIPTPID" ] && kill -TERM $SCRIPTPID 2>/dev/null; [ -n "$RAWCAPTURE" ] && rm -f "$RAWCAPTURE"; [ -n "$SCRIPTPID" ] && rm -f "$PIDFILE"' EXIT

# Process raw capture into readable screen: strip ANSI, fix CR->LF (curses uses
# carriage returns between lines). Take from last clear [2J onward (current frame only).
esc="$(printf '\033')"

# Loop feeds keypresses to script's stdin; script forwards to game's PTY.
# Loop also processes raw capture into screen_dump. Pipeline runs until game exits.
(
    while true; do
        if [ -f "$RAWCAPTURE" ]; then
            last=$(grep -abo "${esc}\\[2J" "$RAWCAPTURE" 2>/dev/null | tail -1 | cut -d: -f1)
            if [ -n "$last" ]; then
                out=$(tail -c "+$((last + 4))" "$RAWCAPTURE" 2>/dev/null | \
                sed "s/${esc}\\[[^a-zA-Z]*[a-zA-Z]//g;s/${esc}[=>]//g" | \
                tr '\r' '\n' | tail -24)
                [ -n "$out" ] && printf '%s' "$out" > "$SCREEN_DUMP"
            fi
        fi
        [ -f "$KEYPRESS_FILE" ] && cat "$KEYPRESS_FILE" && rm -f "$KEYPRESS_FILE"
        sleep 1
    done
) | script -q -f -m classic -c "TERM=xterm ./start.sh $@" -O "$RAWCAPTURE" 2>/dev/null &
SCRIPTPID=$!
echo $SCRIPTPID >&9

# Wait for game to exit
wait $SCRIPTPID 2>/dev/null || true

# Final dump
echo "--- Game output ---"
cat "$SCREEN_DUMP"
echo "--- End of output ---"

