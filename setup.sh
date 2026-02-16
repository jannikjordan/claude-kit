#!/usr/bin/env bash
# ==============================================================================
# claude-kit Setup - Cross-platform entry point
# Detects OS and runs the appropriate setup script
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
O='\033[38;5;208m'
B='\033[1m'
N='\033[0m'
R='\033[31m'

echo ""
echo -e "  ${O}${B}══════════════════════════════════════════${N}"
echo -e "  ${O}${B}  claude-kit Setup${N}"
echo -e "  ${O}${B}══════════════════════════════════════════${N}"
echo ""

case "$(uname -s)" in
    Darwin)
        echo -e "  ${O}Detected:${N} macOS"
        echo ""
        exec "$SCRIPT_DIR/setup-macos.sh"
        ;;
    Linux)
        echo -e "  ${O}Detected:${N} Linux"
        echo ""
        exec "$SCRIPT_DIR/setup-linux.sh"
        ;;
    *)
        echo -e "  ${R}Unsupported OS:${N} $(uname -s)"
        echo "  claude-kit supports macOS and Linux."
        exit 1
        ;;
esac
