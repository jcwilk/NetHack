#!/bin/sh
#
# Send one or more keypresses to the running NetHack game via tmux.

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

TMUX_SESSION="nethack_agent"

show_help() {
    cat <<'EOF'
Usage: ./agent_keypress.sh KEY [KEY ...]

Send one or more keys to the NetHack game. Each argument is one keypress.
After sending, prints the updated screen (via agent_look.sh).

KEY formats:
  Single char:   a  A  @  /  ?  .  ,  <  >  :  ;
  Named:         enter  escape  space  tab  backspace
  Arrow:         up  down  left  right
  Meta combo:    meta-x   (Alt+key; for extended commands like meta-o)
  Ctrl combo:    ctrl-a   (Ctrl+key; e.g. ctrl-p for previous messages)

Examples:
  ./agent_keypress.sh y                       # answer yes
  ./agent_keypress.sh .                       # wait one turn
  ./agent_keypress.sh meta-o                  # extended: adjust options
  ./agent_keypress.sh ctrl-p                  # show previous messages
  ./agent_keypress.sh '#' p r a y enter       # extended command: #pray
  ./agent_keypress.sh escape                  # cancel

Note: quote shell-special characters: '#'  '>'  '<'  '?'  '*'  '!'  ';'
EOF
}

if [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

if [ $# -eq 0 ]; then
    echo "Error: at least one KEY is required. Run with -h for help." >&2
    exit 1
fi

if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "Error: no game running. Start one with ./agent_start.sh" >&2
    exit 1
fi

send_key() {
    _key="$1"
    _lower=$(printf '%s' "$_key" | tr 'A-Z' 'a-z')

    case "$_lower" in
        enter)      tmux send-keys -t "$TMUX_SESSION" Enter ;;
        escape|esc) tmux send-keys -t "$TMUX_SESSION" Escape ;;
        space)      tmux send-keys -t "$TMUX_SESSION" Space ;;
        tab)        tmux send-keys -t "$TMUX_SESSION" Tab ;;
        backspace)  tmux send-keys -t "$TMUX_SESSION" BSpace ;;
        up)         tmux send-keys -t "$TMUX_SESSION" Up ;;
        down)       tmux send-keys -t "$TMUX_SESSION" Down ;;
        left)       tmux send-keys -t "$TMUX_SESSION" Left ;;
        right)      tmux send-keys -t "$TMUX_SESSION" Right ;;
        meta-?)
            _ch="${_key#*-}"
            if [ "${#_ch}" -ne 1 ]; then
                echo "Error: meta- requires exactly one character (e.g. meta-x), got '$_key'." >&2
                return 1
            fi
            tmux send-keys -t "$TMUX_SESSION" M-"$_ch"
            ;;
        ctrl-?)
            _ch="${_key#*-}"
            if [ "${#_ch}" -ne 1 ]; then
                echo "Error: ctrl- requires exactly one character (e.g. ctrl-a), got '$_key'." >&2
                return 1
            fi
            tmux send-keys -t "$TMUX_SESSION" C-"$_ch"
            ;;
        ?)
            tmux send-keys -t "$TMUX_SESSION" -l "$_key"
            ;;
        *)
            echo "Error: unrecognized key '$_key'." >&2
            echo "  Single characters, named keys (enter/escape/space/tab/backspace)," >&2
            echo "  arrows (up/down/left/right), meta-X, and ctrl-X are supported." >&2
            echo "  Run with -h for full help." >&2
            return 1
            ;;
    esac
}

for _k in "$@"; do
    send_key "$_k" || exit 1
done

sleep 0.1
exec "$ROOT/agent_look.sh"
