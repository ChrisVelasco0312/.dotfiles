#!/usr/bin/env bash
set -euo pipefail

GEMINI_CLI_PATH="$HOME/.local/bin/gemini"

# Auto-install if not present or force update if --update flag is passed
if [ ! -f "$GEMINI_CLI_PATH" ] || [[ "$*" == *"--force-update"* ]]; then
  echo "Installing/updating gemini-cli..."
  gemini-cli-install
  # Remove --force-update from arguments if present
  set -- "${@/--force-update/}"
fi

# Execute the actual gemini CLI with all arguments
if [ -f "$GEMINI_CLI_PATH" ]; then
  exec "$GEMINI_CLI_PATH" "$@"
else
  echo "Error: gemini-cli installation failed"
  echo "Please run 'gemini-cli-install' manually or check your internet connection"
  exit 1
fi 