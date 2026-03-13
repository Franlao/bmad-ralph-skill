#!/bin/bash
#
# BMAD-Ralph Post-Edit Hook
# Auto-formats files after Claude edits them
# PostToolUse hooks receive tool result on stdin
# File path is extracted from CLAUDE_TOOL_INPUT env var or parsed from stdin
#

# Try to get file path from environment or parse from stdin
INPUT=$(cat -)
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"\K[^"]+' 2>/dev/null || echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

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
