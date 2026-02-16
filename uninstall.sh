#!/usr/bin/env bash
# ==============================================================================
# claude-kit Uninstall — fully removes all installed files, configs, and aliases
# Works on macOS and Linux, supports bash and zsh
# ==============================================================================

set -e

# Colors
O='\033[38;5;208m'
W='\033[38;5;214m'
G='\033[32m'
R='\033[31m'
D='\033[90m'
B='\033[1m'
N='\033[0m'

echo ""
echo -e "  ${O}${B}╔══════════════════════════════════════════╗${N}"
echo -e "  ${O}${B}║         claude-kit Uninstall             ║${N}"
echo -e "  ${O}${B}╚══════════════════════════════════════════╝${N}"
echo ""

# Confirm
read -rp "  This will remove all claude-kit files and shell aliases. Continue? [y/N]: " answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo -e "  ${D}Aborted.${N}"
    exit 0
fi

echo ""

# --- 1. Remove installed scripts from ~/.claude/ ---
echo -e "  ${W}Removing helper scripts...${N}"
SCRIPTS=(
    claude-sessions.sh
    claude-stats.sh
    claude-stats-import.sh
    claude-export.sh
    claude-import.sh
    claude-move.sh
    claude-new.sh
    claude-branch.sh
    claude-init.sh
    claude-mcp.sh
    statusline-enhanced.sh
    shell-snippet.sh
    zshrc-snippet.sh
)

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$HOME/.claude/$script" ]]; then
        rm -f "$HOME/.claude/$script"
        echo -e "    ${D}removed ~/.claude/$script${N}"
    fi
done
echo -e "  ${G}  done${N}"

# --- 2. Remove templates ---
echo -e "  ${W}Removing templates...${N}"
if [[ -d "$HOME/.claude/templates" ]]; then
    rm -rf "$HOME/.claude/templates"
    echo -e "    ${D}removed ~/.claude/templates/${N}"
fi
echo -e "  ${G}  done${N}"

# --- 3. Remove hooks ---
echo -e "  ${W}Removing hooks...${N}"
if [[ -f "$HOME/.claude/hooks/pre-commit" ]]; then
    rm -f "$HOME/.claude/hooks/pre-commit"
    echo -e "    ${D}removed ~/.claude/hooks/pre-commit${N}"
fi
# Remove hooks dir if empty
rmdir "$HOME/.claude/hooks" 2>/dev/null || true
echo -e "  ${G}  done${N}"

# --- 4. Remove safe mode flag ---
if [[ -f "$HOME/.claude/.yolo" ]]; then
    rm -f "$HOME/.claude/.yolo"
    echo -e "  ${D}  removed ~/.claude/.yolo${N}"
fi

# --- 5. Restore settings.json from backup if available ---
echo -e "  ${W}Restoring settings...${N}"
if [[ -f "$HOME/.claude/settings.json.backup" ]]; then
    mv "$HOME/.claude/settings.json.backup" "$HOME/.claude/settings.json"
    echo -e "    ${D}restored settings.json from backup${N}"
else
    # Only remove if it's ours (has our statusline command)
    if grep -q 'statusline-enhanced.sh' "$HOME/.claude/settings.json" 2>/dev/null; then
        rm -f "$HOME/.claude/settings.json"
        echo -e "    ${D}removed settings.json${N}"
    fi
fi
echo -e "  ${G}  done${N}"

# --- 6. Remove shell snippet from ALL shell configs ---
echo -e "  ${W}Cleaning shell configs...${N}"

clean_shell_config() {
    local config_file="$1"
    [[ -f "$config_file" ]] || return 0

    if grep -q '>>> CLAUDE CODE >>>' "$config_file" 2>/dev/null; then
        awk '/>>> CLAUDE CODE >>>/,/<<< CLAUDE CODE <<</{next}1' "$config_file" > "$config_file.tmp"
        mv "$config_file.tmp" "$config_file"
        echo -e "    ${D}cleaned $config_file${N}"
    fi

    # Also remove legacy alias sections (from older claude-setup versions)
    if grep -q 'alias claude=.*--dangerously-skip-permissions' "$config_file" 2>/dev/null; then
        awk '/alias claude=.*dangerously-skip-permissions/,/^alias ch=/{next}1' "$config_file" > "$config_file.tmp"
        mv "$config_file.tmp" "$config_file"
        echo -e "    ${D}removed legacy aliases from $config_file${N}"
    fi

    # Remove any leftover blank lines at end of file
    if [[ -f "$config_file" ]]; then
        local tmp
        tmp=$(awk 'NF{p=1; for(i=1;i<=bl;i++) print ""; bl=0; print; next} p{bl++}' "$config_file" 2>/dev/null) || true
        if [[ -n "$tmp" ]]; then
            printf '%s\n' "$tmp" > "$config_file"
        fi
    fi
}

# Clean all possible shell config files
clean_shell_config "$HOME/.zshrc"
clean_shell_config "$HOME/.bashrc"
clean_shell_config "$HOME/.profile"
clean_shell_config "$HOME/.bash_profile"

echo -e "  ${G}  done${N}"

# --- 7. Clean up statusline cache files ---
echo -e "  ${W}Cleaning cache files...${N}"
rm -f /tmp/claude-sl-session-* 2>/dev/null
rm -f /tmp/claude-sl-project-* 2>/dev/null
rm -f /tmp/claude-sl-dur-* 2>/dev/null
rm -f /tmp/claude-statusline-git 2>/dev/null
echo -e "  ${G}  done${N}"

echo ""
echo -e "  ${O}${B}══════════════════════════════════════════${N}"
echo -e "  ${O}${B}  Uninstall Complete${N}"
echo -e "  ${O}${B}══════════════════════════════════════════${N}"
echo ""
echo -e "  ${W}claude-kit has been fully removed.${N}"
echo ""
echo -e "  ${D}Note: ~/.claude/ directory was preserved (contains your sessions).${N}"
echo -e "  ${D}To remove all Claude data: rm -rf ~/.claude${N}"
echo ""
echo -e "  ${W}Restart your shell or run:${N}"
echo -e "    ${O}exec \$SHELL${N}"
echo ""
