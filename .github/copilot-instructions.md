# GitHub Copilot Instructions for this Repo

## Build / apply configuration

- Preferred: `make build` – runs `sudo nixos-rebuild switch --flake .#nixos --impure` and then `make home`.
- Home only: `make home` – installs Home Manager if missing, then `home-manager switch --flake .#cavelasco@nixos --impure`.
- System only: `make flake`.
- Upgrade: `make update` or `make update-safe`.
- Maintenance: `make backup-configs`, `make clean`, `make wallpaper-fix`.

## Tests and linting

- No repository-level automated tests. Validate changes by successfully running `make build` and `make home`.
- For Java projects following `docs/java-development-workflow.md`:
  - All tests: `mvn test`
  - Single test class: `mvn test -Dtest=MyTestClass`
  - Single test method: `mvn test -Dtest=MyTestClass#testMethod`
- For C/C++ projects following `docs/cpp-development-workflow.md`:
  - Configure + build: `cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && cmake --build build`
- Prefer existing tools when suggesting linters/formatters:
  - Python: `ruff`, `mypy`, `black`, `isort`.
  - JS/TS: `prettier`, `eslint`, `typescript-language-server`.

## High-level architecture

- `flake.nix` is the single entrypoint. It defines:
  - `nixosConfigurations.nixos` using modules `./nixos/configuration.nix` and `./nixos/hyprland.nix` plus an overlay enabling `nixd`.
  - `homeConfigurations."cavelasco@nixos"` using `./home-manager/home.nix`.
- `nixos/`:
  - `configuration.nix` – main NixOS system config (boot, filesystems, NVIDIA, networking, audio, database services, VM helpers, etc.).
  - `hyprland.nix` – Hyprland desktop, portals, fonts, and related environment variables.
- `home-manager/home.nix`:
  - Defines overlays (e.g. `own-lualine-nvim` from flake input `plugin-lualine`, `cursor-cli` from `home-manager/scripts`).
  - Configures user-level environment (`home.*`, `gtk.*`, Hyprland-specific options).
  - Imports program modules under `home-manager/programs/*` (e.g. `neovim`, `tmux`, `rofi`, `firefox`).
- `home-manager/programs/*`:
  - Each directory is a focused Home Manager module.
  - `neovim/default.nix` wires the entire Neovim Lua config (`nvim-lua/*`) and plugins (incl. `copilot-vim`, `nvim-jdtls`, `nvim-dap`).
  - `tmux/tmux.nix` configures tmux and packages plugins via `tmuxPlugins.mkTmuxPlugin`.
- `dots/`:
  - Non-Nix configs and scripts for Hyprland and related tools.
  - `dots/hypr/wallpaper-picker.py` integrates Tidal/Last.fm with wallpaper selection and relies on `.dotfiles/.env` for credentials.
- `docs/`:
  - Workflow docs for C/C++, Java, and GPU passthrough / Windows VM.
- `node-shells/shell.nix`:
  - Node.js 20 development shell that adds `node_modules/.bin` to `PATH`. Prefer this for Node-centric work in this repo.

## Key conventions

### Nix / Home Manager modules

- For new user-level programs, create a module under `home-manager/programs/<name>` and add it to the `imports` list in `home-manager/home.nix`.
- For new system-level config, extend `nixos/configuration.nix` or add a new module and include it in `flake.nix`’s `nixosConfigurations.nixos.modules` list.

### Custom overlays and plugins

- Reuse the overlay pattern in `home-manager/home.nix` for custom packages:
  - Example: `own-lualine-nvim` built from flake input `plugin-lualine` and exposed as `pkgs.vimPlugins.own-lualine-nvim`.
  - Example: `cursor-cli` built from scripts in `home-manager/scripts` and wrapped using `makeWrapper`.
- Prefer embedding shell/Lua configs via `builtins.readFile` (and helpers like `toLuaFile`) instead of large inline strings.

### Secrets and environment

- Secrets and API keys live in `.dotfiles/.env` and are parsed in both Nix (`home-manager/home.nix`’s `env` attr) and Python (`dots/hypr/wallpaper-picker.py`’s `load_env`).
- Treat any `env.*` lookups (e.g. `env.LASTFM_APIKEY`) and values read from `.env` as secrets:
  - Do not hardcode or log them.
  - Never commit `.env`.
- When adding new secret-backed session variables, follow the `env.FOO or ""` pattern to keep missing keys optional.

### Editor and AI tooling

- Neovim is configured declaratively via `home-manager/programs/neovim/default.nix` and `nvim-lua/*`:
  - Add/remove plugins in the `plugins` list and keep their Lua configs under `nvim-lua/plugins/*.lua`, loaded with `builtins.readFile`.
  - LSP/DAP for C/C++ (clangd, nvim-dap) and Java (jdtls, nvim-jdtls, nvim-dap) are already wired; prefer extending these setups instead of introducing parallel ones.
- Copilot:
  - Neovim uses the `copilot-vim` plugin configured in `nvim-lua/plugins/copilot.lua`.
  - GitHub Copilot CLI is installed via `home.packages` in `home-manager/home.nix`.
- Cursor CLI:
  - Implemented as Nix package `cursor-cli` in `home-manager/home.nix`, embedding `home-manager/scripts/cursor-agent.sh` and `cursor-cli-install.sh`.
  - `cursor-agent` auto-installs/updates the official CLI via `https://cursor.com/install` into `$HOME/.local/bin`.

### Scripts and desktop tooling

- Reusable scripts belong in:
  - `home-manager/scripts` for scripts referenced from Nix packages/overlays.
  - `dots/hypr` for Hyprland/desktop-related helpers (e.g. rofi integrations, wallpaper tools).
- `dots/hypr/wallpaper-picker.py` maintains caches in `~/.cache/album_covers` (`thumbnails`, full-size images, `rofi_list_cache.txt`). When editing, preserve the caching behavior and `.env`-based configuration.
- Use `make wallpaper-fix` to clear wallpaper cache and force regeneration via `wallpaper-picker.py`.

### Language workflows

- For C/C++ and Java, prefer the existing workflows under `docs/`:
  - `docs/cpp-development-workflow.md` – Nix/devbox shells, CMake project layout, `compile_commands.json` symlink, Neovim LSP/DAP.
  - `docs/java-development-workflow.md` – Neovim + jdtls, Maven lifecycle (`mvn compile`, `mvn test`, `mvn package`), Google Java style, `nvim-dap` debugging.
- When suggesting commands or configuration for these stacks, align with those documents instead of inventing new patterns.
