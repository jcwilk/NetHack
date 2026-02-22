# NetHack – Agent Guide

NetHack 3.6.7 in playground mode (runs from source tree; data in `dat/`). This guide tells agents how to run the game and what to do when things go wrong.

## Scripts

| Script | Purpose |
|--------|---------|
| `start.sh` | Human play. Builds automatically if needed. |
| `agent_start.sh` | Start the game in a tmux session. Blocks until ready. |
| `agent_look.sh` | Read the current screen (exactly what a player sees). |
| `agent_keypress.sh` | Send keys (supports meta/ctrl combos, arrows, etc.). |
| `agent_stop.sh` | Kill the game session. |
| `agent_reset_save_data.sh` | Delete saves/locks/bones (requires `-f`). |

All agent scripts support `-h` for usage help.

## Agent workflow

1. **Clean slate** (if starting fresh or recovering from a crash):
   ```bash
   ./agent_stop.sh
   ./agent_reset_save_data.sh -f
   ```

2. **Start and interact**:
   ```bash
   ./agent_start.sh                          # blocks until game is ready
   ./agent_look.sh                           # see the screen
   ./agent_keypress.sh y                     # send a key
   ./agent_look.sh                           # see what changed
   ./agent_keypress.sh '#' p r a y enter     # extended command: #pray
   ```

3. **Stop** when done or stuck:
   ```bash
   ./agent_stop.sh
   ```

## How it works

The game runs inside a **tmux session** (`nethack_agent`), which is a real terminal emulator. This means all cursor movement, screen clearing, and redraws are handled properly — `agent_look.sh` returns exactly what a human player would see on an 80×24 terminal.

- `agent_look.sh` reads the screen via `tmux capture-pane` (always accurate)
- `agent_keypress.sh` sends keys via `tmux send-keys` (supports all key types)
- A background process also dumps the screen to `agent_screen_dump.txt` every second for human observers — agents should **not** read this file; always use `agent_look.sh`

## Common issues

- **"Cannot open file perm"**: Create `dat/perm`, `dat/record`, `dat/logfile`, `dat/xlogfile` (e.g. `touch dat/perm dat/record dat/logfile dat/xlogfile`).
- **"Too many hacks running now"**: Stale locks from a crashed run. `./agent_reset_save_data.sh -f` clears them.
- **"Terminal must backspace"** / **"You must play from a terminal"**: Use `agent_start.sh` (provides a PTY via tmux). Don't run the binary directly.
- **Game already running**: Run `./agent_stop.sh` first, then try again.

## Dev loop

Edit source → `./agent_start.sh` (builds automatically, blocks until game ready) → `./agent_look.sh` → `./agent_keypress.sh` → iterate. Use `./agent_stop.sh` if needed.
