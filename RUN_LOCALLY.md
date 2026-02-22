# Running NetHack from the Build Directory

This document describes the playground/development configuration that allows NetHack to run directly from the source tree without installing to a separate directory. This is useful for development and for keeping the repo clean for git operations.

## What Was Changed

1. **`start.sh`**: A convenience script that ensures `dat/save` and `dat/sysconf` exist, runs `make all` (or configures with `setup.sh` on fresh checkout), then runs `./src/nethack` with all arguments passed through. Use this for a zero-friction run experience.

2. **New hints file**: `sys/unix/hints/linux-playground`
   - Configures the build to use the source tree as the data directory
   - Sets `HACKDIR` to the project's `dat/` directory so the game reads data from `dat/` and writes saves there
   - No separate install directory (`~/nh/install`) is used

3. **Build system**: The project was reconfigured with `setup.sh hints/linux-playground`, which regenerates the top-level `Makefile` and other Makefiles. The generated `Makefile` is in `.gitignore` (standard NetHack behavior).

4. **`.gitignore`**: Added entries for playground runtime files so they don't clutter git status:
   - `dat/save/`
   - `dat/perm`
   - `dat/record`
   - `dat/logfile`
   - `dat/xlogfile`
   - `dat/bones*`
   - `dat/sysconf`

## How to Run Locally

**Recommended:** Use the `start.sh` script. It ensures prerequisites exist, builds if needed, and runs the game. All arguments are passed through to the executable.

```bash
./start.sh
```

With arguments (all are passed through to nethack):

```bash
./start.sh --version          # version info
./start.sh -s                 # score list
./start.sh -u playername       # specify player name
./start.sh -p wizard -r elf   # role and race
./start.sh -D                 # wizard mode
# ... any other nethack options (see man nethack or doc/nethack.6)
```

**Alternative:** Run the binary directly (after `make all`):

```bash
./src/nethack
```

## Switching Back to Normal Install Layout

To restore the standard configuration (install to `~/nh/install/games/lib/nethackdir`):

1. Reconfigure with the standard Linux hints:
   ```bash
   cd sys/unix && sh setup.sh hints/linux && cd ../..
   ```

2. Clean and rebuild:
   ```bash
   make spotless && make all
   ```

3. Install:
   ```bash
   make install
   ```

4. Run:
   ```bash
   ~/nh/install/games/nethack
   ```

## For Future Agents

- The project is currently configured for **playground mode** (run from build dir). The active hints file is `sys/unix/hints/linux-playground`.
- **`./start.sh`** is the recommended way to run: it handles setup, build, and argument passthrough. Do not parse or filter arguments—pass them all through to the executable.
- To check the current configuration, look at the top-level `Makefile` (if present) for `HACKDIR` and `PREFIX` values, or run `./src/nethack --version` and note where it looks for data.
- The `Makefile` is generated; do not edit it directly. Changes to build configuration go in `sys/unix/hints/` and are applied via `sh setup.sh hints/<name>`.
