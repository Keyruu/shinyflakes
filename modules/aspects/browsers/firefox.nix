{ ... }:
{
  den.aspects.browsers.firefox = {
    homeManager =
      {
        pkgs,
        ...
      }:
      let
        engines = {
          "Uruky" = {
            urls = [
              {
                template = "https://uruky.com/search";
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
        programs.firefox = {
          enable = true;
          policies = {
            AutofillAddressEnabled = false;
            AutofillCreditCardEnabled = false;
            DontCheckDefaultBrowser = true;
            NoDefaultBookmarks = true;
            OfferToSaveLogins = false;
            TranslateEnabled = false;
            SearchEngines = {
              Default = "Uruky";
              Add = [
                {
                  Name = "Uruky";
                  URLTemplate = "https://uruky.com/search?q={searchTerms}";
                }
              ];
            };
            Preferences = {
              "browser.ctrlTab.sortByRecentlyUsed" = true;
            };
            ExtensionSettings =
              let
                moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
              in
              {
                "*".installation_mode = "blocked";

                "uBlock0@raymondhill.net" = {
                  install_url = moz "ublock-origin";
                  installation_mode = "force_installed";
                  updates_disabled = true;
                };

                "vimium-c@gdh1995.cn" = {
                  install_url = moz "vimium-c";
                  installation_mode = "force_installed";
                  updates_disabled = true;
                };

                "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
                  install_url = moz "1password-x-password-manager";
                  installation_mode = "force_installed";
                  updates_disabled = true;
                };

                "sponsorBlocker@ajay.app" = {
                  install_url = moz "sponsorblock";
                  installation_mode = "force_installed";
                  updates_disabled = true;
                };

                "addon@darkreader.org" = {
                  install_url = moz "darkreader";
                  installation_mode = "force_installed";
                  updates_disabled = true;
                };

                "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
                  install_url = moz "return-youtube-dislikes";
                  installation_mode = "force_installed";
                  updates_disabled = true;
                };

                "firefox@vicinae.com" = {
                  install_url = moz "vicinae";
                  installation_mode = "force_installed";
                  updates_disabled = true;
                };
              };
          };
          profiles.default = {
            search = {
              force = true;
              default = "Uruky";
              privateDefault = "ddg";

              inherit engines;
            };
          };
        };
      };
  };
}
