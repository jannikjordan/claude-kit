#!/usr/bin/env bash
# ==============================================================================
# macOS Setup for Claude Code (claude-kit)
# Prepares a Mac for autonomous Claude Code development
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Colors & Helpers --------------------------------------------------------

info()  { printf "\033[38;5;214m[INFO]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[OK]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[38;5;208m[WARN]\033[0m  %s\n" "$1"; }
err()   { printf "\033[1;31m[ERR]\033[0m   %s\n" "$1"; exit 1; }

prompt_yes_no() {
    local message="$1"
    read -rp "$message [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

command_exists() {
    command -v "$1" &>/dev/null
}

# --- Passwordless Sudo -------------------------------------------------------

setup_passwordless_sudo() {
    info "Configuring passwordless sudo..."
    local user
    user="$(whoami)"

    if sudo grep -q "^${user}.*NOPASSWD" /etc/sudoers 2>/dev/null; then
        ok "Passwordless sudo already configured"
    else
        if prompt_yes_no "Add passwordless sudo for ${user}?"; then
            echo "${user} ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers >/dev/null
            ok "Passwordless sudo enabled"
        else
            warn "Skipping passwordless sudo"
        fi
    fi
}

# --- Homebrew -----------------------------------------------------------------

install_homebrew() {
    info "Installing Homebrew..."
    if command_exists brew; then
        ok "Homebrew already installed"
    else
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        ok "Homebrew installed"
    fi
}

# --- Essential Dev Tools ------------------------------------------------------

install_dev_tools() {
    info "Installing essential development tools..."
    local formulae=("git" "jq" "gh" "fzf")
    for pkg in "${formulae[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            ok "$pkg already installed"
        else
            brew install "$pkg"
            ok "$pkg installed"
        fi
    done
}

# --- Claude Code --------------------------------------------------------------

check_claude_code() {
    info "Checking Claude Code installation..."
    if command_exists claude; then
        local version
        version=$(claude --version 2>&1 | head -n1)
        ok "Claude Code installed: ${version}"
    else
        warn "Claude Code not found - install via: npm install -g @anthropic-ai/claude-code"
    fi
}

# --- Git Configuration -------------------------------------------------------

setup_git() {
    info "Checking Git configuration..."
    local git_name git_email
    git_name=$(git config --global user.name 2>/dev/null || echo "")
    git_email=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -n "$git_name" ]] && [[ -n "$git_email" ]]; then
        ok "Git configured: ${git_name} <${git_email}>"
    else
        if prompt_yes_no "Configure git name & email?"; then
            read -rp "  Git name: " git_name
            read -rp "  Git email: " git_email
            git config --global user.name "$git_name"
            git config --global user.email "$git_email"
            ok "Git configured: ${git_name} <${git_email}>"
        else
            warn "Skipping git config"
        fi
    fi
}

# --- macOS Optimizations -----------------------------------------------------

optimize_macos() {
    if ! prompt_yes_no "Apply macOS optimizations? (faster key repeat, show hidden files)"; then
        warn "Skipping macOS optimizations"
        return
    fi

    info "Applying macOS optimizations..."
    defaults write -g InitialKeyRepeat -int 15
    defaults write -g KeyRepeat -int 2
    ok "Faster key repeat enabled"

    defaults write com.apple.finder AppleShowAllFiles -bool true
    ok "Hidden files shown in Finder"

    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    ok ".DS_Store disabled on network volumes"

    killall Finder 2>/dev/null || true
    ok "macOS optimizations applied"
}

# --- SSH Server ---------------------------------------------------------------

enable_ssh() {
    if ! prompt_yes_no "Enable SSH (Remote Login)?"; then
        warn "Skipping SSH"
        return
    fi

    info "Enabling SSH..."
    if sudo systemsetup -getremotelogin | grep -q "On"; then
        ok "SSH already enabled"
    else
        sudo systemsetup -setremotelogin on
        ok "SSH enabled"
    fi
}

# --- Main ---------------------------------------------------------------------

main() {
    setup_passwordless_sudo
    install_homebrew
    install_dev_tools
    check_claude_code

    # Apply claude-kit configuration
    "$SCRIPT_DIR/install.sh"

    setup_git
    optimize_macos
    enable_ssh

    local O='\033[38;5;208m' W='\033[38;5;214m' B='\033[1m' N='\033[0m'
    echo ""
    echo -e "  ${O}${B}══════════════════════════════════════════${N}"
    echo -e "  ${O}${B}  Setup Complete!${N}"
    echo -e "  ${O}${B}══════════════════════════════════════════${N}"
    echo ""
    echo -e "  Next: ${W}source ~/.zshrc && claude-help${N}"
    echo ""
}

# Verify running from repo directory
if [[ ! -f "$SCRIPT_DIR/config/statusline-enhanced.sh" ]] || [[ ! -f "$SCRIPT_DIR/config/settings.json" ]]; then
    err "Please run this script from the claude-kit directory"
fi

main
