# Home Manager Scripts

This directory contains shell scripts that are used by the custom packages defined in `home.nix`.

## Scripts

### Cursor CLI
- `cursor-cli-install.sh` - Installation script for Cursor CLI
- `cursor-agent.sh` - Wrapper script for Cursor CLI execution

### Gemini CLI
- `gemini-cli-install.sh` - Installation script for Gemini CLI
- `gemini.sh` - Wrapper script for Gemini CLI execution

## Usage

These scripts are automatically imported into the Nix packages using `builtins.readFile` in the `home.nix` file. They are not meant to be executed directly, but rather as part of the Nix package installation process.

## Benefits of this organization

1. **Better readability**: Scripts are properly indented and formatted
2. **Easier maintenance**: Each script can be edited independently
3. **Version control**: Changes to scripts are tracked separately
4. **Syntax highlighting**: IDEs can provide proper syntax highlighting for shell scripts
5. **Testing**: Scripts can be tested independently if needed 