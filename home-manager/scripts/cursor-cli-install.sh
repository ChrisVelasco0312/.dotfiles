#!/usr/bin/env bash
set -euo pipefail

CURSOR_CLI_DIR="$HOME/.local/bin"
CURSOR_CLI_PATH="$CURSOR_CLI_DIR/cursor-agent"

# Create directory if it doesn't exist
mkdir -p "$CURSOR_CLI_DIR"

# Check if cursor-agent exists and is recent (less than 7 days old)
if [ -f "$CURSOR_CLI_PATH" ]; then
  if [ $(find "$CURSOR_CLI_PATH" -mtime -7 2>/dev/null | wc -l) -gt 0 ]; then
    echo "cursor-cli is up to date (less than 7 days old)"
    exit 0
  fi
  echo "cursor-cli found but older than 7 days, updating..."
fi

echo "Installing/updating cursor-cli..."
# Use the official installation script
if command -v curl >/dev/null 2>&1; then
  curl https://cursor.com/install -fsS | bash
else
  echo "Error: curl is required but not found in PATH"
  exit 1
fi

echo "cursor-cli installation completed!" 