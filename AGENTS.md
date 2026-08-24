# AGENTS.md

Personal NixOS + Home Manager dotfiles. `flake.nix` is the single entrypoint with two outputs: a system config and a home-manager config.

## Build & apply

Run from repo root. `--impure` is **required** on every flake command — `home.nix` reads `.env` at eval time via `builtins.readFile`; dropping `--impure` breaks evaluation.

- `make build` — full apply (alias of `make flake`): system rebuild, then home-manager.
- `make flake` — system only: `sudo nixos-rebuild switch --flake .#nixos --impure` + `make home`.
- `make home` — home only: sources `.env`, then `home-manager switch -b backup --flake .#cavelasco@nixos --impure`.
- `make flake-dry` / `make home-dry` — dry-run variants; use `home-dry` for a fast eval check before applying.
- `make home-eval` — `nix eval .#homeConfigurations.cavelasco@nixos.config.home.username --impure` (quick eval probe).
- `make home-news` — print home-manager news before switching.
- `make update` — `nix flake update` all inputs + system rebuild + home.
- `make update-safe` — update only `home-manager nixd hardware plugin-lualine`, then home (avoid full nixpkgs roll).
- `make clean` — `nix-collect-garbage`.
- `make wallpaper-fix` — clear `~/.cache/album_covers` and regenerate the rofi wallpaper list via `dots/hypr/wallpaper-picker.py`.

Order matters: `make build`/`make flake` rebuild the system **then** run home; `make home` needs `.env` present.

## Validation

No automated tests. Verify changes by running the target you touched: `make home` (home-manager) or `make flake` (system). Use `make home-dry`/`make flake-dry` for a fast check before applying. `nixd` is the Nix LSP.

## Critical gotchas

- `.env` (gitignored) holds secrets (e.g. `LASTFM_APIKEY`/`LASTFM_SECRET`/`LASTFM_USER`). Parsed in Nix (`home.nix` `env` attr) and in Python (`dots/hypr/wallpaper-picker.py`). Add new keys with the `env.FOO or ""` pattern so missing keys stay optional. Never commit `.env` or hardcode/log its values.
- `hardware-configuration.nix` is machine-specific and gitignored; `nixos/configuration.nix` imports it from the absolute path `/etc/nixos/hardware-configuration.nix`. Don't expect it in the repo and don't make paths relative to the flake.
- `-b backup` (in `make home`) makes home-manager back up files it would overwrite.
- Submodule `dots/nvim-frankenstein` — run `git submodule update --init` on a fresh clone.

## Architecture

`flake.nix` defines:
- `nixosConfigurations.nixos` — system config; modules `./nixos/configuration.nix` + `./nixos/hyprland.nix` + a module that applies the `nixd` overlay.
- `homeConfigurations."cavelasco@nixos"` — home config; module `./home-manager/home.nix`.

Boundaries:
- `nixos/` — system-level: boot, NVIDIA driver, networking, PipeWire/JACK audio, and services (mysql, navidrome, murmur, tailscale, docker, steam, flatpak).
- `home-manager/home.nix` — parses `.env`, defines overlays + `home.packages` + session vars, and wires `dots/*` into `~/.config` via `xdg.configFile`. Imports modules from `home-manager/programs/*`.
- `home-manager/programs/<name>/` — one focused HM module per dir (`neovim`, `tmux`, `rofi`, `firefox`, `cursor`).
- `dots/` — non-Nix configs/scripts (hypr, waybar, rofi, kitty, eww, ncmpcpp, ghostty, mpv). **Not standalone**: they only ship via `xdg.configFile` lines in `home.nix`.
- `docs/` — workflow docs (C/C++, Java, React Native, GPU passthrough).
- `templates/react-native/` — project template consumed via direnv.
- `node-shells/shell.nix` — `nodejs_20` dev shell; prepends `node_modules/.bin` to `PATH`.

## Conventions

- Add a user-level program: create `home-manager/programs/<name>/default.nix`, append it to `imports` in `home-manager/home.nix`.
- Add system-level config: extend `nixos/configuration.nix`, or add a module and list it in `flake.nix` `nixosConfigurations.nixos.modules`.
- Add a flake input in `flake.nix`, then expose it via an overlay in `home.nix` (see `own-lualine-nvim` built from the `plugin-lualine` input and exposed as `pkgs.vimPlugins.own-lualine-nvim`).
- Embed Lua/shell config with `builtins.readFile` (and the `toLuaFile` helper in the neovim module) rather than large inline strings.
- Neovim: edit `home-manager/programs/neovim/default.nix` (`plugins` list, `extraPackages`) and `nvim-lua/plugins/*.lua` (Lua config, loaded via `builtins.readFile` in `initLua`).
- When adding a new `dots/*` file, also add the matching `xdg.configFile` line in `home.nix` — the source alone won't be installed.

## Language tooling (pre-installed via home.packages — don't suggest installing these)

- Python: `ruff`, `mypy`, `black`, `isort`, `uv` (+ `tidalapi`, `requests`).
- Java/JVM: `jdk21`, `maven`, `jdt-language-server`, `lombok`.
- Node/Bun: `nodejs_24`, `pnpm`, `yarn`, `typescript`, `prettier`, `bun`, `watchman`.
- C/C++: `gcc`, `gnumake`, `cmake`, `clang`, `lldb`, `gdb`.
- direnv + nix-direnv are enabled; per-project `devShell`s auto-load on `cd`.

Project-specific workflows live in `docs/` (C/C++, Java, React Native). A fuller guide exists at `.github/copilot-instructions.md` but is partly stale (e.g. it references a `cursor-cli` overlay no longer present in `home.nix`) — trust this file and the source over it.
