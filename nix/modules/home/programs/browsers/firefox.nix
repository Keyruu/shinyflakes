{
  perSystem,
  pkgs,
  lib,
  ...
}:
let
  # Override the unfree packages to mark them as free
  onepassword-fixed = perSystem.firefox-addons.onepassword-password-manager.overrideAttrs (old: {
    meta = old.meta // {
      license = lib.licenses.free;
    };
  });
  languagetool-fixed = perSystem.firefox-addons.languagetool.overrideAttrs (old: {
    meta = old.meta // {
      license = lib.licenses.free;
    };
  });
in
{
  home.packages = with pkgs; [
    firefoxpwa
  ];

  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.firefoxpwa ];
    policies =
      let
        mkExtensionSettings = builtins.mapAttrs (
          _: pluginId: {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
            installation_mode = "force_installed";
          }
        );
      in
      {
        ExtensionSettings = mkExtensionSettings {
          "{94d0c662-e350-4ae5-9c76-79a9a756627f}" = "2fas-auth";
        };
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        TranslateEnabled = false;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        Preferences = {
          "browser.ctrlTab.sortByRecentlyUsed" = true;
        };
      };
    profiles.default = {
      search = {
        force = true;
        default = "Kagi";
        privateDefault = "ddg";

        engines = {
          "Kagi" = {
            urls = [
              {
                template = "https://kagi.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "";
          };
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          "Nix Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@no" ];
          };

          "NixOS Wiki" = {
            urls = [
              {
                template = "https://wiki.nixos.org/w/index.php";
                params = [
                  {
                    name = "search";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@nw" ];
          };
        };
      };
      extensions = {
        packages = with perSystem.firefox-addons; [
          ublock-origin
          dearrow
          onepassword-fixed
          return-youtube-dislikes
          vimium-c
          languagetool-fixed
          pwas-for-firefox
          sponsorblock
        ];
      };
    };
  };
}
