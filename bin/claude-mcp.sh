#!/usr/bin/env bash
# ==============================================================================
# MCP Server Quick Setup - Install common MCP servers
# ==============================================================================

server="${1:-}"

if [[ -z "$server" ]]; then
    echo "Usage: claude-mcp <server-name>"
    echo ""
    echo "Common MCP servers:"
    echo "  github      - GitHub integration (repos, issues, PRs)"
    echo "  filesystem  - Enhanced file operations"
    echo "  postgres    - PostgreSQL database access"
    echo "  sqlite      - SQLite database access"
    echo "  fetch       - Enhanced web fetching"
    echo "  brave       - Brave search integration"
    echo ""
    echo "Example: claude-mcp github"
    echo ""
    echo "Note: This is a placeholder. MCP server installation"
    echo "requires editing ~/.claude/mcp.json manually for now."
    echo ""
    echo "Learn more: https://modelcontextprotocol.io"
    exit 1
fi

echo "MCP Server setup for: $server"
echo ""
echo "To manually configure MCP servers:"
echo "  1. Edit ~/.claude/mcp.json"
echo "  2. Add server configuration"
echo "  3. Restart Claude Code"
echo ""
echo "Example configuration:"

case "$server" in
    github)
        cat <<'EOF'
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token-here"
      }
    }
  }
}
EOF
        ;;
    postgres)
        cat <<'EOF'
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://user:pass@localhost/dbname"
      }
    }
  }
}
EOF
        ;;
    *)
        echo "  (configuration varies by server)"
        echo ""
        echo "Check documentation: https://github.com/modelcontextprotocol/servers"
        ;;
esac
