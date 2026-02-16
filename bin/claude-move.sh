#!/usr/bin/env bash
# ==============================================================================
# Claude Session Mover - Move session to different working directory
# ==============================================================================

session_id="${1:-}"
target_dir="${2:-$(pwd)}"

if [[ -z "$session_id" ]]; then
    echo "Usage: claude-move <session-id> [target-directory]"
    echo ""
    echo "Moves a session to a different working directory."
    echo "Useful when you started a session in the wrong directory."
    echo ""
    echo "Examples:"
    echo "  claude-move abc-123 /path/to/correct/project"
    echo "  claude-move abc-123  # moves to current directory"
    exit 1
fi

# Find current session file
projects_dir="$HOME/.claude/projects"
current_session=$(find "$projects_dir" -name "${session_id}.jsonl" -type f 2>/dev/null | head -1)

if [[ ! -f "$current_session" ]]; then
    echo "❌ Session not found: $session_id"
    exit 1
fi

current_project=$(dirname "$current_session")
current_memory="$current_project/memory"

# Encode target path (Claude uses dashes to replace slashes)
target_dir=$(cd "$target_dir" 2>/dev/null && pwd -P)
encoded_target=$(echo "$target_dir" | sed 's|/|-|g')
target_project="$projects_dir/$encoded_target"

mkdir -p "$target_project"

echo "Moving session $session_id"
echo "  From: $current_project"
echo "  To:   $target_project"
echo ""

# Move session file
mv "$current_session" "$target_project/"
echo "✓ Moved session file"

# Move memory if exists
if [[ -d "$current_memory" ]]; then
    if [[ -d "$target_project/memory" ]]; then
        echo "⚠️  Target already has memory directory, merging..."
        # Copy files, handling both empty and non-empty directories
        if [[ -n "$(ls -A "$current_memory" 2>/dev/null)" ]]; then
            cp -r "$current_memory/"* "$target_project/memory/" 2>/dev/null || true
            echo "✓ Merged memory contents"
        fi
        rm -rf "$current_memory"
    else
        mv "$current_memory" "$target_project/"
        echo "✓ Moved memory directory"
    fi
else
    echo "ℹ️  No memory directory to move"
fi

# Clean up empty source directory
if [[ -z "$(ls -A "$current_project")" ]]; then
    rmdir "$current_project"
    echo "✓ Cleaned up empty source directory"
fi

echo ""
echo "✓ Session moved successfully!"
echo "Resume with: claude --resume $session_id"
