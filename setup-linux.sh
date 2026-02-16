#!/usr/bin/env bash
# ==============================================================================
# Linux Setup for Claude Code (claude-kit)
# Prepares a Linux system for autonomous Claude Code development
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

install_package() {
    local pkg="$1"
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y "$pkg"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$pkg"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm "$pkg"
    elif command -v zypper &>/dev/null; then
        sudo zypper install -y "$pkg"
    else
        warn "No supported package manager found. Please install $pkg manually."
        return 1
    fi
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
            echo "${user} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/"$user" >/dev/null
            sudo chmod 440 /etc/sudoers.d/"$user"
            ok "Passwordless sudo enabled"
        else
            warn "Skipping passwordless sudo"
        fi
    fi
}

# --- Essential Dev Tools ------------------------------------------------------

install_dev_tools() {
    info "Installing essential development tools..."

    # Update package cache
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
    fi

    local packages=("git" "jq" "fzf" "curl")
    for pkg in "${packages[@]}"; do
        if command_exists "$pkg"; then
            ok "$pkg already installed"
        else
            install_package "$pkg"
            ok "$pkg installed"
        fi
    done

    # GitHub CLI (separate — different package name on some distros)
    if command_exists gh; then
        ok "gh already installed"
    else
        info "Installing GitHub CLI..."
        if command -v apt-get &>/dev/null; then
            # Official GitHub CLI repo for Debian/Ubuntu
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update -qq
            sudo apt-get install -y gh
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y gh
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm github-cli
        else
            warn "Please install GitHub CLI manually: https://cli.github.com"
        fi
        command_exists gh && ok "gh installed"
    fi
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

# --- SSH Server ---------------------------------------------------------------

enable_ssh() {
    if ! prompt_yes_no "Enable SSH server?"; then
        warn "Skipping SSH"
        return
    fi

    info "Enabling SSH..."
    if command_exists systemctl; then
        if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
            ok "SSH already running"
        else
            # Try sshd (Fedora/Arch) then ssh (Ubuntu/Debian)
            if systemctl list-unit-files sshd.service &>/dev/null; then
                sudo systemctl enable --now sshd
            elif systemctl list-unit-files ssh.service &>/dev/null; then
                sudo systemctl enable --now ssh
            else
                install_package openssh-server
                sudo systemctl enable --now ssh 2>/dev/null || sudo systemctl enable --now sshd 2>/dev/null
            fi
            ok "SSH enabled"
        fi
    else
        warn "systemctl not found — enable SSH manually"
    fi
}

# --- Main ---------------------------------------------------------------------

main() {
    setup_passwordless_sudo
    install_dev_tools
    check_claude_code

    # Apply claude-kit configuration
    "$SCRIPT_DIR/install.sh"

    setup_git
    enable_ssh

    local O='\033[38;5;208m' W='\033[38;5;214m' B='\033[1m' N='\033[0m'
    local shell_config
    case "$(basename "$SHELL")" in
        zsh)  shell_config="~/.zshrc" ;;
        bash) shell_config="~/.bashrc" ;;
        *)    shell_config="~/.profile" ;;
    esac

    echo ""
    echo -e "  ${O}${B}══════════════════════════════════════════${N}"
    echo -e "  ${O}${B}  Setup Complete!${N}"
    echo -e "  ${O}${B}══════════════════════════════════════════${N}"
    echo ""
    echo -e "  Next: ${W}source ${shell_config} && claude-help${N}"
    echo ""
}

# Verify running from repo directory
if [[ ! -f "$SCRIPT_DIR/config/statusline-enhanced.sh" ]] || [[ ! -f "$SCRIPT_DIR/config/settings.json" ]]; then
    err "Please run this script from the claude-kit directory"
fi

main
