#!/usr/bin/env bash
# ==============================================================================
# claude-kit Config Install — no system changes, just copies configs
# Works on macOS and Linux, supports bash and zsh
#
# Usage: source ./install.sh   (recommended — activates commands immediately)
#        ./install.sh           (also works — requires shell restart)
# ==============================================================================

_claude_kit_install() {
    local SCRIPT_DIR
    # Handle both sourced and executed contexts
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        # zsh fallback
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    fi

    # Colors (Anthropic orange theme)
    local O='\033[38;5;208m'
    local W='\033[38;5;214m'
    local G='\033[32m'
    local D='\033[90m'
    local B='\033[1m'
    local N='\033[0m'

    # Detect shell config file
    local SHELL_CONFIG
    case "$(basename "$SHELL")" in
        zsh)  SHELL_CONFIG="$HOME/.zshrc" ;;
        bash) SHELL_CONFIG="$HOME/.bashrc" ;;
        *)    SHELL_CONFIG="$HOME/.profile" ;;
    esac

    echo ""
    echo -e "${O}${B}Installing claude-kit...${N}"
    echo ""

    # Ensure ~/.claude exists
    mkdir -p ~/.claude

    # 1. Copy statusline
    echo -e "${W}Statusline...${N}"
    cp "$SCRIPT_DIR/config/statusline-enhanced.sh" ~/.claude/
    chmod +x ~/.claude/statusline-enhanced.sh
    echo -e "${G}  done${N}"

    # 2. Copy helper scripts
    echo -e "${W}Helper scripts...${N}"
    local script
    for script in "$SCRIPT_DIR"/bin/claude-*.sh; do
        [[ -f "$script" ]] || continue
        cp "$script" ~/.claude/
        chmod +x ~/.claude/"$(basename "$script")"
    done
    echo -e "${G}  done${N}"

    # 3. Copy shell snippet
    echo -e "${W}Shell config...${N}"
    cp "$SCRIPT_DIR/config/shell-snippet.sh" ~/.claude/
    echo -e "${G}  done${N}"

    # 4. Copy templates
    echo -e "${W}Templates...${N}"
    cp -r "$SCRIPT_DIR/templates" ~/.claude/
    echo -e "${G}  done${N}"

    # 5. Copy git hooks
    echo -e "${W}Git hooks...${N}"
    mkdir -p ~/.claude/hooks
    cp "$SCRIPT_DIR/hooks/pre-commit" ~/.claude/hooks/
    chmod +x ~/.claude/hooks/pre-commit
    echo -e "${G}  done${N}"

    # 6. Backup + install settings
    if [[ -f ~/.claude/settings.json ]]; then
        cp ~/.claude/settings.json ~/.claude/settings.json.backup
    fi
    cp "$SCRIPT_DIR/config/settings.json" ~/.claude/settings.json
    echo -e "${G}  settings updated${N}"

    # 7. Update shell config (bash or zsh)
    echo -e "${W}Updating ${SHELL_CONFIG}...${N}"

    # Create file if it doesn't exist
    touch "$SHELL_CONFIG"

    # Remove old claude-setup or claude-kit sections
    if grep -q '>>> CLAUDE CODE >>>' "$SHELL_CONFIG" 2>/dev/null; then
        awk '/>>> CLAUDE CODE >>>/,/<<< CLAUDE CODE <<</{next}1' "$SHELL_CONFIG" > "$SHELL_CONFIG.tmp"
        mv "$SHELL_CONFIG.tmp" "$SHELL_CONFIG"
    fi

    # Remove legacy alias sections
    if grep -q 'alias claude=.*--dangerously-skip-permissions' "$SHELL_CONFIG" 2>/dev/null; then
        awk '/alias claude=.*dangerously-skip-permissions/,/^alias ch=/{next}1' "$SHELL_CONFIG" > "$SHELL_CONFIG.tmp"
        mv "$SHELL_CONFIG.tmp" "$SHELL_CONFIG"
    fi

    # Append fresh configuration
    echo "" >> "$SHELL_CONFIG"
    cat "$SCRIPT_DIR/config/shell-snippet.sh" >> "$SHELL_CONFIG"
    echo -e "${G}  done${N}"

    echo ""
    echo -e "${O}${B}Installation complete!${N}"
    echo ""
    echo -e "${D}Required: jq fzf (install via your package manager)${N}"
    echo ""

    # Source the snippet into the current shell so commands work immediately
    source "$SCRIPT_DIR/config/shell-snippet.sh" 2>/dev/null || true

    # Show help
    claude-help 2>/dev/null || true
}

# Run the install
_claude_kit_install

# Clean up the function from the shell namespace
unset -f _claude_kit_install
