# >>> CLAUDE CODE >>>
# Claude Kit — Long Commands + Short Aliases
# Works with bash and zsh on macOS and Linux

# --- Safe Mode Toggle ---
# Default: safe mode (no skip-permissions)
unalias claude 2>/dev/null || true
claude() {
    # "command claude" bypasses this function and runs the real binary
    if [[ -f ~/.claude/.yolo ]]; then
        command claude --dangerously-skip-permissions "$@"
    else
        command claude "$@"
    fi
}

claude-safe() {
    local O='\033[38;5;208m' G='\033[32m' R='\033[31m' D='\033[90m' B='\033[1m' N='\033[0m'
    case "$1" in
        on)
            rm -f ~/.claude/.yolo
            echo -e "${G}${B}Safe mode ON${N} ${D}- Claude will ask before risky actions${N}"
            ;;
        off)
            touch ~/.claude/.yolo
            echo -e "${R}${B}Safe mode OFF${N} ${D}- Claude has full permissions (--dangerously-skip-permissions)${N}"
            ;;
        *)
            if [[ -f ~/.claude/.yolo ]]; then
                echo -e "${O}${B}Current mode:${N} ${R}${B}YOLO${N} ${D}(skip-permissions)${N} - run ${O}claude-safe on${N} to enable safe mode"
            else
                echo -e "${O}${B}Current mode:${N} ${G}${B}SAFE${N} - run ${O}claude-safe off${N} to disable"
            fi
            ;;
    esac
}

# === LONG COMMANDS ===

claude-resume() {
    claude --continue
}

claude-sessions() {
    ~/.claude/claude-sessions.sh "$@"
}

claude-stats() {
    ~/.claude/claude-stats.sh "$@"
}

claude-new() {
    case "$1" in
        bug) claude -m "Help me debug. Steps: 1) Reproduce 2) Find cause 3) Fix" ;;
        refactor) claude -m "Help me refactor. Steps: 1) Analyze 2) Improve 3) Implement" ;;
        feature) claude -m "Help me build feature. Steps: 1) Requirements 2) Design 3) Build 4) Test" ;;
        test) claude -m "Help me write tests. Steps: 1) Test cases 2) Write tests" ;;
        review) claude -m "Review code for: quality, bugs, performance, security" ;;
        *) ~/.claude/claude-new.sh "$@" ;;
    esac
}

claude-branch() {
    ~/.claude/claude-branch.sh "$@"
}

claude-init() {
    ~/.claude/claude-init.sh "$@"
}

claude-move() {
    ~/.claude/claude-move.sh "$@"
}

claude-export() {
    ~/.claude/claude-export.sh "$@"
}

claude-import() {
    ~/.claude/claude-import.sh "$@"
}

claude-purge() {
    ~/.claude/claude-sessions.sh --purge "$@"
}

claude-mcp() {
    ~/.claude/claude-mcp.sh "$@"
}

# === HELP (colorful!) ===

claude-help() {
    local O='\033[38;5;208m' W='\033[38;5;214m' G='\033[32m' R='\033[31m' D='\033[90m' B='\033[1m' N='\033[0m'

    echo ""
    echo -e "  ${O}${B}╔══════════════════════════════════════════╗${N}"
    echo -e "  ${O}${B}║         CLAUDE CODE COMMANDS             ║${N}"
    echo -e "  ${O}${B}╚══════════════════════════════════════════╝${N}"
    echo ""

    # Safe mode status
    if [[ -f ~/.claude/.yolo ]]; then
        echo -e "  ${B}Permission mode:${N}  ${R}${B}YOLO${N} ${D}(skip-permissions)${N}"
        echo -e "  ${D}Switch to safe:${N}   ${O}claude-safe on${N}"
    else
        echo -e "  ${B}Permission mode:${N}  ${G}${B}SAFE${N} ${D}(asks before risky actions)${N}"
        echo -e "  ${D}Switch to yolo:${N}   ${O}claude-safe off${N}"
    fi
    echo ""

    echo -e "  ${O}${B}── Getting Started ──${N}"
    echo -e "  ${W}claude${N}                              ${D}Start a new session${N}"
    echo -e "  ${W}claude-resume${N}            ${O}cr${N}          ${D}Continue where you left off${N}"
    echo -e "  ${W}claude-sessions${N}          ${O}cs${N}          ${D}Pick a session to resume${N}"
    echo -e "  ${W}claude-sessions -a${N}       ${O}cs -a${N}       ${D}Browse ALL projects${N}"
    echo ""

    echo -e "  ${O}${B}── Quick Start Templates ──${N}"
    echo -e "  ${W}claude-new bug${N}           ${O}cn bug${N}      ${D}\"Help me debug this\"${N}"
    echo -e "  ${W}claude-new feature${N}       ${O}cn feature${N}  ${D}\"Help me build a feature\"${N}"
    echo -e "  ${W}claude-new refactor${N}      ${O}cn refactor${N} ${D}\"Help me refactor code\"${N}"
    echo -e "  ${W}claude-new test${N}          ${O}cn test${N}     ${D}\"Help me write tests\"${N}"
    echo -e "  ${W}claude-new review${N}        ${O}cn review${N}   ${D}\"Review my code\"${N}"
    echo ""

    echo -e "  ${O}${B}── Stats & Costs ──${N}"
    echo -e "  ${W}claude-stats${N}             ${O}cstat${N}       ${D}Current project stats${N}"
    echo -e "  ${W}claude-stats -a${N}          ${O}cstat -a${N}    ${D}All projects + per-model breakdown${N}"
    echo -e "  ${W}claude-stats --today${N}                 ${D}Last 24 hours only${N}"
    echo -e "  ${W}claude-stats --week${N}                  ${D}Last 7 days${N}"
    echo -e "  ${W}claude-stats --month${N}                 ${D}Last 30 days${N}"
    echo ""

    echo -e "  ${O}${B}── Git & Project ──${N}"
    echo -e "  ${W}claude-branch${N} ${O}<task>${N}     ${O}cbr${N}         ${D}Create branch from task name${N}"
    echo -e "  ${W}claude-init${N} ${O}<type>${N}                   ${D}Create CLAUDE.md (react/python/api)${N}"
    echo ""

    echo -e "  ${O}${B}── Session Management ──${N}"
    echo -e "  ${W}claude-move${N} ${O}<id>${N}                     ${D}Move session to another directory${N}"
    echo -e "  ${W}claude-export${N} ${O}<id>${N}                   ${D}Export session as backup${N}"
    echo -e "  ${W}claude-import${N} ${O}<file>${N}                 ${D}Import session from backup${N}"
    echo -e "  ${W}claude-purge${N}                           ${D}Delete empty sessions (0 messages)${N}"
    echo -e "  ${W}claude-purge -a${N}                        ${D}Purge empty sessions globally${N}"
    echo -e "  ${W}claude-mcp${N}                             ${D}Set up MCP servers${N}"
    echo -e "  ${W}claude-safe${N} ${O}[on|off]${N}                 ${D}Toggle permission mode${N}"
    echo ""
}

# === SHORT ALIASES ===

alias cr='claude-resume'
alias cs='claude-sessions'
alias cstat='claude-stats'
alias cn='claude-new'
alias cbr='claude-branch'
alias ch='claude-help'
# <<< CLAUDE CODE <<<
