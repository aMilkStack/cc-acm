#!/bin/bash
# Prompts user for handoff with Yes/No/Remind options
# Styled dialog matching Claude CLI aesthetic

TRANSCRIPT_PATH="$1"
SESSION_ID="$2"
FLAG_FILE="/tmp/handoff-triggered-${SESSION_ID}"
SNOOZE_FILE="/tmp/handoff-snooze-${SESSION_ID}"

# Show styled dialog matching Claude aesthetic
RESULT=$(powershell.exe -Command "
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Colors matching Claude/terminal dark theme
\$bgColor = [System.Drawing.Color]::FromArgb(24, 24, 27)
\$fgColor = [System.Drawing.Color]::FromArgb(210, 210, 215)
\$mutedColor = [System.Drawing.Color]::FromArgb(140, 140, 150)
\$accentColor = [System.Drawing.Color]::FromArgb(217, 119, 87)
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
\$header.Text = 'Context Handoff'
\$header.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 12)
\$header.ForeColor = \$accentColor
\$form.Controls.Add(\$header)

# Message
\$label = New-Object System.Windows.Forms.Label
\$label.Location = New-Object System.Drawing.Point(15, 45)
\$label.AutoSize = \$true
\$label.Text = 'Context at 60%. Start fresh with handoff?'
\$label.Font = New-Object System.Drawing.Font('Segoe UI', 10)
\$label.ForeColor = \$mutedColor
\$form.Controls.Add(\$label)

# Buttons - using AutoSize for reliable text fitting
\$yesBtn = New-Object System.Windows.Forms.Button
\$yesBtn.Location = New-Object System.Drawing.Point(15, 90)
\$yesBtn.Size = New-Object System.Drawing.Size(120, 35)
\$yesBtn.Text = 'Handoff'
\$yesBtn.FlatStyle = 'Flat'
\$yesBtn.Font = New-Object System.Drawing.Font('Segoe UI', 10)
\$yesBtn.BackColor = \$accentColor
\$yesBtn.ForeColor = \$bgColor
\$yesBtn.Add_Click({ \$form.Tag = 'Yes'; \$form.Close() })
\$form.Controls.Add(\$yesBtn)

\$remindBtn = New-Object System.Windows.Forms.Button
\$remindBtn.Location = New-Object System.Drawing.Point(145, 90)
\$remindBtn.Size = New-Object System.Drawing.Size(120, 35)
\$remindBtn.Text = 'In 5 min'
\$remindBtn.FlatStyle = 'Flat'
\$remindBtn.Font = New-Object System.Drawing.Font('Segoe UI', 10)
\$remindBtn.BackColor = \$btnBg
\$remindBtn.ForeColor = \$fgColor
\$remindBtn.Add_Click({ \$form.Tag = 'Remind'; \$form.Close() })
\$form.Controls.Add(\$remindBtn)

\$noBtn = New-Object System.Windows.Forms.Button
\$noBtn.Location = New-Object System.Drawing.Point(275, 90)
\$noBtn.Size = New-Object System.Drawing.Size(120, 35)
\$noBtn.Text = 'Dismiss'
\$noBtn.FlatStyle = 'Flat'
\$noBtn.Font = New-Object System.Drawing.Font('Segoe UI', 10)
\$noBtn.BackColor = \$btnBg
\$noBtn.ForeColor = \$fgColor
\$noBtn.Add_Click({ \$form.Tag = 'No'; \$form.Close() })
\$form.Controls.Add(\$noBtn)

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
        echo $(($(date +%s) + 300)) > "$SNOOZE_FILE"
        exit 0
        ;;
    *)
        # No or closed - keep flag so we don't ask again
        exit 0
        ;;
esac

# Find transcript if not provided
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    TRANSCRIPT_PATH=$(find ~/.claude/projects -name "*.jsonl" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
fi

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    powershell.exe -Command "[System.Windows.Forms.MessageBox]::Show('Could not find transcript file', 'Error', 'OK', 'Error')" 2>/dev/null
    exit 1
fi

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
    except: pass
print('\n'.join(msgs[-20:]))
" 2>/dev/null)

# Generate handoff via claude -p
HANDOFF=$(echo "$CONVERSATION" | claude -p "Generate a concise handoff summary (under 500 tokens) for continuing this conversation. Include: current task, progress made, next steps, key decisions. Format as markdown." 2>/dev/null)

if [ -z "$HANDOFF" ]; then
    powershell.exe -Command "[System.Windows.Forms.MessageBox]::Show('Failed to generate handoff', 'Error', 'OK', 'Error')" 2>/dev/null
    exit 1
fi

# Save handoff
echo "$HANDOFF" > /tmp/claude-handoff.txt

# Open new Warp tab with claude + handoff
powershell.exe -Command "
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport(\"user32.dll\")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport(\"user32.dll\")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
'@

\$proc = Get-Process warp | Where-Object { \$_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (\$proc) {
    [Win32]::ShowWindow(\$proc.MainWindowHandle, 9) | Out-Null
    Start-Sleep -Milliseconds 100
    [Win32]::SetForegroundWindow(\$proc.MainWindowHandle) | Out-Null
    Start-Sleep -Milliseconds 200

    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait('^+t')
    Start-Sleep -Milliseconds 500

    Set-Clipboard -Value 'claude --append-system-prompt \"\`$(cat /tmp/claude-handoff.txt)\"'
    [System.Windows.Forms.SendKeys]::SendWait('^v')
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
}
" 2>/dev/null
