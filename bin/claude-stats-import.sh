#!/usr/bin/env bash
# Import historical token usage from all session JSONL files

set -e

# Colors (Anthropic orange theme)
O='\033[38;5;208m'
W='\033[38;5;214m'
G='\033[32m'
D='\033[90m'
B='\033[1m'
N='\033[0m'

PROJ_DIR="$HOME/.claude/projects"
STATS_FILE="$HOME/.claude/stats-detailed.json"

echo ""
echo -e "  ${O}${B}╔══════════════════════════════════════════╗${N}"
echo -e "  ${O}${B}║       IMPORTING HISTORICAL STATS         ║${N}"
echo -e "  ${O}${B}╚══════════════════════════════════════════╝${N}"
echo ""

# Initialize stats file
echo '{
  "sessions": {},
  "lastUpdated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
}' > "$STATS_FILE.tmp"

total_sessions=0
total_in=0
total_out=0
skipped=0

echo -e "  ${W}Scanning all session files...${N}"

# Find all session JSONL files
while IFS= read -r session_file; do
    session_id=$(basename "$session_file" .jsonl)

    # Skip if not a valid UUID-like session ID
    if [[ ! "$session_id" =~ ^[a-f0-9-]{36}$ ]] && [[ ! "$session_id" =~ ^agent- ]]; then
        ((skipped++))
        continue
    fi

    # Get project path
    project_dir=$(dirname "$session_file")
    project_name=$(basename "$project_dir" | sed 's/^-//;s/-/\//g' | awk -F/ '{print $NF}')

    # Get first and last message timestamps
    first_msg=$(grep -m1 '"type":"message"' "$session_file" 2>/dev/null || echo "")
    last_msg=$(tail -100 "$session_file" | grep '"type":"message"' | tail -1 2>/dev/null || echo "")

    if [[ -z "$first_msg" ]]; then
        ((skipped++))
        continue
    fi

    # Extract timestamps
    created=$(echo "$first_msg" | jq -r '.timestamp // empty' 2>/dev/null || echo "")
    updated=$(echo "$last_msg" | jq -r '.timestamp // empty' 2>/dev/null || echo "")

    # Count messages
    msg_count=$(grep -c '"type":"message"' "$session_file" 2>/dev/null || echo 0)

    # Extract token usage from API responses
    in_tokens=0
    out_tokens=0

    while IFS= read -r line; do
        tin=$(echo "$line" | jq -r '.usage.input_tokens // .snapshot.context_window.current_usage.input_tokens // 0' 2>/dev/null || echo 0)
        tout=$(echo "$line" | jq -r '.usage.output_tokens // .snapshot.context_window.current_usage.output_tokens // 0' 2>/dev/null || echo 0)

        if [[ $tin -gt 0 ]]; then
            in_tokens=$tin
        fi
        if [[ $tout -gt 0 ]]; then
            out_tokens=$tout
        fi
    done < "$session_file"

    total_in=$((total_in + in_tokens))
    total_out=$((total_out + out_tokens))

    # Store session data
    jq --arg sid "$session_id" \
       --arg proj "$project_name" \
       --arg created "$created" \
       --arg updated "$updated" \
       --argjson msgs "$msg_count" \
       --argjson tin "$in_tokens" \
       --argjson tout "$out_tokens" \
       '.sessions[$sid] = {
           "project": $proj,
           "created": $created,
           "updated": $updated,
           "messages": $msgs,
           "tokens": {
               "input": $tin,
               "output": $tout,
               "total": ($tin + $tout)
           }
       }' "$STATS_FILE.tmp" > "$STATS_FILE.tmp2"

    mv "$STATS_FILE.tmp2" "$STATS_FILE.tmp"
    ((total_sessions++))

    # Progress indicator
    if (( total_sessions % 10 == 0 )); then
        echo -ne "\r  ${D}Processed: $total_sessions sessions...${N}"
    fi
done < <(find "$PROJ_DIR" -name "*.jsonl" -type f 2>/dev/null)

echo -ne "\r  ${G}Processed: $total_sessions sessions${N}\n"

# Add totals
jq --argjson total_sessions "$total_sessions" \
   --argjson total_in "$total_in" \
   --argjson total_out "$total_out" \
   --argjson skipped "$skipped" \
   '.totals = {
       "sessions": $total_sessions,
       "skipped": $skipped,
       "tokens": {
           "input": $total_in,
           "output": $total_out,
           "total": ($total_in + $total_out)
       }
   }' "$STATS_FILE.tmp" > "$STATS_FILE"

rm "$STATS_FILE.tmp"

echo ""
echo -e "  ${O}${B}══════════════════════════════════════════${N}"
echo -e "  ${W}Sessions:${N}  ${B}$total_sessions${N}"
echo -e "  ${W}Tokens:${N}    ${B}$(printf "%'d" $((total_in + total_out)))${N}  ${D}($(printf "%'d" $total_in) in / $(printf "%'d" $total_out) out)${N}"
echo -e "  ${W}Skipped:${N}   ${D}$skipped${N}"
echo -e "  ${O}${B}══════════════════════════════════════════${N}"
echo ""
echo -e "  ${D}Saved to: $STATS_FILE${N}"
echo -e "  ${O}Note:${N} ${D}Historical token counts may be incomplete for older sessions${N}"
echo ""
