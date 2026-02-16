#!/usr/bin/env bash

# Claude Code Statusline - wide 3-line layout, orange theme
# Shows: session totals (from JSONL) + project totals (all sessions)
# Cross-platform: macOS + Linux

input=$(cat)

# --- Extract current session data ---
MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
SESSION_ID=$(echo "$input" | jq -r '.session_id // ""')
CONTEXT_USED_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
CWD=$(echo "$input" | jq -r '.workspace.current_dir // "N/A"')
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // "N/A"')

# --- Colors (orange theme) ---
ORANGE='\033[38;5;208m'
GOLD='\033[38;5;214m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
MAGENTA='\033[35m'
GRAY='\033[90m'
WHITE='\033[97m'
BOLD='\033[1m'
NC='\033[0m'

# --- Cross-platform helpers ---
stat_mtime() {
    stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

md5_hash() {
    echo "$1" | md5 2>/dev/null || echo "$1" | md5sum 2>/dev/null | cut -d' ' -f1
}

# Cross-platform date parsing (ISO timestamp to epoch)
date_to_epoch() {
    local ts="${1%%.*}"  # strip fractional seconds
    ts="${ts%%Z}"        # strip Z suffix
    date -j -f "%Y-%m-%dT%H:%M:%S" "$ts" +%s 2>/dev/null || date -d "$1" +%s 2>/dev/null || echo 0
}

# --- Format helpers ---
fmt_tokens() {
    local n=$1
    if [[ $n -ge 1000000 ]]; then
        awk "BEGIN {printf \"%.1fM\", $n/1000000}"
    elif [[ $n -ge 1000 ]]; then
        awk "BEGIN {printf \"%.1fK\", $n/1000}"
    else
        printf "%d" "$n"
    fi
}

fmt_duration() {
    local ms=$1
    local sec=$((ms / 1000))
    local h=$((sec / 3600))
    local m=$(((sec % 3600) / 60))
    if [[ $h -gt 0 ]]; then
        printf "%dh %dm" "$h" "$m"
    else
        printf "%dm" "$m"
    fi
}

# --- Calculate session totals from JSONL file (cached 10s) ---
calc_session_totals() {
    local session_id="$1"
    local project_path="$2"
    local cache_file="/tmp/claude-sl-session-${session_id}"

    # Check cache
    if [[ -f "$cache_file" ]]; then
        local age=$(( $(date +%s) - $(stat_mtime "$cache_file") ))
        if [[ $age -lt 10 ]]; then
            cat "$cache_file"
            return
        fi
    fi

    # Find session JSONL
    local encoded_path
    encoded_path=$(echo "$project_path" | sed 's|^/||; s|/|-|g')
    local project_store="$HOME/.claude/projects/-${encoded_path}"
    local jsonl_file="${project_store}/${session_id}.jsonl"

    if [[ ! -f "$jsonl_file" ]]; then
        echo "0 0 0 0 0"
        return
    fi

    # Sum tokens from all assistant messages and calculate cost
    local result
    result=$(jq -r 'select(.type == "assistant" and .message.usage != null) |
        .message.model as $model |
        .message.usage |
        [
            (.input_tokens // 0),
            (.output_tokens // 0),
            (.cache_creation_input_tokens // 0),
            (.cache_read_input_tokens // 0),
            $model
        ] | @tsv' "$jsonl_file" 2>/dev/null | awk '
    {
        in_tok += $1; out_tok += $2; cache_create += $3; cache_read += $4
        model = $5
        if (model ~ /opus/) {
            cost += ($1 * 15 / 1000000) + ($2 * 75 / 1000000) + ($3 * 18.75 / 1000000) + ($4 * 1.875 / 1000000)
        } else if (model ~ /sonnet/) {
            cost += ($1 * 3 / 1000000) + ($2 * 15 / 1000000) + ($3 * 3.75 / 1000000) + ($4 * 0.30 / 1000000)
        } else if (model ~ /haiku/) {
            cost += ($1 * 0.80 / 1000000) + ($2 * 4 / 1000000) + ($3 * 1.0 / 1000000) + ($4 * 0.08 / 1000000)
        }
    }
    END {
        printf "%d %d %d %d %.4f\n", in_tok, out_tok, cache_create + cache_read, in_tok + out_tok + cache_create + cache_read, cost
    }')

    echo "$result" > "$cache_file"
    echo "$result"
}

# --- Calculate project totals from all JSONL files (cached 30s) ---
calc_project_totals() {
    local project_path="$1"
    local cache_file="/tmp/claude-sl-project-$(md5_hash "$project_path")"

    # Check cache
    if [[ -f "$cache_file" ]]; then
        local age=$(( $(date +%s) - $(stat_mtime "$cache_file") ))
        if [[ $age -lt 30 ]]; then
            cat "$cache_file"
            return
        fi
    fi

    local encoded_path
    encoded_path=$(echo "$project_path" | sed 's|^/||; s|/|-|g')
    local project_store="$HOME/.claude/projects/-${encoded_path}"

    if [[ ! -d "$project_store" ]]; then
        echo "0 0"
        return
    fi

    # Count sessions and sum cost across all JSONL files
    local session_count=0
    local total_cost=0

    for f in "${project_store}"/*.jsonl; do
        [[ -f "$f" ]] || continue
        session_count=$((session_count + 1))
        local file_cost
        file_cost=$(jq -r 'select(.type == "assistant" and .message.usage != null) |
            .message.model as $model |
            .message.usage |
            [(.input_tokens // 0), (.output_tokens // 0), (.cache_creation_input_tokens // 0), (.cache_read_input_tokens // 0), $model] | @tsv' "$f" 2>/dev/null | awk '
        {
            model = $5
            if (model ~ /opus/) {
                cost += ($1 * 15 / 1000000) + ($2 * 75 / 1000000) + ($3 * 18.75 / 1000000) + ($4 * 1.875 / 1000000)
            } else if (model ~ /sonnet/) {
                cost += ($1 * 3 / 1000000) + ($2 * 15 / 1000000) + ($3 * 3.75 / 1000000) + ($4 * 0.30 / 1000000)
            } else if (model ~ /haiku/) {
                cost += ($1 * 0.80 / 1000000) + ($2 * 4 / 1000000) + ($3 * 1.0 / 1000000) + ($4 * 0.08 / 1000000)
            }
        }
        END { printf "%.4f", cost }')
        total_cost=$(awk "BEGIN {printf \"%.4f\", $total_cost + $file_cost}")
    done

    local result="${session_count} ${total_cost}"
    echo "$result" > "$cache_file"
    echo "$result"
}

# --- Get session total duration from JSONL timestamps (cached 10s) ---
calc_session_duration() {
    local session_id="$1"
    local project_path="$2"
    local cache_file="/tmp/claude-sl-dur-${session_id}"

    if [[ -f "$cache_file" ]]; then
        local age=$(( $(date +%s) - $(stat_mtime "$cache_file") ))
        if [[ $age -lt 10 ]]; then
            cat "$cache_file"
            return
        fi
    fi

    local encoded_path
    encoded_path=$(echo "$project_path" | sed 's|^/||; s|/|-|g')
    local jsonl_file="$HOME/.claude/projects/-${encoded_path}/${session_id}.jsonl"

    if [[ ! -f "$jsonl_file" ]]; then
        echo "0"
        return
    fi

    # Get first and last timestamps
    local first_ts last_ts
    first_ts=$(jq -r 'select(.timestamp != null) | .timestamp' "$jsonl_file" 2>/dev/null | head -1)
    last_ts=$(jq -r 'select(.timestamp != null) | .timestamp' "$jsonl_file" 2>/dev/null | tail -1)

    if [[ -n "$first_ts" && -n "$last_ts" ]]; then
        local first_epoch last_epoch dur_ms
        first_epoch=$(date_to_epoch "$first_ts")
        last_epoch=$(date_to_epoch "$last_ts")
        dur_ms=$(( (last_epoch - first_epoch) * 1000 ))
        echo "$dur_ms" > "$cache_file"
        echo "$dur_ms"
    else
        echo "0" > "$cache_file"
        echo "0"
    fi
}

# --- Calculate totals ---
SESSION_DATA=$(calc_session_totals "$SESSION_ID" "$PROJECT_DIR")
read -r S_IN S_OUT S_CACHE S_TOTAL S_COST <<< "$SESSION_DATA"

PROJECT_DATA=$(calc_project_totals "$PROJECT_DIR")
read -r P_SESSIONS P_COST <<< "$PROJECT_DATA"

TOTAL_SESSION_DUR=$(calc_session_duration "$SESSION_ID" "$PROJECT_DIR")

# Format session tokens
S_IN_FMT=$(fmt_tokens "$S_IN")
S_OUT_FMT=$(fmt_tokens "$S_OUT")
S_CACHE_FMT=$(fmt_tokens "$S_CACHE")
S_TOTAL_FMT=$(fmt_tokens "$S_TOTAL")

# Format costs
S_COST_FMT=$(printf '$%.2f' "$S_COST")
P_COST_FMT=$(printf '$%.2f' "$P_COST")

# Format durations
CURRENT_DUR_FMT=$(fmt_duration "$DURATION_MS")
TOTAL_DUR_FMT=$(fmt_duration "$TOTAL_SESSION_DUR")

# --- Context progress bar ---
BAR_WIDTH=20
USED_BARS=$(awk "BEGIN {printf \"%.0f\", $CONTEXT_USED_PCT * $BAR_WIDTH / 100}")
REMAINING_BARS=$((BAR_WIDTH - USED_BARS))

if awk "BEGIN {exit !($CONTEXT_USED_PCT > 80)}"; then
    BAR_COLOR="$RED"
elif awk "BEGIN {exit !($CONTEXT_USED_PCT > 60)}"; then
    BAR_COLOR="$YELLOW"
else
    BAR_COLOR="$GREEN"
fi

BAR_FILLED=""
BAR_EMPTY=""
[[ $USED_BARS -gt 0 ]] && BAR_FILLED=$(printf '█%.0s' $(seq 1 "$USED_BARS"))
[[ $REMAINING_BARS -gt 0 ]] && BAR_EMPTY=$(printf '░%.0s' $(seq 1 "$REMAINING_BARS"))
PROGRESS_BAR="${BAR_COLOR}${BAR_FILLED}${GRAY}${BAR_EMPTY}${NC}"
CONTEXT_USED_FMT=$(printf "%.0f" "$CONTEXT_USED_PCT")

# --- Git info (cached 5s) ---
GIT_CACHE_FILE="/tmp/claude-statusline-git"

get_git_info() {
    if [[ -f "$GIT_CACHE_FILE" ]]; then
        local age=$(( $(date +%s) - $(stat_mtime "$GIT_CACHE_FILE") ))
        if [[ $age -lt 5 ]]; then
            cat "$GIT_CACHE_FILE"
            return
        fi
    fi
    local info=""
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local branch
        branch=$(git branch --show-current 2>/dev/null || echo "detached")
        local changes
        changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        info="${branch}"
        [[ $changes -gt 0 ]] && info="${info} *${changes}"
    fi
    echo "$info" > "$GIT_CACHE_FILE"
    echo "$info"
}

GIT_INFO=$(get_git_info)

# --- Output (3 wide lines) ---

# Line 1: Path (git) | Model | Duration: current (total session)
LINE1="${ORANGE}${BOLD}${PROJECT_DIR}${NC}"
[[ -n "$GIT_INFO" ]] && LINE1="${LINE1} ${GRAY}(${NC}${MAGENTA}${GIT_INFO}${NC}${GRAY})${NC}"
LINE1="${LINE1} ${GRAY}|${NC} ${MODEL} ${GRAY}|${NC} ${ORANGE}${BOLD}Time:${NC} ${CURRENT_DUR_FMT}"
[[ "$TOTAL_SESSION_DUR" -gt 0 ]] && LINE1="${LINE1} ${GRAY}(total: ${TOTAL_DUR_FMT})${NC}"
echo -e "$LINE1"

# Line 2: Tokens + Session cost + Project cost
LINE2="${ORANGE}${BOLD}Tokens:${NC} ${GREEN}${S_IN_FMT}${NC} in  ${GOLD}${S_OUT_FMT}${NC} out  ${BLUE}${S_CACHE_FMT}${NC} cache  ${GRAY}=${NC} ${BOLD}${S_TOTAL_FMT}${NC} total"
LINE2="${LINE2} ${GRAY}|${NC} ${ORANGE}${BOLD}Cost:${NC} ${GOLD}${S_COST_FMT}${NC} session  ${GOLD}${P_COST_FMT}${NC} project ${GRAY}(${P_SESSIONS} sessions)${NC}"
echo -e "$LINE2"

# Line 3: Context bar + code changes
echo -e "${ORANGE}${BOLD}Context:${NC} ${PROGRESS_BAR} ${BAR_COLOR}${CONTEXT_USED_FMT}%${NC} ${GRAY}|${NC} ${ORANGE}${BOLD}Code:${NC} ${GREEN}+${LINES_ADDED}${NC} ${RED}-${LINES_REMOVED}${NC} ${GRAY}|${NC} ${ORANGE}${BOLD}ID:${NC} ${GRAY}${SESSION_ID}${NC}"
