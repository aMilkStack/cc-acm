```
 ██████╗██╗      █████╗ ██╗   ██╗██████╗ ██╗██╗  ██╗██╗███╗   ██╗███████╗
██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██║██║ ██╔╝██║████╗  ██║██╔════╝
██║     ██║     ███████║██║   ██║██║  ██║██║█████╔╝ ██║██╔██╗ ██║███████╗
██║     ██║     ██╔══██║██║   ██║██║  ██║██║██╔═██╗ ██║██║╚██╗██║╚════██║
╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝██║██║  ██╗██║██║ ╚████║███████║
 ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝
                     █████╗  ██████╗███╗   ███╗
                    ██╔══██╗██╔════╝████╗ ████║
                    ███████║██║     ██╔████╔██║
                    ██╔══██║██║     ██║╚██╔╝██║
                    ██║  ██║╚██████╗██║ ╚═╝ ██║
                    ╚═╝  ╚═╝ ╚═════╝╚═╝     ╚═╝
            ░▒▓ Automatic Context Manager ▓▒░
```

Automatic context handoff for Claude Code. When context usage hits 60%, a dialog prompts you to generate a summary and continue in a fresh session.

**Requirements**: Claude Code CLI, WSL, Warp terminal, Python 3.

## What It Does

1. Statusline monitors context usage
2. At 60% (configurable), a dialog appears
3. Click YES - generates a summary via `claude -p`
4. Summary saved to `.claude/claudikins-acm/handoff.md` (project-local)
5. New Warp tab opens with `claude`
6. SessionStart hook auto-loads the handoff

## Installation

### As a Plugin (Recommended)

```bash
claude --plugin-dir /path/to/claudikins-acm
```

Or add to your project's `.claude/settings.json`:

```json
{
  "plugins": ["/path/to/claudikins-acm"]
}
```

### Manual Installation

```bash
./install.sh
```

## How It Works

```
Statusline runs every 300ms
    │
    └─ Context >= 60%?
           │
           YES → handoff-prompt.sh (background)
                    │
                    ├─ Dialog appears (retro ASCII style)
                    │
                    ├─ [YES] → claude -p generates summary
                    │          → Writes to .claude/claudikins-acm/handoff.md
                    │          → Opens new Warp tab
                    │          → SessionStart hook fires
                    │          → Claude auto-invokes /acm:handoff
                    │
                    ├─ [SNOOZE] → Asks again in 5 min (configurable)
                    │
                    └─ [DISMISS] → Won't ask again this session
```

## Plugin Structure

```
claudikins-acm/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── hooks/
│   ├── hooks.json            # SessionStart hook config
│   └── scripts/
│       └── session-start.sh  # Detects handoff, tells Claude to load it
├── skills/
│   ├── acm-config/           # /acm:config - interactive settings
│   └── acm-handoff/          # /acm:handoff - loads handoff content
├── scripts/
│   ├── handoff-prompt.sh     # Dialog + handoff generation
│   └── statusline-command.sh # Statusline with trigger logic
└── platforms/                # Platform-specific implementations
```

## Project-Local State

Handoff state is stored per-project, so handoffs only load in the same project:

```
your-project/
└── .claude/
    └── claudikins-acm/
        └── handoff.md        # Project-specific handoff content

~/.claude/
└── claudikins-acm.conf       # Global configuration
```

## Configuration

Use `/acm:config` in Claude for interactive setup, or edit `~/.claude/claudikins-acm.conf`:

```bash
THRESHOLD=60           # Context % to trigger (50-90)
SNOOZE_DURATION=300    # Seconds before re-prompting (60-3600)
SUMMARY_TOKENS=500     # Max tokens for summary (200-2000)
```

## Technical Details

**Dialog**: PowerShell WinForms, borderless with ASCII `░▒▓` borders. Retro palette.

**Warp Launch**: Uses SendKeys - focuses Warp, Ctrl+Shift+T for new tab, clipboard paste "claude", Enter.

**Hook**: Checks if `.claude/claudikins-acm/handoff.md` exists in the current project. If so, injects context telling Claude to immediately invoke `/acm:handoff`.

**Summary Generation**: Extracts recent conversation from transcript, includes git context if available, sends to `claude -p` for summarisation.

## Platform Support

Currently: WSL + Warp on Windows only.

The `platforms/` directory contains work-in-progress implementations for:
- macOS (AppleScript dialogs)
- Linux (Zenity dialogs)
- Generic (terminal-based fallback)

## Uninstall

```bash
./uninstall.sh
```

## Part of the Claudikins Framework

This is one component of the broader Claudikins ecosystem for Claude Code enhancement.
