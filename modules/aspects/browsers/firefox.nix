{
  ...
}:
{
  den.aspects.browsers.firefox = {
    homeManager =
      {
        pkgs,
        lib,
        self',
        ...
      }:
      let
        betterfox = self'.packages.betterfox;

        # Tree-style tabs lives in sidebery — collapse the native tab bar.
        userChrome = ''
          #TabsToolbar {
            visibility: collapse !important;
          }

          #titlebar-buttonbox {
            height: 32px !important;
          }
        '';

        extraConfig = builtins.concatStringsSep "\n" [
          (builtins.readFile "${betterfox}/Securefox.js")
          (builtins.readFile "${betterfox}/Fastfox.js")
          (builtins.readFile "${betterfox}/Peskyfox.js")
        ];

        settings = {
          # General
          "intl.accept_languages" = "en-US,en";
          "browser.startup.page" = 3;
          "browser.aboutConfig.showWarning" = false;
          "browser.ctrlTab.sortByRecentlyUsed" = false;
          "browser.download.useDownloadDir" = false;
          "browser.translations.neverTranslateLanguages" = "de";
          "privacy.clearOnShutdown.history" = false;
          # Hi-DPI
          "layout.css.devPixelsPerPx" = "-1";
          # Dev console chrome
          "devtools.chrome.enabled" = true;
          # Crash reporting
          "browser.tabs.crashReporting.sendReport" = false;
          # Allow userChrome.css
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          # UX noise
          "accessibility.typeaheadfind.enablesound" = false;
          "general.autoScroll" = true;
          # Privacy
          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.userContext.enabled" = true;
          "privacy.userContext.ui.enabled" = true;
          "browser.send_pings" = false;
          "beacon.enabled" = false;
          "device.sensors.enabled" = false;
          "geo.enabled" = false;
          "network.dns.echconfig.enabled" = true;
          # Telemetry off
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "";
          "toolkit.telemetry.unified" = false;
          "extensions.webcompat-reporter.enabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "browser.ping-centre.telemetry" = false;
          "browser.urlbar.eventTelemetry.enabled" = false;
          # Disable bundled cruft
          "extensions.pocket.enabled" = false;
          "extensions.abuseReport.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          "browser.uitour.enabled" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          # Network prediction off
          "network.predictor.enabled" = false;
          "browser.urlbar.speculativeConnect.enabled" = false;
          # Web feature nukes
          "dom.push.enabled" = false;
          "dom.push.connection.enabled" = false;
          "dom.battery.enabled" = false;
          "dom.private-attribution.submission.enabled" = false;
        };

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

        search = {
          force = true;
          default = "Kagi";
          privateDefault = "ddg";

          inherit engines;
        };
      in
      {
        programs.firefox = {
          enable = true;

          policies = {
            AutofillAddressEnabled = false;
            AutofillCreditCardEnabled = false;
            DontCheckDefaultBrowser = true;
            NoDefaultBookmarks = lib.mkForce true;
            OfferToSaveLogins = false;
            TranslateEnabled = false;
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

          profiles = {
            default = {
              id = 0;
              isDefault = true;
              inherit
                search
                userChrome
                extraConfig
                settings
                ;
              bookmarks = {
                force = true;
                settings = [
                  {
                    name = "GitHub";
                    url = "https://github.com";
                  }
                  {
                    name = "Hacker News";
                    url = "https://news.ycombinator.com";
                  }
                  {
                    name = "Reddit";
                    url = "https://reddit.com";
                  }
                  {
                    name = "Dash";
                    url = "https://dash.peeraten.net";
                  }
                  {
                    name = "YouTube";
                    url = "https://youtube.com";
                  }
                ];
              };
            };
            work = {
              id = 1;
              inherit
                search
                userChrome
                extraConfig
                settings
                ;
              bookmarks = {
                force = true;
                settings = [
                  {
                    name = "GitHub";
                    url = "https://github.com";
                  }
                ];
              };
            };
          };
        };
      };
  };
}
