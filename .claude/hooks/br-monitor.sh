#!/bin/bash
#
# BMAD-Ralph Monitor Hook (PostToolUse)
#
# Logs tool activity to .bmad-ralph/logs/ so /br-debug and
# /br-metrics have raw data. Reads the hook payload JSON on stdin
# (tool_name + tool_input, per https://code.claude.com/docs/en/hooks.md).
# Never blocks anything — always exits 0.

# Only activate inside a BMAD-Ralph project (hooks run with cwd = project dir)
STATE_FILE=".bmad-ralph/state.json"
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/br-lib.sh"

BR_HOOK_INPUT=$(cat -)

LOG_DIR=".bmad-ralph/logs"
mkdir -p "$LOG_DIR"
MONITOR_LOG="$LOG_DIR/monitor.log"

TOOL_NAME=$(br_get_field "tool_name")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")

# Observed model — ground truth from the session transcript (every assistant
# message records the model that actually served it). This is how /br-metrics
# and the user VERIFY that per-phase model routing is really applied.
MODEL=""
TRANSCRIPT=$(br_get_field "transcript_path")
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] && command -v jq >/dev/null 2>&1; then
    MODEL=$(tail -c 200000 "$TRANSCRIPT" 2>/dev/null \
        | jq -r 'select(.message.model? // empty | length > 0) | .message.model' 2>/dev/null \
        | tail -1)
fi
MODEL_TAG=""
[ -n "$MODEL" ] && MODEL_TAG=" [model:$MODEL]"

case "$TOOL_NAME" in
    Bash)
        COMMAND=$(br_get_field "tool_input.command" | head -c 120)
        echo "[$TIMESTAMP]$MODEL_TAG BASH: $COMMAND" >> "$MONITOR_LOG"

        # tool_response is not guaranteed in the PostToolUse payload —
        # extract an exit code opportunistically if the field exists.
        EXIT_CODE=$(br_get_field "tool_response.exit_code")
        if [ -n "$EXIT_CODE" ] && [ "$EXIT_CODE" != "0" ]; then
            echo "[$TIMESTAMP] !! FAIL: exit $EXIT_CODE" >> "$MONITOR_LOG"
            echo "[$TIMESTAMP] $COMMAND → exit $EXIT_CODE" >> "$LOG_DIR/errors.log"
        fi
        ;;

    Edit|Write|NotebookEdit)
        FILE_PATH=$(br_get_field "tool_input.file_path")
        if [ -n "$FILE_PATH" ]; then
            echo "[$TIMESTAMP]$MODEL_TAG $TOOL_NAME: $FILE_PATH" >> "$MONITOR_LOG"
        fi
        ;;

    Agent|Task)
        DESC=$(br_get_field "tool_input.description")
        echo "[$TIMESTAMP]$MODEL_TAG AGENT: $DESC" >> "$MONITOR_LOG"
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
