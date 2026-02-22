# NetHack – Agent Guide

NetHack 3.6.7 in playground mode (runs from source tree; data in `dat/`). This guide tells agents how to run the game and what to do when things go wrong.

## Scripts

| Script | Use when |
|--------|----------|
| `start.sh` | Human play. Builds automatically if needed. |
| `agent_start.sh` | Agent play. Blocks until game ready; captures screen, accepts keypresses via file. |
| `agent_stop.sh` | Game stuck or no clean exit. Kills the agent session. |
| `agent_reset.sh` | Fresh start or "Too many hacks running now". Clears saves/locks. |

## Agent workflow

1. **Clean slate** (if starting fresh or recovering from a crash):
   ```bash
   ./agent_stop.sh
   ./agent_reset.sh
   ```

2. **Start and interact**:
   ```bash
   ./agent_start.sh
   # Blocks until game is ready (detects copyright screen); then poll and send keys
   cat agent_screen_dump.txt
   echo -n 'y' > agent_keypress.txt   # e.g. accept random character
   # Repeat: read dump, send keys as needed
   wait
   ```

3. **Stop** when stuck:
   ```bash
   ./agent_stop.sh
   ```

## Files the agent uses

- **Read**: `agent_screen_dump.txt` – current screen (updated ~1s)
- **Write**: `agent_keypress.txt` – keypresses to send
- `agent_pidfile` – used by agent_stop; don't touch

## Common issues

- **"Cannot open file perm"**: Create `dat/perm`, `dat/record`, `dat/logfile`, `dat/xlogfile` (e.g. `touch dat/perm dat/record dat/logfile dat/xlogfile`).
- **"Too many hacks running now"**: Stale locks from a crashed run. `./agent_reset.sh` clears them.
- **"Terminal must backspace"** / **"You must play from a terminal"**: Use `agent_start.sh` (provides a PTY). Don't run the binary directly.

## Dev loop

Edit source → `./agent_start.sh` (builds automatically, blocks until game ready) → read dump, send keys, iterate. Use `./agent_stop.sh` if needed.
