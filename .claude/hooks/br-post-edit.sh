#!/bin/bash
#
# BMAD-Ralph Post-Edit Hook (PostToolUse on Edit|Write)
#
# Auto-formats files after Claude edits them. Reads the hook payload JSON
# on stdin and takes the path from tool_input.file_path
# (https://code.claude.com/docs/en/hooks.md). Never fails the hook.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/br-lib.sh"

BR_HOOK_INPUT=$(cat -)

FILE_PATH=$(br_get_field "tool_input.file_path")

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Detect formatter and run it (silently, never fail the hook)
format_file() {
    if [ -f "node_modules/.bin/prettier" ] && [[ "$EXT" =~ ^(js|jsx|ts|tsx|css|scss|json|md|html|yaml|yml)$ ]]; then
        npx prettier --write "$FILE_PATH" 2>/dev/null || true
    elif [ -f "node_modules/.bin/biome" ] && [[ "$EXT" =~ ^(js|jsx|ts|tsx|json)$ ]]; then
        npx biome format --write "$FILE_PATH" 2>/dev/null || true
    elif command -v black &>/dev/null && [ "$EXT" = "py" ]; then
        black --quiet "$FILE_PATH" 2>/dev/null || true
    elif command -v rustfmt &>/dev/null && [ "$EXT" = "rs" ]; then
        rustfmt "$FILE_PATH" 2>/dev/null || true
    elif command -v gofmt &>/dev/null && [ "$EXT" = "go" ]; then
        gofmt -w "$FILE_PATH" 2>/dev/null || true
    fi
}

format_file
exit 0
