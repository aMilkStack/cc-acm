---
name: acm-handoff
description: Context handoff from a previous Claude Code session. Reads the handoff summary when context reached the configured threshold. Use this to understand what was being worked on and continue seamlessly.
---

# Context Handoff

This skill loads handoff content from a previous session that reached the context threshold.

## Instructions

When this skill is invoked:

1. **Read the handoff file** at `~/.claude/claudikins-acm/handoff.md`
2. **Present the summary** to understand what was being worked on
3. **Continue the work** from where it was left off

## Handoff Location

The handoff content is stored externally at:
```
~/.claude/claudikins-acm/handoff.md
```

Read this file to get the previous session's context.

## If No Handoff Exists

If the file doesn't exist or is empty, inform the user:
- No handoff is currently active
- A handoff is created when context usage hits the threshold (default 60%)
- They can trigger a manual handoff via the statusline

---

*Claudikins Automatic Context Manager*
*To configure settings, use: /acm:config*
