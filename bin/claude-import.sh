#!/usr/bin/env bash
# ==============================================================================
# Claude Session Import - Import sessions from export files
# ==============================================================================

import_file="${1:-}"
target_project="${2:-$(pwd)}"

if [[ -z "$import_file" ]] || [[ ! -f "$import_file" ]]; then
    echo "Usage: claude-import <export-file> [target-project-dir]"
    echo ""
    echo "Import formats:"
    echo "  • .tar.gz  - Full session backup"
    echo "  • .json    - Session transcript only"
    echo ""
    echo "Examples:"
    echo "  claude-import my-session.tar.gz"
    echo "  claude-import session.json /path/to/project"
    exit 1
fi

# Encode project path (Claude uses dashes to replace slashes)
target_project=$(cd "$target_project" 2>/dev/null && pwd -P)
encoded_path=$(echo "$target_project" | sed 's|/|-|g')
project_dir="$HOME/.claude/projects/$encoded_path"
mkdir -p "$project_dir"

extension="${import_file##*.}"
[[ "$import_file" == *.tar.gz ]] && extension="tar.gz"

case "$extension" in
    tar.gz|tgz)
        echo "📦 Importing full session..."
        temp_dir=$(mktemp -d)
        tar -xzf "$import_file" -C "$temp_dir"

        session_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -1)

        # Copy .jsonl files (named by session ID)
        imported=false
        for jsonl in "$session_dir"/*.jsonl; do
            [[ -f "$jsonl" ]] || continue
            fname=$(basename "$jsonl")
            # Old exports used "session.jsonl" — recover ID from directory name
            if [[ "$fname" == "session.jsonl" ]]; then
                dir_name=$(basename "$session_dir")
                session_id="${dir_name#claude-session-}"
                if [[ -n "$session_id" && "$session_id" != "$dir_name" ]]; then
                    cp "$jsonl" "$project_dir/${session_id}.jsonl"
                    echo "✓ Imported session: ${session_id}"
                    imported=true
                else
                    echo "❌ Cannot determine session ID from export"
                    continue
                fi
            else
                cp "$jsonl" "$project_dir/"
                echo "✓ Imported session: ${fname%.jsonl}"
                imported=true
            fi
        done

        if [[ -d "$session_dir/memory" ]]; then
            if [[ -d "$project_dir/memory" ]]; then
                echo "⚠️  Target already has memory directory, merging..."
                if [[ -n "$(ls -A "$session_dir/memory" 2>/dev/null)" ]]; then
                    cp -r "$session_dir/memory/"* "$project_dir/memory/" 2>/dev/null || true
                    echo "✓ Merged memory contents"
                fi
            else
                cp -r "$session_dir/memory" "$project_dir/"
                echo "✓ Imported memory directory"
            fi
        fi

        rm -rf "$temp_dir"
        echo "✓ Session imported to: $project_dir"
        ;;

    json|jsonl)
        echo "📄 Importing session transcript..."
        cp "$import_file" "$project_dir/"
        echo "✓ Session imported to: $project_dir"
        ;;

    *)
        echo "❌ Unknown format: $extension"
        echo "Supported: .tar.gz, .json"
        exit 1
        ;;
esac
