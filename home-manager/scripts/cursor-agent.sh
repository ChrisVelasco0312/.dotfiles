#!/usr/bin/env bash
set -euo pipefail

CURSOR_CLI_PATH="$HOME/.local/bin/cursor-agent"

# Auto-install if not present or force update if --update flag is passed
if [ ! -f "$CURSOR_CLI_PATH" ] || [[ "$*" == *"--force-update"* ]]; then
  echo "Installing/updating cursor-cli..."
  cursor-cli-install
  # Remove --force-update from arguments if present
  set -- "${@/--force-update/}"
fi

# Execute the actual cursor-agent with all arguments
if [ -f "$CURSOR_CLI_PATH" ]; then
  exec "$CURSOR_CLI_PATH" "$@"
else
  echo "Error: cursor-cli installation failed"
  echo "Please run 'cursor-cli-install' manually or check your internet connection"
  exit 1
fi 