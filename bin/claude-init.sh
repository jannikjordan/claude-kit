#!/usr/bin/env bash
# ==============================================================================
# CLAUDE.md Template Initializer - Quick project setup
# ==============================================================================

template="${1:-}"
output_file="${2:-.claude/CLAUDE.md}"

TEMPLATE_DIR="$(dirname "$0")/templates"

if [[ -z "$template" ]]; then
    echo "Usage: claude-init <template> [output-file]"
    echo ""
    echo "Available templates:"
    echo "  react    - React + TypeScript project"
    echo "  python   - Python project (FastAPI/Django/Flask)"
    echo "  api      - REST API project"
    echo ""
    echo "Examples:"
    echo "  claude-init react"
    echo "  claude-init python .claude/CLAUDE.md"
    exit 1
fi

template_file="$TEMPLATE_DIR/CLAUDE.$template.md"

if [[ ! -f "$template_file" ]]; then
    echo "❌ Template not found: $template"
    echo ""
    echo "Available templates:"
    ls "$TEMPLATE_DIR" | sed 's/CLAUDE\.//;s/\.md$//' | sed 's/^/  /'
    exit 1
fi

# Create .claude directory if needed
mkdir -p "$(dirname "$output_file")"

# Copy template
cp "$template_file" "$output_file"

echo "✓ Created $output_file from $template template"
echo ""
echo "Next steps:"
echo "  1. Edit $output_file with project-specific details"
echo "  2. Start Claude: claude"
echo "  3. Claude will automatically load the instructions"
