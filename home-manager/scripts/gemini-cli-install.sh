#!/usr/bin/env bash
set -euo pipefail

GEMINI_CLI_DIR="$HOME/.local/bin"
GEMINI_CLI_PATH="$GEMINI_CLI_DIR/gemini"

# Create directory if it doesn't exist
mkdir -p "$GEMINI_CLI_DIR"

# Check if gemini exists and is recent (less than 7 days old)
if [ -f "$GEMINI_CLI_PATH" ]; then
  if [ $(find "$GEMINI_CLI_PATH" -mtime -7 2>/dev/null | wc -l) -gt 0 ]; then
    echo "gemini-cli is up to date (less than 7 days old)"
    exit 0
  fi
  echo "gemini-cli found but older than 7 days, updating..."
fi

echo "Installing/updating gemini-cli..."

# Fetch the latest release information
LATEST_RELEASE=$(curl -s https://api.github.com/repos/google-gemini/gemini-cli/releases/latest)
LATEST_VERSION=$(echo "$LATEST_RELEASE" | jq -r '.tag_name')
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | jq -r '.assets[0].browser_download_url')

if [ "$DOWNLOAD_URL" = "null" ] || [ -z "$DOWNLOAD_URL" ]; then
  echo "Error: Could not find download URL for latest release"
  exit 1
fi

echo "Downloading Gemini CLI version $LATEST_VERSION..."

# Download the latest version
if curl -L -o "$GEMINI_CLI_PATH.tmp" "$DOWNLOAD_URL"; then
  chmod +x "$GEMINI_CLI_PATH.tmp"
  mv "$GEMINI_CLI_PATH.tmp" "$GEMINI_CLI_PATH"
  echo "gemini-cli installation completed! Version: $LATEST_VERSION"
else
  echo "Error: Failed to download gemini-cli"
  rm -f "$GEMINI_CLI_PATH.tmp"
  exit 1
fi 