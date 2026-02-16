#!/usr/bin/env bash
# Session browser: current project or global

# Colors (Anthropic orange theme)
O='\033[38;5;208m'
W='\033[38;5;214m'
G='\033[32m'
R='\033[31m'
D='\033[90m'
B='\033[1m'
N='\033[0m'

# Cross-platform stat: formatted modification time
stat_fmt_time() {
    stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$1" 2>/dev/null \
        || stat -c "%y" "$1" 2>/dev/null | cut -d'.' -f1 | cut -d' ' -f1-2
}

# Parse flags
GLOBAL=false
INCLUDE_SUBAGENTS=false
PURGE=false

for arg in "$@"; do
    case "$arg" in
        -a|--all|--global) GLOBAL=true ;;
        --include-subagents|--subagents) INCLUDE_SUBAGENTS=true ;;
        --purge) PURGE=true ;;
    esac
done

# Determine search directory
if $GLOBAL; then
    DIR="$HOME/.claude/projects"
    HEADER="All Sessions"
else
    PROJECT=$(cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" && pwd -P)
    ENCODED=$(echo "$PROJECT" | sed 's|/|-|g')
    DIR="$HOME/.claude/projects/$ENCODED"
    HEADER="Sessions: $(basename "$PROJECT")"

    if [[ ! -d "$DIR" ]]; then
        echo -e "${O}No sessions for:${N} $PROJECT"
        echo -e "${D}Tip: Use 'claude-sessions -a' to see all sessions${N}"
        exit 1
    fi
fi

# --- Purge mode: delete empty sessions ---
if $PURGE; then
    DEPTH_OPTS=()
    if $INCLUDE_SUBAGENTS; then
        DEPTH_OPTS=()
    elif $GLOBAL; then
        DEPTH_OPTS=(-maxdepth 2)
    else
        DEPTH_OPTS=(-maxdepth 1)
    fi

    count=0
    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        MSGS=$(grep -c '"role":' "$f" 2>/dev/null || echo 0)
        if [[ "$MSGS" -eq 0 ]]; then
            rm "$f"
            ((count++))
        fi
    done < <(find "$DIR" "${DEPTH_OPTS[@]}" -name "*.jsonl" -type f 2>/dev/null)

    if [[ $count -gt 0 ]]; then
        echo -e "${G}${B}Purged ${count} empty session(s)${N}"
    else
        echo -e "${D}No empty sessions found${N}"
    fi
    exit 0
fi

# --- Browse mode ---
if ! command -v fzf &>/dev/null; then
    echo -e "${R}fzf required:${N} Install with your package manager (brew install fzf / apt install fzf)"
    exit 1
fi

# Build session list
TMP=$(mktemp)

DEPTH_OPTS=()
if $INCLUDE_SUBAGENTS; then
    DEPTH_OPTS=()
elif $GLOBAL; then
    DEPTH_OPTS=(-maxdepth 2)
else
    DEPTH_OPTS=(-maxdepth 1)
fi

while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    ID=$(basename "$f" .jsonl)
    MSGS=$(grep -c '"role":' "$f" 2>/dev/null || echo 0)

    # Skip empty sessions
    [[ "$MSGS" -eq 0 ]] && continue

    MOD=$(stat_fmt_time "$f")

    # Get project name (for global mode)
    if $GLOBAL; then
        PDIR=$(dirname "$f")
        PROJ=$(basename "$PDIR" | sed 's/^-//;s/-/\//g' | awk -F/ '{print $NF}')
        PROJ="[${PROJ:0:12}]"
    else
        PROJ=""
    fi

    # Get session name
    NAME=$(grep -m1 '"sessionName"' "$f" | sed 's/.*"sessionName":"\([^"]*\)".*/\1/' 2>/dev/null)
    if [[ -z "$NAME" ]]; then
        NAME=$(grep -m1 '"role":"user"' "$f" | sed 's/.*"content":"\([^"]*\)".*/\1/' | cut -c1-40 2>/dev/null)
    fi
    NAME=${NAME:-"Unnamed"}

    printf "%-16s  %4s msgs  %-13s  %-40s  %s\n" "$MOD" "$MSGS" "$PROJ" "${NAME:0:40}" "$ID"
done < <(find "$DIR" "${DEPTH_OPTS[@]}" -name "*.jsonl" -type f 2>/dev/null) | sort -r > "$TMP"

if [[ ! -s "$TMP" ]]; then
    echo -e "${D}No sessions with messages found${N}"
    rm "$TMP"
    exit 0
fi

# Show in fzf
SEL=$(cat "$TMP" | fzf \
    --reverse \
    --header="$HEADER • ↑/↓ Navigate • Enter to Resume" \
    --height=80% \
    --ansi)
rm "$TMP"

if [[ -n "$SEL" ]]; then
    ID=$(echo "$SEL" | awk '{print $NF}')
    if [[ -f ~/.claude/.yolo ]]; then
        exec claude --dangerously-skip-permissions --resume "$ID"
    else
        exec claude --resume "$ID"
    fi
fi
