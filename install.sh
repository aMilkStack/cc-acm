#!/bin/bash
# Claudikins Automatic Context Manager - Installation Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
STATUSLINE="$CLAUDE_DIR/statusline-command.sh"
STATE_DIR="$CLAUDE_DIR/claudikins-acm"

# Colors for output
ORANGE='\033[38;5;208m'
PINK='\033[38;5;205m'
GREEN='\033[38;5;120m'
CYAN='\033[38;5;51m'
GRAY='\033[38;5;240m'
RESET='\033[0m'
BOLD='\033[1m'

# ASCII art banner
echo -e "${ORANGE}${BOLD}"
cat << "EOF"
   ╔══════════════════════════════════════════════════════════════════╗
   ║  ██████╗██╗      █████╗ ██╗   ██╗██████╗ ██╗██╗  ██╗██╗███╗   ██╗║
   ║ ██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██║██║ ██╔╝██║████╗  ██║║
   ║ ██║     ██║     ███████║██║   ██║██║  ██║██║█████╔╝ ██║██╔██╗ ██║║
   ║ ██║     ██║     ██╔══██║██║   ██║██║  ██║██║██╔═██╗ ██║██║╚██╗██║║
   ║ ╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝██║██║  ██╗██║██║ ╚████║║
   ║  ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝║
   ║                    █████╗  ██████╗███╗   ███╗                    ║
   ║                   ██╔══██╗██╔════╝████╗ ████║                    ║
   ║                   ███████║██║     ██╔████╔██║                    ║
   ║                   ██╔══██║██║     ██║╚██╔╝██║                    ║
   ║                   ██║  ██║╚██████╗██║ ╚═╝ ██║                    ║
   ║                   ╚═╝  ╚═╝ ╚═════╝╚═╝     ╚═╝                    ║
   ║              ░▒▓ Automatic Context Manager ▓▒░                   ║
   ╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"
echo -e "${CYAN}    Installing Claudikins Automatic Context Manager for Claude Code CLI${RESET}"
echo ""

# Create directories
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$STATE_DIR"

# Backup existing handoff script if present
if [ -f "$SCRIPTS_DIR/handoff-prompt.sh" ]; then
    echo -e "${GRAY}→${RESET} Backing up existing handoff-prompt.sh"
    cp "$SCRIPTS_DIR/handoff-prompt.sh" "$SCRIPTS_DIR/handoff-prompt.sh.bak"
fi

# Copy the handoff script
echo -e "${GRAY}→${RESET} Installing handoff-prompt.sh"
if ! cp "$SCRIPT_DIR/scripts/handoff-prompt.sh" "$SCRIPTS_DIR/"; then
    echo -e "${PINK}✗${RESET} Failed to copy script"
    exit 1
fi
chmod +x "$SCRIPTS_DIR/handoff-prompt.sh"
echo -e "${GREEN}✓${RESET} Script installed"

# Install SessionStart hook
HOOKS_DIR="$CLAUDE_DIR/hooks"
SKILLS_DIR="$CLAUDE_DIR/skills"
mkdir -p "$HOOKS_DIR"
mkdir -p "$SKILLS_DIR/acm-handoff"

echo -e "${GRAY}→${RESET} Installing SessionStart hook"
cp "$SCRIPT_DIR/hooks/scripts/session-start.sh" "$HOOKS_DIR/session-start-acm.sh"
chmod +x "$HOOKS_DIR/session-start-acm.sh"
echo -e "${GREEN}✓${RESET} SessionStart hook installed"

# Install skills
cp "$SCRIPT_DIR/skills/acm-handoff/SKILL.md" "$SKILLS_DIR/acm-handoff/"
echo -e "${GREEN}✓${RESET} Handoff skill installed"

mkdir -p "$SKILLS_DIR/acm-config"
cp "$SCRIPT_DIR/skills/acm-config/SKILL.md" "$SKILLS_DIR/acm-config/"
echo -e "${GREEN}✓${RESET} Config skill installed"

# Install Warp launch configuration (if exists)
WARP_DIR="$HOME/.warp/launch_configurations"
WARP_CONFIG="$SCRIPT_DIR/.warp/launch_configurations/cc-acm-handoff.yaml"
if [ -f "$WARP_CONFIG" ]; then
    mkdir -p "$WARP_DIR"
    echo -e "${GRAY}→${RESET} Installing Warp launch configuration"
    cp "$WARP_CONFIG" "$WARP_DIR/claudikins-acm-handoff.yaml"
    echo -e "${GREEN}✓${RESET} Warp config installed"
fi

# Install retro statusline (includes Claudikins Automatic Context Manager trigger)
if [ -f "$STATUSLINE" ]; then
    echo -e "${GRAY}→${RESET} Backing up existing statusline"
    cp "$STATUSLINE" "$STATUSLINE.bak"
fi
echo -e "${GRAY}→${RESET} Installing Claudikins Automatic Context Manager statusline"
cp "$SCRIPT_DIR/scripts/statusline-command.sh" "$STATUSLINE"
chmod +x "$STATUSLINE"
echo -e "${GREEN}✓${RESET} Retro statusline installed"

echo ""
echo -e "${PINK}${BOLD}IMPORTANT:${RESET} Add the SessionStart hook to ~/.claude/settings.json:"
echo ""
echo -e "${GRAY}{"
echo -e "  \"hooks\": {"
echo -e "    \"SessionStart\": [{"
echo -e "      \"matcher\": \"startup\","
echo -e "      \"hooks\": [{"
echo -e "        \"type\": \"command\","
echo -e "        \"command\": \"~/.claude/hooks/session-start-acm.sh\""
echo -e "      }]"
echo -e "    }]"
echo -e "  }"
echo -e "}${RESET}"
echo ""
echo -e "${GREEN}${BOLD}✓ Installation complete!${RESET}"
echo ""
echo -e "${CYAN}The handoff dialog will appear when context reaches 60%.${RESET}"
echo -e "${GRAY}To test manually: ${RESET}~/.claude/scripts/handoff-prompt.sh"
echo ""
echo -e "${ORANGE}Happy coding!${RESET}"
