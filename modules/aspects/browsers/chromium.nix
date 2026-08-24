{ ... }:
let
  extensionIds = [
    "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
    "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
    "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
    "gebbhagfogifgggkldgodflihgfeippi" # Return YouTube Dislike
    "kcmipingpfbohfjckomimmahknoddnke" # Vicinae Integration
  ];

  # Layer A: chromeenterprise managed policies (locked, user can't override).
  # Schema: https://chromeenterprise.google/policies/
  policies = {
    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "Kagi";
    DefaultSearchProviderKeyword = "kagi.com";
    DefaultSearchProviderSearchURL = "https://kagi.com/search?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://kagisuggest.com/api/autosuggest?q={searchTerms}";
    DefaultSearchProviderImageURL = "https://kagi.com/reverse/upload";
    DefaultSearchProviderNewTabURL = "https://kagi.com/";

    PasswordManagerEnabled = false;
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;
    ExtensionInstallForcelist = extensionIds;
  };

  # Layer B: Helium-specific UI prefs (no chromeenterprise equivalent).
  # Merged into Default/Preferences at activation time — see mergePrefs below.
  # We never symlink Default/Preferences because Helium writes back to it on
  # quit (sessions, signin, per-site perms, window placement). A symlink to
  # /nix/store would block those writes and break the browser.
  preferences = {
    helium.browser = {
      centered_location_bar = true;
      layout = 2;
      minimal_location_bar = false;
      mru_tab_cycling = true;
      vertical_right_aligned = false;
      zen_mode = true;
      zen_mode_sidebar_pinned = false;
    };
    helium.completed_onboarding = true;
    helium.services = {
      browser_updates = false;
      enabled = true;
      schema_version = 1;
      user_consented = true;
    };
    # https://source.chromium.org/chromium/chromium/src/+/main:chrome/app/chrome_command_ids.h
    # Vim hjkl on browser navigation. added = new binding, removed = unbind default.
    helium.browser.custom_accelerators = {
      # 33000 IDC_BACK
      "33000" = {
        added = [ "Control+KeyH" ];
      };
      # 33001 IDC_FORWARD
      "33001" = {
        added = [ "Control+KeyL" ];
      };
      # 34016 IDC_SELECT_NEXT_TAB
      "34016" = {
        added = [ "Control+KeyJ" ];
      };
      # 34017 IDC_SELECT_PREVIOUS_TAB
      "34017" = {
        added = [ "Control+KeyK" ];
      };
      # 39001 IDC_FOCUS_LOCATION
      "39001" = {
        added = [ "Control+Slash" ];
        removed = [ "Control+KeyL" ];
      };
      # 39002 IDC_FOCUS_SEARCH
      "39002" = {
        removed = [ "Control+KeyK" ];
      };
      # 40010 IDC_SHOW_HISTORY (default Ctrl+H; unbound, taken by Back)
      "40010" = {
        removed = [ "Control+KeyH" ];
      };
      # 40012 IDC_SHOW_DOWNLOADS (default Ctrl+J; unbound, taken by Next Tab)
      "40012" = {
        removed = [ "Control+KeyJ" ];
      };
    };
    vertical_tabs = {
      collapsed_state = false;
      uncollapsed_width = 200;
    };
    browser.theme.is_grayscale2 = true;
    ntp.num_personal_suggestions = 0;
    privacy_sandbox.first_party_sets_enabled = false;
    intl.selected_languages = "en-US,en";
    spellcheck = {
      dictionary = "";
      dictionaries = [ "en-US" ];
    };
  };
in
{
  den.aspects.browsers.chromium = {
    homeManager =
      {
        lib,
        config,
        pkgs,
        inputs',
        ...
      }:
      let
        seedPath = "${config.xdg.configHome}/net.imput.helium/.declarative-prefs.json";
        livePath = "${config.xdg.configHome}/net.imput.helium/Default/Preferences";

        mergePrefs = pkgs.writeShellApplication {
          name = "helium-merge-prefs";
          runtimeInputs = [ pkgs.jq ];
          text = ''
            set -euo pipefail
            live="${livePath}"
            live="''${live/#\$XDG_CONFIG_HOME\//''${XDG_CONFIG_HOME:-$HOME/.config}/}"
            seed="$1"
            mkdir -p "$(dirname "$live")"
            [ -f "$live" ] || echo '{}' > "$live"
            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT
            jq -s '.[0] * .[1]' "$live" "$seed" > "$tmp"
            mv "$tmp" "$live"
            chmod 600 "$live"
          '';
        };
      in
      {
        home.packages = [ inputs'.helium.packages.default ];

        # Layer A: chromeenterprise policies (read-only by design, Helium never writes here).
        # Layer B seed — hidden dot-prefix keeps it out of Helium's view.
        # ExtensionInstallForcelist installs silently via the services proxy.
        xdg.configFile = {
          "net.imput.helium/policies/managed/helium.json" = lib.mkIf (policies != { }) {
            text = builtins.toJSON policies;
          };
          "net.imput.helium/.declarative-prefs.json" = lib.mkIf (preferences != { }) {
            text = builtins.toJSON preferences;
          };
        };

        home.activation.heliumMergePrefs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${lib.getExe mergePrefs} ${seedPath}
        '';
      };
  };
}
