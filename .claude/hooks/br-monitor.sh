#!/bin/bash
#
# BMAD-Ralph Monitor Hook
# Runs AFTER every tool use to track progress and detect issues
# Hook type: PostToolUse (all tools)
#

# Only activate if this is a BMAD-Ralph project
STATE_FILE=".bmad-ralph/state.json"
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

LOG_DIR=".bmad-ralph/logs"
mkdir -p "$LOG_DIR"

MONITOR_LOG="$LOG_DIR/monitor.log"
TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")

# Read tool input from stdin
INPUT=$(cat -)

# Extract relevant info based on tool type
case "$TOOL_NAME" in
    Bash)
        # Extract command from input
        COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//' | head -c 100)
        echo "[$TIMESTAMP] BASH: $COMMAND" >> "$MONITOR_LOG"

        # Detect test/build failures from exit codes
        EXIT_CODE=$(echo "$INPUT" | grep -o '"exit_code"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed 's/.*:[[:space:]]*//')
        if [ -n "$EXIT_CODE" ] && [ "$EXIT_CODE" != "0" ]; then
            echo "[$TIMESTAMP] !! FAIL: Command exited with code $EXIT_CODE" >> "$MONITOR_LOG"

            # Write to a separate error log for quick scanning
            echo "[$TIMESTAMP] $COMMAND → exit $EXIT_CODE" >> "$LOG_DIR/errors.log"
        fi
        ;;

    Edit|Write)
        # Track file modifications
        FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')
        if [ -n "$FILE_PATH" ]; then
            echo "[$TIMESTAMP] $TOOL_NAME: $FILE_PATH" >> "$MONITOR_LOG"
        fi
        ;;

    Agent)
        # Track subagent launches
        DESC=$(echo "$INPUT" | grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"description"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')
        echo "[$TIMESTAMP] AGENT: $DESC" >> "$MONITOR_LOG"
        ;;
esac

# Keep monitor log under 500 lines (rotate)
if [ -f "$MONITOR_LOG" ]; then
    LINE_COUNT=$(wc -l < "$MONITOR_LOG" 2>/dev/null || echo 0)
    if [ "$LINE_COUNT" -gt 500 ]; then
        tail -300 "$MONITOR_LOG" > "$MONITOR_LOG.tmp"
        mv "$MONITOR_LOG.tmp" "$MONITOR_LOG"
    fi
fi

exit 0
