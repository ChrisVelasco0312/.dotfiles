{
  description = "React Native development shell (NixOS + Expo + direnv)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # The Android SDK is installed via Android Studio at ~/Android/Sdk
        # (kept out of the Nix store so the SDK Manager + licenses work normally).
        androidHome =
          let env = builtins.getEnv "ANDROID_HOME"; in
          if env != "" then env else "${builtins.getEnv "HOME"}/Android/Sdk";
      in
      {
        devShells.default = pkgs.mkShell {
          name = "react-native";

          buildInputs = with pkgs; [
            # --- Runtime / languages ---
            nodejs_20     # Node 20 LTS — the version React Native officially supports
            jdk17         # JDK 17 — required by the Android Gradle Plugin and RN
            watchman      # File watcher that powers Metro's Fast Refresh

            # --- Build tooling ---
            gradle        # Gradle CLI (apps usually use the wrapper; this covers edge cases)
            cmake         # Needed by native modules that compile C/C++
            ninja         # Faster backend for some native module builds

            # --- Device interaction ---
            android-tools # adb / fastboot (also system-wide; ensures parity in the shell)
            scrcpy        # Mirror + control a physical Android device screen
          ];

          shellHook = ''
            # --- Android SDK paths ---
            export ANDROID_HOME="${androidHome}"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

            # --- JDK 17 for Gradle / React Native (overrides the system JDK 21) ---
            export JAVA_HOME="${pkgs.jdk17}/lib/openjdk"
            export PATH="$JAVA_HOME/bin:$PATH"

            # Watchman needs a place to keep its state.
            export WATCHMAN_STATE_DIR="''${WATCHMAN_STATE_DIR:-$HOME/.watchman-state}"
            mkdir -p "$WATCHMAN_STATE_DIR"

            echo ""
            echo "🐸 React Native devShell active"
            echo "   Node:         $(node --version)"
            echo "   JDK:          $(java -version 2>&1 | head -1)"
            echo "   adb:          $(adb --version 2>/dev/null | head -1 || echo 'not found')"
            echo "   ANDROID_HOME: $ANDROID_HOME"
            echo ""
          '';
        };
      });
}