#!/usr/bin/env bash
# ==============================================================================
# Claude Session Export - Export sessions for sharing/backup
# ==============================================================================

session_id="${1:-}"
output_file="${2:-}"

if [[ -z "$session_id" ]]; then
    echo "Usage: claude-export <session-id> [output-file]"
    echo ""
    echo "Export formats:"
    echo "  • .tar.gz  - Full session backup (with memory)"
    echo "  • .json    - Session transcript only"
    echo "  • .md      - Human-readable markdown"
    echo ""
    echo "Examples:"
    echo "  claude-export abc-123 my-session.tar.gz"
    echo "  claude-export abc-123 session.json"
    echo "  claude-export abc-123 summary.md"
    exit 1
fi

# Find session file
projects_dir="$HOME/.claude/projects"
session_file=$(find "$projects_dir" -name "${session_id}.jsonl" -type f 2>/dev/null | head -1)

if [[ ! -f "$session_file" ]]; then
    echo "❌ Session not found: $session_id"
    exit 1
fi

project_dir=$(dirname "$session_file")
memory_dir="$project_dir/memory"

# Determine format from extension
if [[ -z "$output_file" ]]; then
    output_file="claude-session-${session_id}.tar.gz"
fi

extension="${output_file##*.}"
[[ "$output_file" == *.tar.gz ]] && extension="tar.gz"

case "$extension" in
    tar.gz|tgz)
        # Full backup with memory
        echo "📦 Exporting full session backup..."
        temp_dir=$(mktemp -d)
        export_dir="$temp_dir/claude-session-$session_id"
        mkdir -p "$export_dir"

        cp "$session_file" "$export_dir/${session_id}.jsonl"

        if [[ -d "$memory_dir" ]]; then
            cp -r "$memory_dir" "$export_dir/"
        fi

        tar -czf "$output_file" -C "$temp_dir" "claude-session-$session_id"
        rm -rf "$temp_dir"

        echo "✓ Exported to: $output_file"
        ;;

    json)
        # JSON transcript only
        echo "📄 Exporting session transcript..."
        cp "$session_file" "$output_file"
        echo "✓ Exported to: $output_file"
        ;;

    md)
        # Markdown summary
        echo "📝 Generating markdown summary..."
        {
            echo "# Claude Session: $session_id"
            echo ""
            echo "**Exported:** $(date +"%Y-%m-%d %H:%M")"
            echo ""
            echo "## Messages"
            echo ""

            grep -o '"role":"[^"]*".*"content":"[^"]*"' "$session_file" | while IFS= read -r line; do
                role=$(echo "$line" | sed 's/.*"role":"\([^"]*\)".*/\1/')
                content=$(echo "$line" | sed 's/.*"content":"\([^"]*\)".*/\1/' | sed 's/\\n/\n/g')

                echo "### $role"
                echo ""
                echo "$content"
                echo ""
            done
        } > "$output_file"

        echo "✓ Exported to: $output_file"
        ;;

    *)
        echo "❌ Unknown format: $extension"
        echo "Supported: .tar.gz, .json, .md"
        exit 1
        ;;
esac
