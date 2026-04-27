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
in
{
  home.packages = with pkgs; [
    firefoxpwa
  ];

  programs.librewolf = {
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
          "admin@2fas.com" = "2fas-two-factor-authentication";
        };
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        TranslateEnabled = false;
        Preferences = {
          "browser.ctrlTab.sortByRecentlyUsed" = true;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "browser.toolbars.bookmarks.visibility" = "never";
        };
      };
    profiles.default = {
      search = {
        force = true;
        default = "Kagi";
        privateDefault = "ddg";

        inherit engines;
      };
      userChrome = ''
        #TabsToolbar { display: none !important; }
        #sidebar-box #sidebar-header { display: none !important; }
      '';
      extensions = {
        packages = with perSystem.firefox-addons; [
          ublock-origin
          onepassword-fixed
          return-youtube-dislikes
          vimium-c
          sidebery
          tabwrangler
          languagetool-fixed
          pwas-for-firefox
          sponsorblock
        ];
      };
    };
  };

  programs.firefox = {
    enable = true;
    policies = {
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      TranslateEnabled = false;
      Preferences = {
        "browser.ctrlTab.sortByRecentlyUsed" = true;
      };
    };
    profiles.default = {
      search = {
        force = true;
        default = "Kagi";
        privateDefault = "ddg";

        inherit engines;
      };
      extensions = {
        packages = with perSystem.firefox-addons; [
          ublock-origin
          vimium-c
          sponsorblock
        ];
      };
    };
  };
}
