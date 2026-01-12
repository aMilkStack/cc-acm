#!/bin/bash
# Claude Handoff - Installation Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
STATUSLINE="$CLAUDE_DIR/statusline-command.sh"

echo "╭─────────────────────────────────────╮"
echo "│     Claude Handoff Installer        │"
echo "╰─────────────────────────────────────╯"
echo ""

# Create scripts directory if needed
mkdir -p "$SCRIPTS_DIR"

# Backup existing handoff script if present
if [ -f "$SCRIPTS_DIR/handoff-prompt.sh" ]; then
    echo "→ Backing up existing handoff-prompt.sh"
    cp "$SCRIPTS_DIR/handoff-prompt.sh" "$SCRIPTS_DIR/handoff-prompt.sh.bak"
fi

# Copy the handoff script
echo "→ Installing handoff-prompt.sh"
cp "$SCRIPT_DIR/scripts/handoff-prompt.sh" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/handoff-prompt.sh"

# Check if statusline needs patching
if [ -f "$STATUSLINE" ]; then
    if grep -q "handoff-prompt.sh" "$STATUSLINE"; then
        echo "→ Statusline already patched"
    else
        echo "→ Backing up statusline"
        cp "$STATUSLINE" "$STATUSLINE.bak"

        echo "→ Patching statusline for 60% trigger"
        # Add the handoff trigger after the 60% color setting
        sed -i "/ctx_color='\\\\033\[31m'/a\\
\\
        # Auto-trigger handoff at 60% (only once per session, with snooze support)\\
        session_id=\$(echo \"\$input\" | grep -o '\"session_id\":\"[^\"]*\"' | sed 's/.*:\"//;s/\"//')\\
        transcript=\$(echo \"\$input\" | grep -o '\"transcript_path\":\"[^\"]*\"' | sed 's/.*:\"//;s/\"//')\\
        flag_file=\"/tmp/handoff-triggered-\${session_id}\"\\
        snooze_file=\"/tmp/handoff-snooze-\${session_id}\"\\
\\
        should_trigger=false\\
        if [ -n \"\$session_id\" ]; then\\
            if [ -f \"\$snooze_file\" ]; then\\
                snooze_until=\$(cat \"\$snooze_file\")\\
                now=\$(date +%s)\\
                if [ \"\$now\" -ge \"\$snooze_until\" ]; then\\
                    rm -f \"\$snooze_file\"\\
                    should_trigger=true\\
                fi\\
            elif [ ! -f \"\$flag_file\" ]; then\\
                should_trigger=true\\
            fi\\
        fi\\
\\
        if [ \"\$should_trigger\" = true ]; then\\
            touch \"\$flag_file\"\\
            ~/.claude/scripts/handoff-prompt.sh \"\$transcript\" \"\$session_id\" \&\\
        fi" "$STATUSLINE"

        echo "→ Statusline patched"
    fi
else
    echo "⚠ No statusline found at $STATUSLINE"
    echo "  You'll need to manually add the trigger to your statusline"
fi

echo ""
echo "✓ Installation complete!"
echo ""
echo "The handoff dialog will appear when context reaches 60%."
echo "To test manually: ~/.claude/scripts/handoff-prompt.sh"
