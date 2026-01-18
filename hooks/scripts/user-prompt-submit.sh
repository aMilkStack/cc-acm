#!/bin/bash
# Claudikins ACM - UserPromptSubmit hook
# Checks for threshold flag and injects handoff prompt context

INPUT=$(cat)

# Extract session info (same pattern as kernel)
if command -v jq &>/dev/null; then
    SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
else
    SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | sed 's/.*:"//;s/"//')
fi

[ -z "$SESSION_ID" ] && exit 0

# Load config
CONFIG="$HOME/.claude/claudikins-acm.conf"
[ -f "$CONFIG" ] && source "$CONFIG"
THRESHOLD="${THRESHOLD:-60}"
SNOOZE_DURATION="${SNOOZE_DURATION:-300}"

# Check flag files
FLAG_FILE="/tmp/acm-threshold-${SESSION_ID}"
SNOOZE_FILE="/tmp/acm-snooze-${SESSION_ID}"
DISMISSED_FILE="/tmp/acm-dismissed-${SESSION_ID}"
INPROGRESS_FILE="/tmp/acm-inprogress-${SESSION_ID}"

# Already dismissed this session?
[ -f "$DISMISSED_FILE" ] && exit 0

# Already handling a handoff request? (race condition prevention)
[ -f "$INPROGRESS_FILE" ] && exit 0

# Check snooze
if [ -f "$SNOOZE_FILE" ]; then
    snooze_until=$(cat "$SNOOZE_FILE")
    now=$(date +%s)
    [ "$now" -lt "$snooze_until" ] && exit 0
    rm -f "$SNOOZE_FILE"
fi

# No flag = no prompt needed
[ ! -f "$FLAG_FILE" ] && exit 0

# Read threshold % from flag file
PCT=$(cat "$FLAG_FILE" 2>/dev/null || echo "$THRESHOLD")

# Mark as in-progress to prevent race condition
touch "$INPROGRESS_FILE"

# Flag exists - inject context (same pattern as kernel execute-status.sh)
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "CONTEXT HANDOFF REQUIRED: Context usage at ${PCT}%. You MUST immediately use AskUserQuestion to ask the user:\\n\\nQuestion: 'Context at ${PCT}%. Generate handoff summary and start fresh?'\\nHeader: 'Handoff'\\nOptions:\\n  - 'Yes, handoff now' (Generate summary and open new session)\\n  - 'Snooze 5 min' (Ask again in 5 minutes)\\n  - 'Dismiss' (Don't ask again this session)\\n\\nAfter user responds, run these Bash commands:\\n- YES: bash \${CLAUDE_PLUGIN_ROOT}/scripts/run-handoff.sh && rm -f /tmp/acm-threshold-${SESSION_ID} /tmp/acm-inprogress-${SESSION_ID}\\n- SNOOZE: echo \\\"\$((\$(date +%s) + ${SNOOZE_DURATION}))\\\" > /tmp/acm-snooze-${SESSION_ID} && rm -f /tmp/acm-threshold-${SESSION_ID} /tmp/acm-inprogress-${SESSION_ID}\\n- DISMISS: touch /tmp/acm-dismissed-${SESSION_ID} && rm -f /tmp/acm-threshold-${SESSION_ID} /tmp/acm-inprogress-${SESSION_ID}\\n\\nThen proceed with the user's original prompt."
  }
}
EOF

exit 0
