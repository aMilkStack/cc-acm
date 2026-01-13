#!/bin/bash
# Prompts user for handoff with Yes/No/Remind options
# Styled dialog matching Claude CLI aesthetic

TRANSCRIPT_PATH="$1"
SESSION_ID="$2"
FLAG_FILE="/tmp/handoff-triggered-${SESSION_ID}"
SNOOZE_FILE="/tmp/handoff-snooze-${SESSION_ID}"

# Load configuration (if exists)
CONFIG_FILE="$HOME/.claude/cc-acm.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Set defaults if not configured
THRESHOLD="${THRESHOLD:-60}"
SNOOZE_DURATION="${SNOOZE_DURATION:-300}"
SUMMARY_TOKENS="${SUMMARY_TOKENS:-500}"
DIALOG_STYLE="${DIALOG_STYLE:-vibrant}"

# Show styled dialog matching Claude aesthetic with vibrant cyberpunk vibes
RESULT=$(powershell.exe -Command "
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Colors based on dialog style (vibrant or minimal)
\$bgColor = [System.Drawing.Color]::FromArgb(24, 24, 27)
if ('$DIALOG_STYLE' -eq 'minimal') {
    \$fgColor = [System.Drawing.Color]::FromArgb(210, 210, 215)
    \$mutedColor = [System.Drawing.Color]::FromArgb(140, 140, 150)
    \$accentColor = [System.Drawing.Color]::FromArgb(217, 119, 87)
} else {
    # Vibrant colors matching the CC-ACM header aesthetic
    \$fgColor = [System.Drawing.Color]::FromArgb(230, 230, 235)
    \$mutedColor = [System.Drawing.Color]::FromArgb(160, 160, 170)
    \$accentColor = [System.Drawing.Color]::FromArgb(255, 140, 80)
}
\$pinkAccent = [System.Drawing.Color]::FromArgb(255, 120, 200)
\$btnBg = [System.Drawing.Color]::FromArgb(39, 39, 42)

\$form = New-Object System.Windows.Forms.Form
\$form.Text = 'Claude'
\$form.Size = New-Object System.Drawing.Size(420, 180)
\$form.StartPosition = 'CenterScreen'
\$form.FormBorderStyle = 'FixedDialog'
\$form.MaximizeBox = \$false
\$form.MinimizeBox = \$false
\$form.BackColor = \$bgColor
\$form.ForeColor = \$fgColor
\$form.TopMost = \$true

# Header
\$header = New-Object System.Windows.Forms.Label
\$header.Location = New-Object System.Drawing.Point(15, 15)
\$header.AutoSize = \$true
\$header.Text = 'CONTEXT ALERT ($THRESHOLD%)'
\$header.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 12)
\$header.ForeColor = \$accentColor
\$form.Controls.Add(\$header)

# Message
\$label = New-Object System.Windows.Forms.Label
\$label.Location = New-Object System.Drawing.Point(15, 45)
\$label.AutoSize = \$true
\$label.Text = 'Session context usage has reached $THRESHOLD%. Generate summary and open a fresh session?'
\$label.Font = New-Object System.Drawing.Font('Segoe UI', 10)
\$label.ForeColor = \$mutedColor
\$form.Controls.Add(\$label)

# Buttons
\$yesBtn = New-Object System.Windows.Forms.Button
\$yesBtn.Location = New-Object System.Drawing.Point(15, 90)
\$yesBtn.Size = New-Object System.Drawing.Size(120, 35)
\$yesBtn.Text = 'YES'
\$yesBtn.FlatStyle = 'Flat'
\$yesBtn.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
\$yesBtn.BackColor = \$accentColor
\$yesBtn.ForeColor = \$bgColor
\$yesBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
\$yesBtn.Add_Click({ \$form.Tag = 'Yes'; \$form.Close() })
\$form.Controls.Add(\$yesBtn)
\$form.AcceptButton = \$yesBtn

\$remindBtn = New-Object System.Windows.Forms.Button
\$remindBtn.Location = New-Object System.Drawing.Point(145, 90)
\$remindBtn.Size = New-Object System.Drawing.Size(120, 35)
\$remindBtn.Text = 'IN 5 MIN'
\$remindBtn.FlatStyle = 'Flat'
\$remindBtn.Font = New-Object System.Drawing.Font('Segoe UI', 9)
\$remindBtn.BackColor = \$btnBg
\$remindBtn.ForeColor = \$fgColor
\$remindBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
\$remindBtn.Add_Click({ \$form.Tag = 'Remind'; \$form.Close() })
\$form.Controls.Add(\$remindBtn)

\$noBtn = New-Object System.Windows.Forms.Button
\$noBtn.Location = New-Object System.Drawing.Point(275, 90)
\$noBtn.Size = New-Object System.Drawing.Size(120, 35)
\$noBtn.Text = 'DISMISS'
\$noBtn.FlatStyle = 'Flat'
\$noBtn.Font = New-Object System.Drawing.Font('Segoe UI', 9)
\$noBtn.BackColor = \$btnBg
\$noBtn.ForeColor = \$mutedColor
\$noBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
\$noBtn.Add_Click({ \$form.Tag = 'No'; \$form.Close() })
\$form.Controls.Add(\$noBtn)
\$form.CancelButton = \$noBtn

\$form.Add_Shown({\$form.Activate()})
[void]\$form.ShowDialog()
\$form.Tag
" 2>/dev/null | tr -d '\r')

case "$RESULT" in
    "Yes")
        # Continue with handoff
        ;;
    "Remind")
        # Set snooze for 5 minutes, remove the permanent flag
        rm -f "$FLAG_FILE"
        echo $(($(date +%s) + SNOOZE_DURATION)) > "$SNOOZE_FILE"
        exit 0
        ;;
    *)
        # No or closed - keep flag so we don't ask again
        exit 0
        ;;
esac

# Find transcript if not provided
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    # Use null-delimited find for paths with spaces
    TRANSCRIPT_PATH=$(find ~/.claude/projects -name "*.jsonl" -type f -printf '%T@\0%p\0' 2>/dev/null | \
        sort -z -n | tail -z -n 1 | cut -z -d$'\0' -f2 | tr -d '\0')
fi

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    powershell.exe -Command "[System.Windows.Forms.MessageBox]::Show('Could not find transcript file', 'Error', 'OK', 'Error')" 2>/dev/null
    exit 1
fi

# Show progress indicator
powershell.exe -Command "
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

\$progressForm = New-Object System.Windows.Forms.Form
\$progressForm.Text = 'CC-ACM'
\$progressForm.Size = New-Object System.Drawing.Size(400, 140)
\$progressForm.StartPosition = 'CenterScreen'
\$progressForm.FormBorderStyle = 'FixedDialog'
\$progressForm.MaximizeBox = \$false
\$progressForm.MinimizeBox = \$false
\$progressForm.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 27)
\$progressForm.TopMost = \$true

\$label = New-Object System.Windows.Forms.Label
\$label.Location = New-Object System.Drawing.Point(20, 30)
\$label.Size = New-Object System.Drawing.Size(360, 60)
\$label.Text = 'Generating handoff summary...`n`nThis might take a few seconds'
\$label.Font = New-Object System.Drawing.Font('Segoe UI', 10)
\$label.ForeColor = [System.Drawing.Color]::FromArgb(255, 140, 80)
\$label.TextAlign = 'MiddleCenter'
\$progressForm.Controls.Add(\$label)

\$progressForm.Show()
\$progressForm.Refresh()
" 2>/dev/null &
PROGRESS_PID=$!

# Extract conversation from JSONL
CONVERSATION=$(cat "$TRANSCRIPT_PATH" | grep -E '"type":"(user|assistant)"' | \
    python3 -c "
import sys, json
msgs = []
for line in sys.stdin:
    try:
        d = json.loads(line)
        role = d.get('type', '')
        content = d.get('message', {}).get('content', '')
        if isinstance(content, list):
            content = ' '.join([c.get('text', '') for c in content if isinstance(c, dict)])
        if role in ('user', 'assistant') and content:
            msgs.append(f'{role.upper()}: {content[:500]}')
    except (json.JSONDecodeError, KeyError, TypeError, ValueError):
        pass
print('\n'.join(msgs[-20:]))
" 2>/dev/null)

# Generate handoff via claude -p
HANDOFF=$(echo "$CONVERSATION" | claude -p "Generate a concise handoff summary (under $SUMMARY_TOKENS tokens) for continuing this conversation. Include: current task, progress made, next steps, key decisions. Format as markdown." 2>/dev/null)

# Close progress dialog
kill $PROGRESS_PID 2>/dev/null || true
pkill -f "CC-ACM.*progressForm" 2>/dev/null || true

if [ -z "$HANDOFF" ]; then
    powershell.exe -Command "[System.Windows.Forms.MessageBox]::Show('Failed to generate handoff', 'Error', 'OK', 'Error')" 2>/dev/null
    exit 1
fi

# Save handoff to skill file
HANDOFF_SKILL="$HOME/.claude/skills/acm-handoff/SKILL.md"
mkdir -p "$(dirname "$HANDOFF_SKILL")"

cat > "$HANDOFF_SKILL" << EOF
---
name: acm-handoff
description: Context handoff from a previous Claude Code session that reached $THRESHOLD% context usage. Use this to understand what was being worked on and continue seamlessly from where the previous session left off.
---

# Context Handoff from Previous Session

This session was started via CC-ACM (Claude Code Automatic Context Manager) after the previous session reached **$THRESHOLD% context usage**.

## Previous Session Summary

$HANDOFF

## How to Use This Context

- Review the summary above to understand what was being worked on
- Continue the work from where it was left off
- The summary was automatically generated to preserve context
- You now have a fresh context window with full headroom

---

*Handoff generated automatically by CC-ACM v1.0*
*To configure CC-ACM settings, use: /acm:config*
EOF

# Open new Warp tab with claude command using Warp URL scheme
# SessionStart hook will automatically detect and invoke the handoff
powershell.exe -Command "Start-Process 'warp://action/new_tab'" 2>/dev/null &

# Give Warp a moment to open the tab
sleep 0.5

# Type claude command in the new tab
powershell.exe -Command "
Add-Type -AssemblyName System.Windows.Forms
Start-Sleep -Milliseconds 300
[System.Windows.Forms.SendKeys]::SendWait('claude')
Start-Sleep -Milliseconds 100
[System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
" 2>/dev/null &
