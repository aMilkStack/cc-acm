#!/bin/bash
# Prompts user for handoff with Yes/No/Remind options
# Styled dialog matching Claude CLI aesthetic

TRANSCRIPT_PATH="$1"
SESSION_ID="$2"
FLAG_FILE="/tmp/handoff-triggered-${SESSION_ID}"
SNOOZE_FILE="/tmp/handoff-snooze-${SESSION_ID}"

# Load configuration (if exists)
CONFIG_FILE="$HOME/.claude/claudikins-acm.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Set defaults if not configured
THRESHOLD="${THRESHOLD:-60}"
SNOOZE_DURATION="${SNOOZE_DURATION:-300}"
SUMMARY_TOKENS="${SUMMARY_TOKENS:-500}"
DIALOG_STYLE="${DIALOG_STYLE:-vibrant}"

# Show retro ASCII styled dialog matching Claudikins Automatic Context Manager statusline aesthetic
RESULT=$(powershell.exe -Command "
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Retro palette (matching Claudikins Automatic Context Manager pixel art header)
\$darkBg = [System.Drawing.Color]::FromArgb(46, 44, 59)        # #2e2c3b
\$darkGray = [System.Drawing.Color]::FromArgb(62, 65, 95)      # #3e415f
\$medGray = [System.Drawing.Color]::FromArgb(85, 96, 125)      # #55607d
\$mint = [System.Drawing.Color]::FromArgb(65, 222, 149)        # #41de95
\$teal = [System.Drawing.Color]::FromArgb(42, 164, 170)        # #2aa4aa
\$orange = [System.Drawing.Color]::FromArgb(196, 101, 28)      # #c4651c
\$rust = [System.Drawing.Color]::FromArgb(181, 65, 49)         # #b54131
\$pink = [System.Drawing.Color]::FromArgb(234, 97, 157)        # #ea619d
\$ice = [System.Drawing.Color]::FromArgb(193, 229, 234)        # #c1e5ea

\$form = New-Object System.Windows.Forms.Form
\$form.Text = 'Claudikins Automatic Context Manager'
\$form.Size = New-Object System.Drawing.Size(460, 200)
\$form.StartPosition = 'CenterScreen'
\$form.FormBorderStyle = 'None'
\$form.BackColor = \$darkBg
\$form.ForeColor = \$ice
\$form.TopMost = \$true

# Custom border panel
\$borderPanel = New-Object System.Windows.Forms.Panel
\$borderPanel.Location = New-Object System.Drawing.Point(0, 0)
\$borderPanel.Size = \$form.Size
\$borderPanel.BackColor = \$darkBg
\$form.Controls.Add(\$borderPanel)

# ASCII top border ░▒▓
\$topBorder = New-Object System.Windows.Forms.Label
\$topBorder.Location = New-Object System.Drawing.Point(0, 0)
\$topBorder.Size = New-Object System.Drawing.Size(460, 25)
\$topBorder.Text = '░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░'
\$topBorder.Font = New-Object System.Drawing.Font('Consolas', 10)
\$topBorder.ForeColor = \$orange
\$topBorder.TextAlign = 'MiddleCenter'
\$borderPanel.Controls.Add(\$topBorder)

# Header with pink accent
\$header = New-Object System.Windows.Forms.Label
\$header.Location = New-Object System.Drawing.Point(20, 32)
\$header.AutoSize = \$true
\$header.Text = '▓ CONTEXT ALERT ▓ $THRESHOLD% ▓'
\$header.Font = New-Object System.Drawing.Font('Consolas', 14, [System.Drawing.FontStyle]::Bold)
\$header.ForeColor = \$pink
\$borderPanel.Controls.Add(\$header)

# Message with teal
\$label = New-Object System.Windows.Forms.Label
\$label.Location = New-Object System.Drawing.Point(20, 65)
\$label.Size = New-Object System.Drawing.Size(420, 40)
\$label.Text = 'Session running hot. Generate handoff summary and open fresh session?'
\$label.Font = New-Object System.Drawing.Font('Consolas', 10)
\$label.ForeColor = \$teal
\$borderPanel.Controls.Add(\$label)

# Buttons with retro styling
\$yesBtn = New-Object System.Windows.Forms.Button
\$yesBtn.Location = New-Object System.Drawing.Point(20, 115)
\$yesBtn.Size = New-Object System.Drawing.Size(130, 40)
\$yesBtn.Text = '▓ YES ▓'
\$yesBtn.FlatStyle = 'Flat'
\$yesBtn.Font = New-Object System.Drawing.Font('Consolas', 11, [System.Drawing.FontStyle]::Bold)
\$yesBtn.BackColor = \$darkGray
\$yesBtn.ForeColor = \$mint
\$yesBtn.FlatAppearance.BorderColor = \$mint
\$yesBtn.FlatAppearance.BorderSize = 2
\$yesBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
\$yesBtn.Add_Click({ \$form.Tag = 'Yes'; \$form.Close() })
\$borderPanel.Controls.Add(\$yesBtn)
\$form.AcceptButton = \$yesBtn

\$remindBtn = New-Object System.Windows.Forms.Button
\$remindBtn.Location = New-Object System.Drawing.Point(165, 115)
\$remindBtn.Size = New-Object System.Drawing.Size(130, 40)
\$remindBtn.Text = '▓ SNOOZE ▓'
\$remindBtn.FlatStyle = 'Flat'
\$remindBtn.Font = New-Object System.Drawing.Font('Consolas', 11)
\$remindBtn.BackColor = \$darkGray
\$remindBtn.ForeColor = \$teal
\$remindBtn.FlatAppearance.BorderColor = \$teal
\$remindBtn.FlatAppearance.BorderSize = 2
\$remindBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
\$remindBtn.Add_Click({ \$form.Tag = 'Remind'; \$form.Close() })
\$borderPanel.Controls.Add(\$remindBtn)

\$noBtn = New-Object System.Windows.Forms.Button
\$noBtn.Location = New-Object System.Drawing.Point(310, 115)
\$noBtn.Size = New-Object System.Drawing.Size(130, 40)
\$noBtn.Text = '▓ DISMISS ▓'
\$noBtn.FlatStyle = 'Flat'
\$noBtn.Font = New-Object System.Drawing.Font('Consolas', 11)
\$noBtn.BackColor = \$darkGray
\$noBtn.ForeColor = \$rust
\$noBtn.FlatAppearance.BorderColor = \$rust
\$noBtn.FlatAppearance.BorderSize = 2
\$noBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
\$noBtn.Add_Click({ \$form.Tag = 'No'; \$form.Close() })
\$borderPanel.Controls.Add(\$noBtn)
\$form.CancelButton = \$noBtn

# ASCII bottom border
\$bottomBorder = New-Object System.Windows.Forms.Label
\$bottomBorder.Location = New-Object System.Drawing.Point(0, 170)
\$bottomBorder.Size = New-Object System.Drawing.Size(460, 25)
\$bottomBorder.Text = '░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░'
\$bottomBorder.Font = New-Object System.Drawing.Font('Consolas', 10)
\$bottomBorder.ForeColor = \$orange
\$bottomBorder.TextAlign = 'MiddleCenter'
\$borderPanel.Controls.Add(\$bottomBorder)

# Allow dragging borderless window
\$form.Add_MouseDown({ \$script:dragging = \$true; \$script:dragStart = [System.Windows.Forms.Cursor]::Position })
\$form.Add_MouseMove({ if (\$script:dragging) { \$p = [System.Windows.Forms.Cursor]::Position; \$form.Location = New-Object System.Drawing.Point((\$form.Location.X + \$p.X - \$script:dragStart.X), (\$form.Location.Y + \$p.Y - \$script:dragStart.Y)); \$script:dragStart = \$p } })
\$form.Add_MouseUp({ \$script:dragging = \$false })

\$form.Add_Shown({\$form.Activate()})
[void]\$form.ShowDialog()
\$form.Tag
" 2>&1 | tr -d '\r')

# Check if dialog failed to open
if [ -z "$RESULT" ]; then
    echo "Claudikins Automatic Context Manager: Dialog failed to open. Check PowerShell/WinForms availability." >&2
    exit 1
fi

case "$RESULT" in
    "Yes")
        # Continue with handoff
        ;;
    "Remind")
        # Set snooze for configured duration, remove the permanent flag
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

# Cleanup function for progress dialog
cleanup_progress() {
    kill $PROGRESS_PID 2>/dev/null || true
}
trap cleanup_progress EXIT

# Show progress indicator
powershell.exe -Command "
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

\$progressForm = New-Object System.Windows.Forms.Form
\$progressForm.Text = 'Claudikins Automatic Context Manager'
\$progressForm.Size = New-Object System.Drawing.Size(400, 140)
\$progressForm.StartPosition = 'CenterScreen'
\$progressForm.FormBorderStyle = 'FixedDialog'
\$progressForm.MaximizeBox = \$false
\$progressForm.MinimizeBox = \$false
\$progressForm.BackColor = [System.Drawing.Color]::FromArgb(46, 44, 59)  # #2e2c3b
\$progressForm.TopMost = \$true

\$label = New-Object System.Windows.Forms.Label
\$label.Location = New-Object System.Drawing.Point(20, 30)
\$label.Size = New-Object System.Drawing.Size(360, 60)
\$label.Text = 'Generating handoff summary...`n`nThis might take a few seconds'
\$label.Font = New-Object System.Drawing.Font('Segoe UI', 10)
\$label.ForeColor = [System.Drawing.Color]::FromArgb(196, 101, 28)  # #c4651c orange
\$label.TextAlign = 'MiddleCenter'
\$progressForm.Controls.Add(\$label)

\$progressForm.Show()
\$progressForm.Refresh()
" 2>/dev/null &
PROGRESS_PID=$!

# Gather context for handoff
# 1. Extract recent conversation (smarter truncation)
CONVERSATION=$(cat "$TRANSCRIPT_PATH" | grep -E '"type":"(user|assistant)"' | \
    python3 -c "
import sys, json
msgs = []
total_chars = 0
MAX_CHARS = 15000  # ~3-4k tokens worth of context

for line in sys.stdin:
    try:
        d = json.loads(line)
        role = d.get('type', '')
        content = d.get('message', {}).get('content', '')
        if isinstance(content, list):
            content = ' '.join([c.get('text', '') for c in content if isinstance(c, dict)])
        if role in ('user', 'assistant') and content:
            msgs.append((role, content))
    except (json.JSONDecodeError, KeyError, TypeError, ValueError):
        pass

# Take recent messages up to MAX_CHARS
recent = []
for role, content in reversed(msgs):
    if total_chars + len(content) > MAX_CHARS:
        break
    recent.insert(0, f'{role.upper()}: {content}')
    total_chars += len(content)

print('\n\n'.join(recent))
" 2>/dev/null)

# 2. Get git context if available
GIT_CONTEXT=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    GIT_STATUS=$(git status --short 2>/dev/null | head -20)
    GIT_RECENT=$(git log --oneline -5 2>/dev/null)

    if [ -n "$GIT_STATUS" ] || [ -n "$GIT_RECENT" ]; then
        GIT_CONTEXT="

GIT CONTEXT:
Branch: $GIT_BRANCH

Modified files:
$GIT_STATUS

Recent commits:
$GIT_RECENT
"
    fi
fi

# 3. Generate handoff with improved prompt
CLAUDE_STDERR=$(mktemp)
HANDOFF=$(cat << EOF | claude -p 2>"$CLAUDE_STDERR"
You are generating a handoff summary for a developer who reached their context limit and needs to continue in a fresh session.

Analyze the conversation below and create a strategic handoff summary (under $SUMMARY_TOKENS tokens) that includes:

1. **Current Objective** - What is the main goal/task being worked on?
2. **Progress So Far** - What has been accomplished? What works?
3. **Active Work** - What was being done right before the handoff?
4. **Key Decisions** - Important architectural or implementation decisions made
5. **Next Steps** - Concrete actions to take when resuming
6. **Context to Remember** - Patterns, conventions, or constraints established

Format as clear, scannable markdown. Be specific and actionable.

CONVERSATION:
$CONVERSATION
$GIT_CONTEXT
EOF
)

# Close progress dialog (trap handles cleanup on exit)
cleanup_progress

if [ -z "$HANDOFF" ]; then
    ERROR_DETAIL=""
    if [ -s "$CLAUDE_STDERR" ]; then
        ERROR_DETAIL=$(head -c 200 "$CLAUDE_STDERR")
    fi
    rm -f "$CLAUDE_STDERR"

    powershell.exe -Command "[System.Windows.Forms.MessageBox]::Show('Failed to generate handoff.`n`n$ERROR_DETAIL', 'Claudikins Automatic Context Manager Error', 'OK', 'Error')" 2>/dev/null
    exit 1
fi
rm -f "$CLAUDE_STDERR"

# Save handoff to external state file (outside plugin)
HANDOFF_STATE="$HOME/.claude/claudikins-acm/handoff.md"
mkdir -p "$(dirname "$HANDOFF_STATE")"

cat > "$HANDOFF_STATE" << EOF
# Context Handoff from Previous Session

This session was started via Claudikins Automatic Context Manager after the previous session reached **$THRESHOLD% context usage**.

## Previous Session Summary

$HANDOFF

## How to Use This Context

- Review the summary above to understand what was being worked on
- Continue the work from where it was left off
- The summary was automatically generated to preserve context
- You now have a fresh context window with full headroom

---

*Handoff generated automatically by Claudikins Automatic Context Manager v1.0*
*To configure Claudikins Automatic Context Manager settings, use: /acm:config*
EOF

# Open new Warp tab and launch Claude using SendKeys
# SessionStart hook will automatically detect and invoke the handoff
powershell.exe -Command "
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

# Check if Warp is already running (get one with a window)
\$warp = Get-Process -Name 'warp' -ErrorAction SilentlyContinue | Where-Object { \$_.MainWindowTitle -ne '' } | Select-Object -First 1

if (\$warp) {
    # Warp running - focus it and open new tab
    [Microsoft.VisualBasic.Interaction]::AppActivate(\$warp.Id)
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait('^+t')  # Ctrl+Shift+T for new tab
    Start-Sleep -Milliseconds 800  # Wait for new tab to be ready
} else {
    # Warp not running - start it
    \$warp = Start-Process 'C:\Users\User\AppData\Local\Programs\Warp\warp.exe' -PassThru
    Start-Sleep -Seconds 3
    [Microsoft.VisualBasic.Interaction]::AppActivate(\$warp.Id)
}

Start-Sleep -Milliseconds 500
Set-Clipboard -Value 'claude'
[System.Windows.Forms.SendKeys]::SendWait('^v')  # Ctrl+V paste
[System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
" 2>/dev/null || {
    echo "Claudikins Automatic Context Manager: Handoff saved to ~/.claude/claudikins-acm/handoff.md" >&2
    echo "Claudikins Automatic Context Manager: Start a new Claude session and use /acm:handoff to continue" >&2
}
