{
  ...
}:
{
  den.aspects.browsers.firefox = {
    homeManager =
      {
        pkgs,
        lib,
        config,
        self',
        ...
      }:
      let
        betterfox = self'.packages.betterfox;

        extraConfig = builtins.concatStringsSep "\n" [
          (builtins.readFile "${betterfox}/Securefox.js")
          (builtins.readFile "${betterfox}/Fastfox.js")
          (builtins.readFile "${betterfox}/Peskyfox.js")
        ];

        settings = {
          # General
          "intl.accept_languages" = "en-US,en";
          "browser.startup.page" = 3;
          "browser.ctrlTab.sortByRecentlyUsed" = true;
          # Vertical tabs (needs revamped sidebar, else Firefox resets the pref)
          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;
          # Bookmarks bar visible on every page, not just the new-tab page
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.bookmarks.addedImportButton" = true;
          # Clicking a bookmark replaces the current tab by default.
          "browser.tabs.loadBookmarksInTabs" = true;
          "browser.download.useDownloadDir" = false;
          "browser.translations.neverTranslateLanguages" = "de";
          "privacy.clearOnShutdown.history" = false;
          # Hi-DPI
          "layout.css.devPixelsPerPx" = "-1";
          # Dev console chrome
          "devtools.chrome.enabled" = true;
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
          # Telemetry off — Securefox already sets toolkit.telemetry.*,
          # datareporting.policy.dataSubmissionEnabled (as "data:,") and
          # browser.tabs.crashReporting.sendReport.
          "extensions.webcompat-reporter.enabled" = false;
          "browser.ping-centre.telemetry" = false;
          "browser.urlbar.eventTelemetry.enabled" = false;
          # Disable bundled cruft
          "extensions.pocket.enabled" = false;
          "extensions.abuseReport.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          # Network prediction off
          "network.predictor.enabled" = false;
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
          # The firefox wrapper sets MOZ_LEGACY_PROFILES=1, which keeps
          # Firefox on the pre-67 single-profile layout at
          # ~/.mozilla/firefox/. HM's default configPath is XDG-based
          # (~/.config/mozilla/firefox) since stateVersion 26.05, so
          # force both profiles.ini and the profile dirs to the legacy
          # path so Firefox actually reads them.
          configPath = lib.mkForce ".mozilla/firefox";

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

                "admin@2fas.com" = {
                  install_url = moz "2fas-two-factor-authentication";
                  installation_mode = "force_installed";
                  updates_disabled = true;
                };

                "enhancerforyoutube@maximerf.addons.mozilla.org" = {
                  install_url = moz "enhancer-for-youtube";
                  installation_mode = "force_installed";
                  updates_disabled = true;
                };

                "{81b74d53-9416-4fb3-afa2-ab46684b253b}" = {
                  install_url = moz "tabwrangler";
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
                extraConfig
                settings
                ;
              bookmarks = {
                force = true;
                # A directory with toolbar = true *is* the Bookmarks Toolbar (HM
                # forces its label), so these land on the bar.
                settings = [
                  {
                    name = "Bookmarks Toolbar";
                    toolbar = true;
                    bookmarks = [
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
                  }
                ];
              };
            };
            work = {
              id = 1;
              inherit
                search
                extraConfig
                settings
                ;
            };
          };
        };
        # Stable path for the generated bookmarks.html. HM also forces
        # browser.places.importBookmarksHTML = true in user.js, so Firefox
        # re-imports it on every launch (replace: true), discarding UI edits.
        home.file = lib.mapAttrs' (
          name: _:
          lib.nameValuePair ".local/share/firefox-bookmarks/${name}.html" {
            source = config.programs.firefox.profiles.${name}.bookmarks.configFile;
          }
        ) (
          lib.filterAttrs (_: p: p.bookmarks.configFile != null) config.programs.firefox.profiles
        );
      };
  };
}
