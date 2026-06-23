{
  perSystem,
  pkgs,
  lib,
  ...
}:
let
  # Override the unfree packages to mark them as free

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
    tridactyl-native
  ];

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
