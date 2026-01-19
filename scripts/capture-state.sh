#!/bin/bash
# Claudikins ACM - Capture structured state for handoff
# Mirrors kernel's preserve-state.sh pattern

PROJECT_DIR="${1:-.}"
TRANSCRIPT="${2:-}"
OUTPUT_FILE="$PROJECT_DIR/.claude/claudikins-acm/handoff-state.json"

mkdir -p "$(dirname "$OUTPUT_FILE")"

# Find transcript if not provided - scope to current project only
if [ -z "$TRANSCRIPT" ]; then
    # Derive transcript directory from project path
    # Claude Code stores transcripts in ~/.claude/projects/-path-to-project/
    PROJECT_DIR_NAME=$(echo "$PROJECT_DIR" | sed 's|^/|-|; s|/|-|g')
    TRANSCRIPT_DIR="$HOME/.claude/projects/$PROJECT_DIR_NAME"

    if [ -d "$TRANSCRIPT_DIR" ]; then
        TRANSCRIPT=$(find "$TRANSCRIPT_DIR" -maxdepth 1 -name "*.jsonl" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    fi
fi

# Export for Python
export TRANSCRIPT OUTPUT_FILE PROJECT_DIR

# Extract structured state
python3 << 'PYEOF'
import json
import sys
import os
from datetime import datetime

transcript_path = os.environ.get('TRANSCRIPT', '')
output_path = os.environ.get('OUTPUT_FILE', '')
project_dir = os.environ.get('PROJECT_DIR', '.')

state = {
    "version": "2.0",
    "created_at": datetime.now().isoformat(),
    "project_dir": os.path.abspath(project_dir),
    "transcript_path": transcript_path,
    "context": {
        "current_objective": "",
        "progress_summary": [],
        "active_todos": [],
        "recent_decisions": [],
        "key_files_modified": [],
        "next_steps": []
    }
}

# Parse transcript for context
if transcript_path and os.path.exists(transcript_path):
    todos = []
    files_modified = set()
    recent_messages = []

    with open(transcript_path, 'r') as f:
        for line in f:
            try:
                entry = json.loads(line)
                msg_type = entry.get('type', '')

                # Track todos
                if msg_type == 'tool_use' and entry.get('tool_name') == 'TodoWrite':
                    todo_input = entry.get('tool_input', {})
                    if 'todos' in todo_input:
                        todos = todo_input['todos']

                # Track file modifications
                if msg_type == 'tool_use' and entry.get('tool_name') in ['Write', 'Edit']:
                    fp = entry.get('tool_input', {}).get('file_path', '')
                    if fp:
                        files_modified.add(fp)

                # Track recent conversation
                if msg_type in ('user', 'assistant'):
                    content = entry.get('message', {}).get('content', '')
                    if isinstance(content, list):
                        content = ' '.join([c.get('text', '') for c in content if isinstance(c, dict)])
                    if content:
                        recent_messages.append({
                            'role': msg_type,
                            'content': content[:500]
                        })
                        recent_messages = recent_messages[-10:]

            except json.JSONDecodeError:
                continue

    # Extract current objective from first user message
    if recent_messages:
        for msg in recent_messages:
            if msg['role'] == 'user':
                state['context']['current_objective'] = msg['content'][:200]
                break

    # Active todos
    state['context']['active_todos'] = [
        t for t in todos if t.get('status') in ('pending', 'in_progress')
    ]

    # Files modified
    state['context']['key_files_modified'] = list(files_modified)[-10:]

# Git context
try:
    import subprocess
    branch = subprocess.check_output(['git', 'branch', '--show-current'],
                                     cwd=project_dir, stderr=subprocess.DEVNULL).decode().strip()
    state['git'] = {'branch': branch}

    status = subprocess.check_output(['git', 'status', '--short'],
                                     cwd=project_dir, stderr=subprocess.DEVNULL).decode().strip()
    state['git']['modified_files'] = status.split('\n')[:5] if status else []
except:
    pass

# Write output
with open(output_path, 'w') as f:
    json.dump(state, f, indent=2)

print(f"State captured to {output_path}")
PYEOF

echo "$OUTPUT_FILE"
