<h1 align="center">claude-kit</h1>

<p align="center">
  <strong>Toolkit for Claude Code.</strong><br/>
  Long commands + short aliases. Session management. Cost tracking. Orange vibes.
</p>

---

<p align="center">
  <img src="https://img.shields.io/badge/Claude%20Code-Toolkit-E8720C?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJ3aGl0ZSI+PHBhdGggZD0iTTEyIDJDNi40OCAyIDIgNi40OCAyIDEyczQuNDggMTAgMTAgMTAgMTAtNC40OCAxMC0xMFMxNy41MiAyIDEyIDJ6Ii8+PC9zdmc+" alt="Claude Code Toolkit"/>
  <img src="https://img.shields.io/badge/macOS%20%2B%20Linux-Compatible-E8720C?logo=apple&logoColor=white" alt="macOS and Linux"/>
  <img src="https://img.shields.io/badge/bash%20%2B%20zsh-Shell-E8720C?logo=gnu-bash&logoColor=white" alt="bash and zsh"/>
</p>

## Statusline

3-line display with session and project tracking:
```
/Users/you/project (main *3) | Claude Opus 4 | Time: 14m (total: 2h 6m)
Tokens: 5.6K in  40.1K out  59.7M cache  = 59.8M total | Cost: $27.17 session  $68.42 project (6 sessions)
Context: ███████░░░░░░░░░░░░░ 36% | Code: +127 -34 | ID: abc-def-123
```

- Session tokens/cost = entire session file (across resumes)
- Project cost = all sessions in current project
- Session ID for use with export/move
- Cached for performance (10-30s)

## Install

**Config only** (no system changes, commands activate immediately):
```bash
git clone https://github.com/jannikjordan/claude-kit.git && cd claude-kit && source ./install.sh
```
> This only copies scripts to `~/.claude/` and adds aliases to your shell config. No root required.
> **Requires:** `jq` and `fzf` installed via your package manager.

---

**Full setup (macOS):**
```bash
git clone https://github.com/jannikjordan/claude-kit.git && cd claude-kit && ./setup.sh
```

**Full setup (Linux):**
```bash
git clone https://github.com/jannikjordan/claude-kit.git && cd claude-kit && ./setup.sh
```

> **Warning:** The full setup scripts make system-level changes. Each step is interactive and asks for confirmation, but review what they do before running:
>
> | Action | macOS | Linux |
> |--------|-------|-------|
> | Passwordless sudo | Appends to `/etc/sudoers` | Creates `/etc/sudoers.d/<user>` |
> | Package install | Homebrew + `git jq fzf gh` | apt/dnf/pacman + `git jq fzf curl gh` |
> | SSH server | `systemsetup -setremotelogin on` | `systemctl enable ssh/sshd` |
> | macOS tweaks | Faster key repeat, show hidden files, disable .DS_Store on network | N/A |
>
> **If you only want the Claude toolkit without system changes, use `source ./install.sh` instead.**

## Commands

| Command | Alias | What it does |
|---------|-------|--------------|
| `claude-resume` | `cr` | Resume last session |
| `claude-sessions` | `cs` | Browse sessions |
| `claude-sessions -a` | `cs -a` | Browse ALL projects |
| `claude-stats` | `cstat` | Current project stats |
| `claude-stats -a` | `cstat -a` | All projects + per-model breakdown |
| `claude-new <type>` | `cn` | Start from template (bug/feature/refactor/test/review) |
| `claude-branch <task>` | `cbr` | Create git branch from task name |
| `claude-export <id>` | | Export session as .tar.gz / .json / .md |
| `claude-import <file>` | | Import session from export |
| `claude-move <id>` | | Move session to another project |
| `claude-purge` | | Delete empty sessions (0 messages) |
| `claude-safe [on\|off]` | | Toggle permission mode |
| `claude-init <type>` | | Generate CLAUDE.md (react/python/api) |
| `claude-help` | `ch` | Show all commands |

## Safe Mode

```bash
claude-safe         # Show current mode
claude-safe on      # Safe (asks before risky actions)
claude-safe off     # YOLO (--dangerously-skip-permissions)
```

Default: **safe**. Toggle per machine — main Mac stays safe, dev Macs go YOLO.

## Stats

```bash
claude-stats              # Current project
claude-stats -a           # All projects + per-model breakdown
claude-stats --today      # Last 24 hours
claude-stats --week       # Last 7 days
claude-stats --month      # Last 30 days
```

Per-model table with Opus/Sonnet/Haiku breakdown, cost share %, and project ranking.

## Templates

```bash
claude-new bug         # Debug workflow
claude-new feature     # Build workflow
claude-new refactor    # Refactor workflow
claude-new test        # Test workflow
claude-new review      # Code review
```

## Agent Teams

Enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.

```bash
"Create a team with 3 agents to refactor the auth module"
```

Navigate: `Shift+Tab` switch modes, `Shift+Up/Down` talk to teammates.

## Project Config

**.claudeignore** — keep Claude fast:
```
node_modules/
dist/
build/
.git/
*.log
```

**CLAUDE.md** — tell Claude about your stack. Generate one with `claude-init react|python|api`.

## Update

```bash
cd claude-kit && git pull && source ./install.sh
```

## Uninstall

```bash
cd claude-kit && ./uninstall.sh
```

Removes all installed scripts, templates, hooks, shell aliases (from `~/.zshrc`, `~/.bashrc`, `~/.profile`), statusline cache, and restores your previous `settings.json`. Your `~/.claude/` directory (sessions, memory) is preserved.

> **Note:** The uninstall does **not** reverse system-level changes made by the full setup (passwordless sudo, SSH, macOS tweaks). To undo those, revert manually.

## Structure

```
bin/                Scripts (copied to ~/.claude/)
config/             Settings, statusline, shell config
  shell-snippet.sh  Shell integration
templates/          CLAUDE.md templates
hooks/              Git pre-commit hook
setup.sh            Platform detector
setup-macos.sh      macOS setup
setup-linux.sh      Linux setup
install.sh          Config-only install
```

---

<p align="center">
  <img src="https://img.shields.io/badge/Made_with-Claude_Code-E8720C?style=flat-square" alt="Made with Claude Code"/>
  <img src="https://img.shields.io/badge/Anthropic-orange?style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJ3aGl0ZSI+PHBhdGggZD0iTTEyIDJDNi40OCAyIDIgNi40OCAyIDEyczQuNDggMTAgMTAgMTAgMTAtNC40OCAxMC0xMFMxNy41MiAyIDEyIDJ6Ie8+PC9zdmc+" alt="Anthropic"/>
</p>
