#!/usr/bin/env bash
# Stats: current project or global, with time filtering and per-model breakdown

# Colors (Anthropic orange theme)
O='\033[38;5;208m'
W='\033[38;5;214m'
G='\033[32m'
R='\033[31m'
D='\033[90m'
BL='\033[34m'
B='\033[1m'
N='\033[0m'

PROJ_DIR="$HOME/.claude/projects"

[[ ! -d "$PROJ_DIR" ]] && echo "No projects found" && exit 1

# Cross-platform stat: file modification epoch
stat_mtime() {
    stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

# Parse flags
GLOBAL=false
TIME_FILTER="all"
FILTER_NAME="All Time"

for arg in "$@"; do
    case "$arg" in
        -a|--all|--global) GLOBAL=true ;;
        --today) TIME_FILTER="today"; FILTER_NAME="Last 24 Hours" ;;
        --week) TIME_FILTER="week"; FILTER_NAME="Last 7 Days" ;;
        --month) TIME_FILTER="month"; FILTER_NAME="Last 30 Days" ;;
    esac
done

# Calculate time cutoff
NOW=$(date +%s)
case "$TIME_FILTER" in
    today) CUTOFF=$((NOW - 86400)) ;;
    week) CUTOFF=$((NOW - 604800)) ;;
    month) CUTOFF=$((NOW - 2592000)) ;;
    all) CUTOFF=0 ;;
esac

# Determine search directory
if $GLOBAL; then
    SEARCH_DIR="$PROJ_DIR"
    HEADER="All Projects"
else
    PROJECT=$(cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" && pwd -P)
    ENCODED=$(echo "$PROJECT" | sed 's|/|-|g')
    SEARCH_DIR="$PROJ_DIR/$ENCODED"
    HEADER="$(basename "$PROJECT")"

    if [[ ! -d "$SEARCH_DIR" ]]; then
        echo -e "${O}No sessions for:${N} $PROJECT"
        echo -e "${D}Tip: Use 'claude-stats -a' to see all projects${N}"
        exit 1
    fi
fi

echo ""
echo -e "  ${O}${B}╔══════════════════════════════════════════╗${N}"
echo -e "  ${O}${B}║         CLAUDE CODE STATS                ║${N}"
echo -e "  ${O}${B}╚══════════════════════════════════════════╝${N}"
echo ""
echo -e "  ${B}Scope:${N}       ${W}${HEADER}${N}"
echo -e "  ${B}Time Range:${N}  ${D}${FILTER_NAME}${N}"
echo ""

# Format helpers
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

# Collect all data into temp files
TMP_MODELS=$(mktemp)
TMP_PROJECTS=$(mktemp)
total_sessions=0

if $GLOBAL; then
    find_depth=(-maxdepth 2)
else
    find_depth=(-maxdepth 1)
fi

while IFS= read -r f; do
    [[ -f "$f" ]] || continue

    # Time filter: check file modification time
    if [[ $CUTOFF -gt 0 ]]; then
        file_time=$(stat_mtime "$f")
        [[ $file_time -lt $CUTOFF ]] && continue
    fi

    # Count messages
    msgs=$(grep -c '"role":' "$f" 2>/dev/null || echo 0)
    [[ "$msgs" -eq 0 ]] && continue

    ((total_sessions++))

    # Get project name for global mode
    if $GLOBAL; then
        pdir=$(dirname "$f")
        pname=$(basename "$pdir" | sed 's/^-//;s/-/\//g' | awk -F/ '{print $NF}')
    else
        pname="$HEADER"
    fi

    # Extract per-model stats and append to temp file
    jq -r 'select(.type == "assistant" and .message.usage != null) |
        .message.model as $model |
        .message.usage |
        [(.input_tokens // 0), (.output_tokens // 0), (.cache_creation_input_tokens // 0), (.cache_read_input_tokens // 0), $model] | @tsv' "$f" 2>/dev/null >> "$TMP_MODELS"

    # Track project info for global mode
    if $GLOBAL; then
        echo "$pname" >> "$TMP_PROJECTS"
    fi
done < <(find "$SEARCH_DIR" "${find_depth[@]}" -name "*.jsonl" -type f 2>/dev/null)

# Process all model data with awk (no associative arrays needed!)
MODEL_STATS=$(awk '
{
    in_tok = $1; out_tok = $2; cc = $3; cr = $4; model = $5
    # Normalize model name
    if (model ~ /opus/) mkey = "Opus"
    else if (model ~ /sonnet/) mkey = "Sonnet"
    else if (model ~ /haiku/) mkey = "Haiku"
    else mkey = "Other"

    m_in[mkey] += in_tok
    m_out[mkey] += out_tok
    m_cc[mkey] += cc
    m_cr[mkey] += cr
    m_msgs[mkey]++

    # Calculate cost
    if (mkey == "Opus") {
        m_cost[mkey] += (in_tok * 15 / 1000000) + (out_tok * 75 / 1000000) + (cc * 18.75 / 1000000) + (cr * 1.875 / 1000000)
    } else if (mkey == "Sonnet") {
        m_cost[mkey] += (in_tok * 3 / 1000000) + (out_tok * 15 / 1000000) + (cc * 3.75 / 1000000) + (cr * 0.30 / 1000000)
    } else if (mkey == "Haiku") {
        m_cost[mkey] += (in_tok * 0.80 / 1000000) + (out_tok * 4 / 1000000) + (cc * 1.0 / 1000000) + (cr * 0.08 / 1000000)
    }

    total_in += in_tok
    total_out += out_tok
    total_cc += cc
    total_cr += cr
    total_msgs++
}
END {
    total_cost = 0
    for (m in m_cost) total_cost += m_cost[m]

    # Print totals line
    printf "TOTALS\t%d\t%d\t%d\t%d\t%.4f\n", total_msgs, total_in, total_out, total_cc, total_cr, total_cost

    # Print per-model lines (in preferred order)
    order[1] = "Opus"; order[2] = "Sonnet"; order[3] = "Haiku"; order[4] = "Other"
    for (i = 1; i <= 4; i++) {
        m = order[i]
        if (m in m_in) {
            share = (total_cost > 0) ? (m_cost[m] * 100 / total_cost) : 0
            printf "MODEL\t%s\t%d\t%d\t%d\t%d\t%d\t%.4f\t%.0f\n", m, m_msgs[m], m_in[m], m_out[m], m_cc[m]+m_cr[m], m_in[m]+m_out[m]+m_cc[m]+m_cr[m], m_cost[m], share
        }
    }
}' "$TMP_MODELS" 2>/dev/null)

# Parse totals
TOTALS_LINE=$(echo "$MODEL_STATS" | grep "^TOTALS")
total_msgs=$(echo "$TOTALS_LINE" | cut -f2)
total_in=$(echo "$TOTALS_LINE" | cut -f3)
total_out=$(echo "$TOTALS_LINE" | cut -f4)
total_cc=$(echo "$TOTALS_LINE" | cut -f5)
total_cr=$(echo "$TOTALS_LINE" | cut -f6)
total_cost=$(echo "$TOTALS_LINE" | cut -f7)

# Default to 0 if empty
total_msgs=${total_msgs:-0}
total_in=${total_in:-0}
total_out=${total_out:-0}
total_cc=${total_cc:-0}
total_cr=${total_cr:-0}
total_cost=${total_cost:-0}
total_tokens=$((total_in + total_out + total_cc + total_cr))

# --- Display ---
echo -e "  ${O}${B}── Overview ──${N}"
echo -e "  ${W}Sessions:${N}    ${B}${total_sessions}${N}"
echo -e "  ${W}Messages:${N}    ${B}${total_msgs}${N}"
echo -e "  ${W}Tokens:${N}      ${B}$(fmt_tokens $total_tokens)${N}  ${D}($(fmt_tokens $total_in) in / $(fmt_tokens $total_out) out / $(fmt_tokens $total_cc) cache-w / $(fmt_tokens $total_cr) cache-r)${N}"
echo -e "  ${W}Total Cost:${N}  ${O}${B}\$$(printf '%.2f' "$total_cost")${N}"
echo ""

# Per-model breakdown
MODEL_LINES=$(echo "$MODEL_STATS" | grep "^MODEL")
if [[ -n "$MODEL_LINES" ]]; then
    echo -e "  ${O}${B}── Per Model ──${N}"
    printf "  ${D}%-10s %8s %8s %8s %8s %10s %8s${N}\n" "Model" "Msgs" "In" "Out" "Cache" "Cost" "Share"
    printf "  ${D}%-10s %8s %8s %8s %8s %10s %8s${N}\n" "─────" "────" "──" "───" "─────" "────" "─────"

    while IFS=$'\t' read -r _ mname mmsgs min mout mcache mtotal mcost mshare; do
        color="$N"
        case "$mname" in
            Opus)   color="$W" ;;
            Sonnet) color="$G" ;;
            Haiku)  color="$BL" ;;
        esac
        printf "  ${color}${B}%-10s${N} %8s %8s %8s %8s %10s %7s%%\n" \
            "$mname" "$mmsgs" "$(fmt_tokens "$min")" "$(fmt_tokens "$mout")" "$(fmt_tokens "$mcache")" "\$$(printf '%.2f' "$mcost")" "$mshare"
    done <<< "$MODEL_LINES"
    echo ""
fi

# Projects breakdown (global mode only)
if $GLOBAL && [[ -s "$TMP_PROJECTS" ]]; then
    echo -e "  ${O}${B}── Projects ──${N}"
    # Count sessions per project and calculate costs
    # Re-process files to get per-project costs
    sort "$TMP_PROJECTS" | uniq -c | sort -rn | head -10 | while read -r count pname; do
        printf "  ${W}%-20s${N}  %3s sessions\n" "${pname:0:20}" "$count"
    done
    echo ""
fi

# Cleanup
rm -f "$TMP_MODELS" "$TMP_PROJECTS"

if [[ $total_sessions -eq 0 ]]; then
    echo -e "  ${D}No sessions found${N}"
    if ! $GLOBAL; then
        echo -e "  ${D}Tip: Use 'claude-stats -a' to see all projects${N}"
    fi
    echo ""
fi
