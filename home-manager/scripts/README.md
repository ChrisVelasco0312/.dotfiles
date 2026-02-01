# Home Manager Scripts

This directory contains shell scripts that are used by the custom packages defined in `home.nix`.

## Scripts

### Cursor CLI
- `cursor-cli-install.sh` - Installation script for Cursor CLI
- `cursor-agent.sh` - Wrapper script for Cursor CLI execution

## Updating Cursor

**Cursor CLI** (the `cursor-agent` / `cursor-cli` binary in `~/.local/bin`):

- Run `cursor-cli-install`. It will install or update only if the binary is missing or older than 7 days.
- To force an update (e.g. when the binary is less than 7 days old), remove it and run the installer again:
  ```bash
  rm -f ~/.local/bin/cursor-agent && cursor-cli-install
  ```

**Cursor AppImage** (the GUI app in `~/Applications/Cursor.AppImage`):

- Updates are done by the systemd user service that re-downloads the latest AppImage. Run:
  ```bash
  systemctl --user start install-cursor
  ```
  The service is not enabled by default; run this whenever you want to refresh the AppImage.

## Usage

These scripts are automatically imported into the Nix packages using
`builtins.readFile` in the `home.nix` file. They are not meant to be executed
directly, but rather as part of the Nix package installation process.

## Benefits of this organization

1. **Better readability**: Scripts are properly indented and formatted
2. **Easier maintenance**: Each script can be edited independently
3. **Version control**: Changes to scripts are tracked separately
4. **Syntax highlighting**: IDEs can provide proper syntax highlighting for shell scripts
5. **Testing**: Scripts can be tested independently if needed 
