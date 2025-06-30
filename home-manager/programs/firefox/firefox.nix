{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      settings = {
        "browser.startup.homepage" = "https://duckduckgo.com";
        # "privacy.donottrackheader.enabled" = true;
        "browser.search.suggest.enabled" = false;
        "extensions.autoDisableScopes" = 0;
        "extensions.enabledScopes" = 15;
        
        # Dark theme settings
        "ui.systemUsesDarkTheme" = 1;
        "browser.theme.dark-private-browsing" = true;
        "browser.theme.content-theme" = 0; # 0 = dark, 1 = light, 2 = system
        "layout.css.prefers-color-scheme.content-override" = 0; # Force dark mode for websites
        "devtools.theme" = "dark";
        "browser.in-content.dark-mode" = true;
        "ui.prefersReducedMotion" = 0;
      };

      userChrome = ''
        /* Hide the title bar */
        #titlebar {
          display: none !important;
        }
      '';
    };

    policies = {
      # DisableTelemetry = true;
      # DisableFirefoxStudies = true;
      # EnableTrackingProtection = {
      #   Value = true;
      #   Locked = true;
      #   Cryptomining = true;
      #   Fingerprinting = true;
      # };
      # DisablePocket = true;
      # DisableFirefoxAccounts = true;
      # DisableAccounts = true;
      # DisableFirefoxScreenshots = true;
      # OverrideFirstRunPage = "";
      # OverridePostUpdatePage = "";
      # DontCheckDefaultBrowser = true;
      # DisplayBookmarksToolbar = "never";
      # DisplayMenuBar = "default-off";
      # SearchBar = "unified";
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
        };
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
        };
      };
    };
  };
}
