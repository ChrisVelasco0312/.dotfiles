# React Native Development Workflow with NixOS and Neovim

This document is the **global, reusable workflow** for developing React Native
applications on this NixOS system with Neovim as the primary editor. It is
explicitly designed for building **many apps over time**, not a single project:
the system-level dependencies live in the NixOS + Home Manager configuration
and are applied once, while each new project reuses the devShell template to
get a pinned, isolated, and reproducible toolchain.

> **Stack choice: Expo + React Native.** Expo is free and open source for both
> development and commercial production. Only the optional EAS cloud services
> (build / update) are paid, with a free tier of ~30 iOS + 30 Android cloud
> builds/month. `eas build --local` (Android) is always free. NixOS cannot
> build iOS binaries locally (iOS requires macOS + Xcode), so iOS builds are
> delegated to EAS cloud or a Mac; dev preview on iPhone uses Expo Go over WiFi.

---

## Development Environment Overview

### What lives where

| Layer             | Location                           | Scope                   | Pinned?                     |
| ----------------- | ---------------------------------- | ----------------------- | --------------------------- |
| System packages   | `nixos/configuration.nix`          | All users, all projects | By flake input              |
| User packages     | `home-manager/home.nix`            | Your user, all projects | By flake input              |
| Project toolchain | `templates/react-native/flake.nix` | One project (copied in) | By per-project `flake.lock` |

The system + Home Manager layers provide the **shared prerequisites** that every
React Native project needs (Android SDK, adb udev rules, watchman, direnv,
firewall port, inotify watches, Neovim LSP). The project layer provides the
**pinned toolchain** (Node 20 LTS, JDK 17, Gradle, watchman) so each app can stay
on a known-good set of versions independent of the others.

### Installed Tools (system / user)

- **Node.js 24** (system-wide, latest) — the per-project devShell pins **Node 20 LTS**.
- **Watchman** — file watcher that powers Metro's Fast Refresh.
- **JDK 21** (system-wide) — the per-project devShell pins **JDK 17** (the version
  required by the Android Gradle Plugin and React Native).
- **Android SDK** at `~/Android/Sdk` — build-tools 34/35/36, platforms android-30..36,
  NDK 26/27, cmake 3.22.1, emulator, system-images android-36.1 (Play Store, x86_64),
  cmdline-tools, platform-tools/adb. Managed via Android Studio's SDK Manager.
- **Android Studio** — SDK management + emulator (AVD) creation.
- **adb / scrcpy** — device interaction and screen mirroring.
- **direnv + nix-direnv** — auto-loads the per-project devShell on `cd`.
- **Gradle, CMake, Ninja** — native module build tooling (in the devShell).

### Neovim React Native Features

| Capability             | Provider                         | Notes                                                    |
| ---------------------- | -------------------------------- | -------------------------------------------------------- |
| TS/JS LSP              | `ts_ls`                          | Go-to-definition, completion, hover, rename              |
| ESLint                 | `eslint` LSP                     | Diagnostics + code actions                               |
| JSX Emmet              | `emmet_ls` (JSX-aware)           | `class`->`className`, `for`->`htmlFor`, etc.             |
| Tree-sitter            | `nvim-treesitter` (all grammars) | TSX/JSX parsing + highlighting                           |
| Auto-close/rename tags | `nvim-ts-autotag`                | Closes JSX tags, renames matching pairs                  |
| Format on save         | `prettierd` via `null-ls`        | Toggle with `:FormatOnSaveToggle` (default OFF)          |
| Manual format          | `prettierd`                      | `<leader>f`                                              |
| Autocompletion         | `nvim-cmp` + `cmp-nvim-lsp`      | LSP + buffer sources (Codeium source removed: no plugin) |
| Bottom terminal        | `<leader>tt`                     | Run Metro in a terminal inside Neovim                    |
| Debugging              | Chrome / React DevTools          | No JS DAP configured — use the JS debugger (see below)   |

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      NixOS system layer                         │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────────────┐  │
│  │ programs.adb │  │ firewall     │  │ inotify max_user_watches│ │
│  │ (udev rules  │  │ port 8081    │  │   = 524288             │  │
│  │  + adbusers) │  │  (Metro)     │  │   (Metro file watching)│  │
│  └─────────────┘  └──────────────┘  └───────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
          │                                │
          ▼                                ▼
┌─────────────────────────────────────────────────────────────────┐
│              Home Manager user layer (cavelasco)                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ watchman │ │ direnv   │ │ ANDROID_ │ │ Neovim LSP stack │  │
│  │          │ │ nix-direnv│ │ SDK_ROOT │ │ ts_ls/eslint/    │  │
│  └──────────┘ └──────────┘ └──────────┘ │ emmet/autotag    │  │
│                                          └──────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│              Per-project layer (copied from template)           │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  flake.nix  (nodejs_20 + jdk17 + watchman + gradle +    │   │
│  │              cmake + ninja + android-tools + scrcpy)     │   │
│  │  .envrc    →  use flake  (auto-loaded by direnv)         │   │
│  │  flake.lock (pins this project's nixpkgs revision)      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Runtime targets                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Metro :8081  │  │ Android device│  │ iOS via Expo Go /    │  │
│  │ (dev server) │  │ (USB via adb) │  │ EAS Build (cloud/Mac)│  │
│  │              │  │ or emulator   │  │                      │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Environment Variables Reference

| Variable             | Set in               | Value                            | Purpose                                         |
| -------------------- | -------------------- | -------------------------------- | ----------------------------------------------- |
| `ANDROID_HOME`       | `home.nix` (session) | `$HOME/Android/Sdk`              | Primary Android SDK location (RN + Gradle)      |
| `ANDROID_SDK_ROOT`   | `home.nix` (session) | `$HOME/Android/Sdk`              | Fallback some Gradle scripts read               |
| `JAVA_HOME`          | `home.nix` (session) | `jdk21/.../openjdk`              | System default (JDK 21)                         |
| `JAVA_HOME`          | devShell `shellHook` | `jdk17/.../openjdk`              | Per-project override to JDK 17                  |
| `PATH` (+SDK)        | devShell `shellHook` | `+cmdline-tools/latest/bin` etc. | Make `sdkmanager`, `adb`, `emulator` reachable  |
| `WATCHMAN_STATE_DIR` | devShell `shellHook` | `$HOME/.watchman-state`          | Keeps watchman state writable outside Nix store |
| `CHROME_EXECUTABLE`  | `home.nix` (session) | `brave`                          | Some RN scripts auto-open a browser             |

---

## One-time Verification

After applying the NixOS config changes, rebuild and verify the system is
React Native ready:

```bash
# Rebuild the whole system + Home Manager (from the dotfiles root)
make flake && make home

# --- Checklist ---
getent group adbusers                       # adbusers group must exist
adb devices                                  # Should list "List of devices attached"
watchman --version                           # watchman must be on PATH
echo "$ANDROID_SDK_ROOT"                     # Must print ~/Android/Sdk
ls /lib/udev/rules.d/*android* 2>/dev/null  # udev rules for USB devices
cat /proc/sys/fs/inotify/max_user_watches   # Must be 524288
ls ~/Android/Sdk/cmdline-tools/latest/bin   # sdkmanager, avdmanager...
```

> **Why `make flake` uses `--impure`:** `configuration.nix` imports
> `/etc/nixos/hardware-configuration.nix`, which lives outside the flake. The
> `--impure` flag lets Nix read it. This is normal and expected.

You must **log out and back in** (or run `newgrp adbusers`) for the `adbusers`
group membership to take effect before `adb devices` will see a USB phone.

---

## Project Setup Workflow

### 1. Create a new Expo project

```bash
cd ~/projects   # or wherever you keep code

# Create a new Expo app (TypeScript template)
npx create-expo-app@latest my-app --template blank-typescript
cd my-app
```

### 2. Attach the devShell template

Copy the pinned toolchain into every new project (this is the global step that
makes the workflow repeatable):

```bash
cp ~/.dotfiles/templates/react-native/flake.nix  ./flake.nix
cp ~/.dotfiles/templates/react-native/.envrc     ./.envrc
direnv allow
```

direnv auto-loads the shell on every `cd` into the project. You should see the
banner:

```
🐸 React Native devShell active
   Node:         v20.x.x
   JDK:          openjdk version "17..."
   adb:          Android Debug Bridge version 1.0.41
   ANDROID_HOME: /home/cavelasco/Android/Sdk
```

> **Pin the project nixpkgs:** run `nix flake update` inside the project
> periodically to bump `flake.lock`. Each project keeps its own lock so apps
> don't force each other to upgrade.

### 3. Install JS dependencies

```bash
npm install     # or: pnpm install / yarn install
```

### 4. (Optional) Initialize EAS for cloud builds

```bash
npx eas-cli build:configure   # creates eas.json
```

---

## Development Workflow

### Running Metro

Metro is the bundler/dev server. It runs on port 8081 and serves the JS bundle
to the device/emulator over the local network.

```bash
# Start Metro (from the project root, inside the devShell)
npx expo start
```

Neovim tip: `<leader>tt` opens a bottom terminal — run Metro there and keep
editing in the main window.

### Running on Android

#### Physical device (USB)

```bash
# Enable Developer Options + USB Debugging on the phone
adb devices                      # Confirm device listed (not "unauthorized")
npx expo run:android --device    # Builds + installs + launches on the phone
```

If `adb devices` shows `unauthorized`, accept the RSA prompt on the phone.

If no device appears at all:

1. Check the USB cable is a data cable (not charge-only).
2. Run `lsusb` to confirm the phone is detected.
3. Run `ls /lib/udev/rules.d/*android*` to confirm adb udev rules installed.
4. Run `getent group adbusers` and `id` — confirm you're in `adbusers`.
5. Re-plug or run `adb kill-server && adb start-server`.

#### Emulator (AVD)

**Prerequisites** — before using the emulator you must install the emulator
package, a system image, and confirm KVM is available:

```bash
# 1. Verify KVM (required for hardware acceleration on Linux)
ls /dev/kvm          # must exist; if not, enable virtualization in BIOS/UEFI

# 2. Install the Android Emulator package + a system image via Android Studio:
#    Android Studio → Settings → SDK Manager → SDK Platforms
#      → install a platform (e.g., Android API 36.1)
#    SDK Manager → SDK Tools
#      → check "Android Emulator" and install

# 3. Confirm the emulator binary is reachable (devShell adds it to PATH)
which emulator       # should print ~/Android/Sdk/emulator/emulator

# 4. Create an AVD (if you didn't create one via Android Studio UI)
avdmanager create avd -n TestDevice -k "system-images;android-36.1;google_apis_playstore;x86_64"
```

> **NixOS-specific notes:**
>
> - **KVM module** — `configuration.nix` must load `kvm_amd` (or `kvm-intel`)
>   in `boot.kernelModules` so KVM is available after every boot. Verify:
>   `lsmod | grep kvm`.
> - **Missing shared libraries** — the Android Emulator is a prebuilt binary
>   that expects FHS paths. NixOS fixes this via `programs.nix-ld`; the
>   required library (`libx11`) must be in `nix-ld.libraries`. If you see
>   `error while loading shared libraries: libX11.so.6`, rebuild: `make flake`.
> - **Rebuild required** — after changing `configuration.nix`, run
>   `sudo nixos-rebuild switch` (or `make flake`) for KVM and nix-ld changes
>   to take effect.

```bash
# List available AVDs
emulator -list-avds

# Launch an AVD (e.g. the one bundled with the SDK)
emulator -avd Pixel_9_API_36.1 -no-snapshot-load &

# Run the app on the emulator
npx expo run:android
```

### Running on iOS

NixOS **cannot** build or run iOS binaries locally — iOS requires macOS + Xcode.
Two supported paths:

| Path                      | What it is                                        | When to use                      |
| ------------------------- | ------------------------------------------------- | -------------------------------- |
| **Expo Go (dev preview)** | Open the Expo Go app on your iPhone, scan the QR  | Everyday dev on a real iPhone    |
| **EAS Build (cloud)**     | `eas build --platform ios` builds on Expo's cloud | Production iOS builds from NixOS |
| **EAS Build (Mac)**       | Run EAS on a Mac with Xcode                       | If you own a Mac                 |

```bash
# Dev preview on iPhone over WiFi (phone same network as this machine)
npx expo start                # then open Expo Go and scan the QR

# Production iOS build via cloud (free tier: ~30/mo)
npx eas-cli build --platform ios --profile production
```

The Metro dev server on port 8081 must be reachable from the phone (firewall
already opens 8081 on this system).

---

## Neovim Editing Workflow

### Opening projects

```bash
cd ~/projects/my-app   # direnv loads the devShell automatically
nvim .                 # open the project root (oil.nvim file browser)
```

### Key LSP features for TypeScript/React

| Keybinding            | Action                | Description                            |
| --------------------- | --------------------- | -------------------------------------- |
| `gd`                  | Go to definition      | Jump to symbol definition              |
| `gI`                  | Go to implementation  | Jump to TS implementation              |
| `K`                   | Hover                 | Show type docs                         |
| `<leader>rn`          | Rename                | Rename symbol everywhere               |
| `<leader>ca`          | Code action           | ESLint fixes, imports                  |
| `<leader>f`           | Format                | prettierd (null-ls)                    |
| `:FormatOnSaveToggle` | Toggle format-on-save | Default OFF; turns ON for this session |

### Emmet JSX expansions

In a `.tsx` file, type an abbreviation and trigger expansion (default `<C-y>,`
or `<Tab>` depending on your cmp setup):

```
div.className            → <div className=""></div>
ul>li*3                  → nested <ul><li></li><li></li><li></li></ul>
button[type=submit]      → <button type="submit"></button>
```

The `emmet_ls` in this config is JSX-aware: `class` becomes `className`,
`for` becomes `htmlFor`, `tabindex` becomes `tabIndex`.

### Auto-tag

`nvim-ts-autotag` closes JSX tags when you type `>` and renames matching pairs
when you edit an open/close tag. HTML auto-tag is intentionally disabled (JSX only).

---

## Debugging

There is no JS/TS DAP adapter configured (the existing `nvim-dap` is Java-only).
React Native debugging uses the JS debugger instead:

### Chrome DevTools

```bash
# In the running app (device or emulator):
#   Android: press `j` (if run via expo start --dev-client) or open the dev menu
#            with `adb shell input keyevent 82` and select "Open Mono / DevTools".
# Or set a breakpoint and run:
npx react-native debug
```

This opens Chrome (or Brave, per `CHROME_EXECUTABLE`) with the React + Redux
DevTools and a full JS step-debugger.

### React DevTools (standalone)

```bash
npx react-devtools        # launches the standalone React DevTools window
# In the app, connect via the dev menu → "Open React DevTools"
```

### Flipper (optional)

Flipper is a mobile dev tool platform. It's available as a Linux download but
is **not** in Nixpkgs (no maintained Nix derivation). If needed, use the AppImage
or run via `nix-shell` with `fetchurl`. For most workflows, Chrome DevTools +
React DevTools are sufficient.

### Logcat

```bash
adb logcat                 # all device logs
adb logcat *:E             # errors only
adb logcat -s ReactNative:V ReactNativeJS:V   # RN-specific logging
```

### Metro console

Errors from the bundler, type errors, and Metro's own logs appear in the
terminal where `expo start` is running. Keep it open (in the Neovim bottom
terminal with `<leader>tt`) to watch for bundle errors.

---

## Building

### Android (local build)

```bash
# Debug APK (fast iteration, needs Metro running)
npx expo run:android --variant debug

# Release build (needs a keystore for signing)
# 1. Generate a keystore (one-time)
keytool -genkey -v -keystore android/my-release-key.keystore \
  -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000

# 2. Configure signing in android/app/build.gradle, then:
cd android && ./gradlew assembleRelease
# Output: android/app/build/outputs/apk/release/app-release.apk

# Or build an App Bundle for the Play Store
cd android && ./gradlew bundleRelease
# Output: android/app/build/outputs/bundle/release/app-release.aab
```

### Android (EAS Build — local)

```bash
# Free, runs on this NixOS machine
npx eas-cli build --platform android --local
```

### Android (EAS Build — cloud)

```bash
# Uses Expo's cloud builders (free tier: ~30 builds/month)
npx eas-cli build --platform android --profile production
```

### iOS (EAS Build — cloud only)

```bash
npx eas-cli build --platform ios --profile production
```

You cannot run `eas build --local --platform ios` on NixOS (needs macOS).

### OTA Updates (EAS Update)

```bash
# Push a JS-only update to already-installed apps (no store re-submission)
npx eas-cli update --branch production --message "fix login bug"
```

---

## Version & Lifecycle Management

### Updating the per-project toolchain

```bash
# Bump this project's nixpkgs lock to latest unstable (periodic)
nix flake update
direnv reload     # apply the new shell
```

### Updating expo / react-native (per project, via npm)

```bash
npx expo install --check   # check for compat updates
npx expo install --fix     # apply them
```

### Updating system-wide prerequisites (rare)

Edit `~/.dotfiles/nixos/configuration.nix` or `home-manager/home.nix`, then:

```bash
cd ~/.dotfiles
make flake && make home
```

---

## NixOS-specific Troubleshooting

### 1. `adb devices` shows no device

```bash
getent group adbusers           # must exist (programs.adb.enable)
id | grep -o adbusers           # you must be in the group
# If group missing → programs.adb not enabled → rebuild: make flake
# If not in group → log out/in or: newgrp adbusers
adb kill-server && adb start-server
adb devices
lsusb                            # confirm phone enumerates
ls /lib/udev/rules.d/*android*  # confirm udev rules present
```

### 2. Metro: "ENOSPC: System limit for number of file watchers reached"

The system `fs.inotify.max_user_watches` is too low. The config sets it to
524288 — verify and reload:

```bash
cat /proc/sys/fs/inotify/max_user_watches   # should be 524288
# If not: build kernel sysctl not applied → rebuild: make flake
# Temporary (until reboot):
sudo sysctl -w fs.inotify.max_user_watches=524288
```

### 3. Metro cannot be reached from the device

Check the firewall opens port 8081:

```bash
sudo iptables -L INPUT -n | grep 8081     # or:
sudo nixos-firewall-tool status          # NixOS firewall helper
# If closed → networking.firewall.allowedTCPPorts missing 8081 → make flake
```

Also confirm the phone and this machine are on the same WiFi.

### 4. `sdkmanager: command not found` inside the shell

The devShell `shellHook` adds `$ANDROID_HOME/cmdline-tools/latest/bin` to PATH.
If `sdkmanager` is still missing, the cmdline-tools are not installed. Fix via
Android Studio → SDK Manager → SDK Tools → Android SDK Command-line Tools (latest).

### 5. Gradle build fails with Java version mismatch

RN requires **JDK 17**. The system default is JDK 21. The devShell overrides
`JAVA_HOME` to JDK 17 — but if you ran Gradle outside the devShell:

```bash
echo $JAVA_HOME             # should point to jdk17 if inside the devShell
direnv reload               # re-enter the devShell
java -version               # confirm 17
```

### 6. `watchman` errors about state dir

watchman under Nix can hit permission issues if it tries to write inside the
read-only Nix store. The devShell sets `WATCHMAN_STATE_DIR=$HOME/.watchman-state`
to avoid this. Verify:

```bash
echo "$WATCHMAN_STATE_DIR"
ls -la "$HOME/.watchman-state"   # should exist and be writable
```

### 7. "`nix-ld`" / prebuilt binary errors

This system has `nix-ld` enabled with a curated library set (libdrm, mesa,
libxkbcommon, libsecret, gtk3, nss, nspr, glib). Some RN prebuilt binaries
(e.g. third-party Gradle plugins) may still need extra `LD_LIBRARY_PATH`
entries — add them to the devShell `buildInputs` or run via `nix-shell -p`.

### 8. Android Studio SDK vs `sdkmanager` SDK disagree

Android Studio installs SDKs to `~/Android/Sdk`. The devShell picks this up
automatically. Don't install a second SDK via Nixpkgs (`androidsdk` package) —
it conflicts and goes stale. Always use the Android Studio SDK.

### Log files

- **Metro**: terminal where `expo start` runs (or `~/.metro-cache` for cached output)
- **Android**: `adb logcat` (runtime) and `android/app/build/` (build output)
- **EAS**: `eas-cli` prints a build dashboard URL with full logs
- **Neovim LSP**: `:LspLog` (ts_ls / eslint / emmet logs)

---

## Workflow Example: Complete Development Cycle

### Creating a new app from scratch

```bash
# 1. Scaffold
cd ~/projects
npx create-expo-app@latest my-app --template blank-typescript
cd my-app

# 2. Attach the pinned devShell (one-time, per project)
cp ~/.dotfiles/templates/react-native/flake.nix  ./flake.nix
cp ~/.dotfiles/templates/react-native/.envrc     ./.envrc
direnv allow

# 3. Install JS deps
npm install

# 4. Open in Neovim
nvim .
# → ts_ls attaches automatically, emmet + autotag active in .tsx files
```

### Day-to-day dev cycle

```bash
cd ~/projects/my-app     # direnv auto-loads the devShell
nvim .                   # edit (LSP, completion, formatting)

# In another terminal (or <leader>tt inside Neovim):
npx expo start             # Metro on :8081

# In a third terminal:
npx expo run:android --device   # build + install + launch on connected phone
adb logcat *:E                  # watch for runtime errors
```

### Production release

```bash
# Android: signing key (one-time) + release build
keytool -genkey -v -keystore android/release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
# Configure android/app/build.gradle signingConfig, then:
cd android && ./gradlew bundleRelease

# iOS: cloud build (NixOS can't do local iOS)
npx eas-cli build --platform ios --profile production

# OTA JS-only update (no binary rebuild)
npx eas-cli update --branch production --message "v1.2.1 hotfix"
```

---

## Quick Reference: Neovim Keybindings (RN-relevant)

| Keybinding            | Mode     | Action                              |
| --------------------- | -------- | ----------------------------------- |
| `<space>` (leader)    | normal   | Leader prefix                       |
| `<space>w`            | normal   | Save file                           |
| `<space>q`            | normal   | Quit                                |
| `<leader>f`           | normal   | Format buffer (prettierd)           |
| `<leader>tt`          | normal   | Toggle bottom terminal              |
| `<leader>ts`          | normal   | Tmux sessionizer                    |
| `gd`                  | normal   | Go to definition (ts_ls)            |
| `gI`                  | normal   | Go to implementation                |
| `K`                   | normal   | Hover docs                          |
| `<leader>rn`          | normal   | Rename symbol                       |
| `<leader>ca`          | normal   | Code action (ESLint fixes)          |
| `<Esc><Esc>`          | terminal | Exit terminal mode                  |
| `:FormatOnSaveToggle` | cmd      | Toggle format-on-save (default OFF) |

---

## Additional Resources

- [React Native docs](https://reactnative.dev/docs/getting-started)
- [Expo documentation](https://docs.expo.dev/)
- [EAS Build](https://docs.expo.dev/build/introduction/)
- [EAS Update](https://docs.expo.dev/update/introduction/)
- [ts_ls (typescript-language-server)](https://github.com/typescript-language-server/typescript-language-server)
- [Emmet LS](https://github.com/aca/emmet-ls)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [Watchman](https://facebook.github.io/watchman/)
- [NixOS wiki: Android](https://nixos.wiki/wiki/Android)
- [direnv](https://direnv.net/)
- [Neovim LSP config](https://neovim.io/doc/user/lsp.html)

---

_This workflow is designed to be global and reusable. The system config is
applied once; every new project only needs the devShell template copy. All
tools are declaratively managed and reproducible, so the same workflow works
for every React Native app you build on this NixOS machine._
