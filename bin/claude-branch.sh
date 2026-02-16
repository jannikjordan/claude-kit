#!/usr/bin/env bash
# ==============================================================================
# Smart Git Branch Creator - Create feature branches from task descriptions
# ==============================================================================

task_description="$*"

if [[ -z "$task_description" ]]; then
    echo "Usage: claude-branch <task description>"
    echo ""
    echo "Examples:"
    echo "  claude-branch add user authentication"
    echo "  claude-branch fix login bug"
    echo "  claude-branch refactor api layer"
    exit 1
fi

# Convert task to branch name
branch_name=$(echo "$task_description" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9 ]//g' | \
    sed -E 's/ +/-/g' | \
    sed 's/^-//;s/-$//')

# Determine prefix from first word
first_word=$(echo "$task_description" | awk '{print tolower($1)}')

case "$first_word" in
    add|implement|create)
        prefix="feature"
        ;;
    fix|bug|resolve)
        prefix="fix"
        ;;
    refactor|improve|optimize)
        prefix="refactor"
        ;;
    update|modify|change)
        prefix="update"
        ;;
    test|testing)
        prefix="test"
        ;;
    docs|documentation)
        prefix="docs"
        ;;
    *)
        prefix="feature"
        ;;
esac

full_branch="$prefix/$branch_name"

echo "Creating branch: $full_branch"

# Create and checkout branch
if git rev-parse --verify "$full_branch" &>/dev/null; then
    echo "Branch already exists, checking out..."
    git checkout "$full_branch"
else
    git checkout -b "$full_branch"
    echo "✓ Created and checked out: $full_branch"
fi
