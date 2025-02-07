{ config, ... }:
{
  sops.templates."homepage.env".content = /* env */ ''
    HOMEPAGE_VAR_RADARR_KEY=${config.sops.placeholder.radarrKey}
    HOMEPAGE_VAR_SONARR_KEY=${config.sops.placeholder.sonarrKey}
    HOMEPAGE_VAR_LIDARR_KEY=${config.sops.placeholder.lidarrKey}
    HOMEPAGE_VAR_BAZARR_KEY=${config.sops.placeholder.bazarrKey}
    HOMEPAGE_VAR_PROWLARR_KEY=${config.sops.placeholder.prowlarrKey}
    HOMEPAGE_VAR_QBITTORRENT_USERNAME=${config.sops.placeholder.qbittorrentUsername}
    HOMEPAGE_VAR_QBITTORRENT_PASSWORD=${config.sops.placeholder.qbittorrentPassword}
    HOMEPAGE_VAR_JELLYFIN_KEY=${config.sops.placeholder.jellyfinKey}
    HOMEPAGE_VAR_BESZEL_USERNAME=${config.sops.placeholder.beszelUsername}
    HOMEPAGE_VAR_BESZEL_PASSWORD=${config.sops.placeholder.beszelPassword}
  '';

  systemd.services.homepage-dashboard = {
    serviceConfig = {
      SupplementaryGroups = [ "podman" ];
    };
  };

  services.homepage-dashboard = {
    enable = true;
    environmentFile = config.sops.templates."homepage.env".path;
    listenPort = 7122;
    docker = {
      highwind = {
        socket = "/run/podman/podman.sock";
      };
    };
    widgets = [
      {
        datetime = {
          text_size = "xl";
          format = {
            timeStyle = "short";
          };
        };
      }
      {
        search = {
          provider = "custom";
          url = "https://search.lab.keyruu.de/search?q=";
          target = "_blank";
          showSearchSuggestions = false;
        };
      }
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
    ];
    settings = {
      locale = "de";
      headerStyle = "boxed";
      layout = [
        {
          "media" = {
            style = "row";
            columns = "3";
          };
        }
      ];
    };
    services = [
      {
        "media" = [
          {
            radarr = {
              icon = "radarr.png";
              href = "https://radarr.lab.keyruu.de";
              server = "highwind";
              container = "torrent-radarr";
              siteMonitor = "https://radarr.lab.keyruu.de";
              widget = {
                type = "radarr";
                url = "http://127.0.0.1:7878";
                key = "{{HOMEPAGE_VAR_RADARR_KEY}}";
              };
            };
          }
          {
            sonarr = {
              icon = "sonarr.png";
              href = "https://sonarr.lab.keyruu.de";
              server = "highwind";
              container = "torrent-sonarr";
              siteMonitor = "http://127.0.0.1:8989";
              widget = {
                type = "sonarr";
                url = "http://127.0.0.1:8989";
                key = "{{HOMEPAGE_VAR_SONARR_KEY}}";
              };
            };
          }
          {
            lidarr = {
              icon = "lidarr.png";
              href = "https://lidarr.lab.keyruu.de";
              server = "highwind";
              container = "torrent-lidarr";
              siteMonitor = "http://127.0.0.1:8686";
              widget = {
                type = "lidarr";
                url = "http://127.0.0.1:8686";
                key = "{{HOMEPAGE_VAR_LIDARR_KEY}}";
              };
            };
          }
          {
            bazarr = {
              icon = "bazarr.png";
              href = "https://bazarr.lab.keyruu.de";
              server = "highwind";
              container = "torrent-bazarr";
              siteMonitor = "http://127.0.0.1:6767";
              widget = {
                type = "bazarr";
                url = "http://127.0.0.1:6767";
                key = "{{HOMEPAGE_VAR_BAZARR_KEY}}";
              };
            };
          }
          {
            prowlarr = {
              icon = "prowlarr.png";
              href = "https://prowlarr.lab.keyruu.de";
              server = "highwind";
              container = "torrent-prowlarr";
              siteMonitor = "http://127.0.0.1:9696";
              widget = {
                type = "prowlarr";
                url = "http://127.0.0.1:9696";
                key = "{{HOMEPAGE_VAR_PROWLARR_KEY}}";
              };
            };
          }
          {
            qbittorrent = {
              icon = "qbittorrent.png";
              href = "https://qbittorrent.lab.keyruu.de";
              server = "highwind";
              container = "torrent-qbittorrent";
              siteMonitor = "http://127.0.0.1:8080";
              widget = {
                type = "qbittorrent";
                url = "http://127.0.0.1:8080";
                username = "{{HOMEPAGE_VAR_QBITTORRENT_USERNAME}}";
                password = "{{HOMEPAGE_VAR_QBITTORRENT_PASSWORD}}";
              };
            };
          }
          {
            jellyfin = {
              icon = "jellyfin.png";
              href = "https://jellyfin.lab.keyruu.de";
              server = "highwind";
              container = "jellyfin";
              siteMonitor = "http://127.0.0.1:8096";
              widget = {
                type = "jellyfin";
                url = "http://127.0.0.1:8096";
                key = "{{HOMEPAGE_VAR_JELLYFIN_KEY}}";
                enableBlocks = true;
                enableUser = true;
                showEpisodeNumber = false;
                enableNowPlaying = false;
              };
            };
          }
          {
            immich = {
              icon = "immich.png";
              href = "https://immich.lab.keyruu.de";
              server = "highwind";
              container = "immich-server";
              siteMonitor = "http://127.0.0.1:2283";
            };
          }
          {
            slskd = {
              icon = "slskd.png";
              href = "https://slskd.lab.keyruu.de";
              server = "highwind";
              container = "torrent-slskd";
              siteMonitor = "http://127.0.0.1:5030";
            };
          }
          {
            navidrome = {
              icon = "navidrome.png";
              href = "https://navidrome.lab.keyruu.de";
              server = "highwind";
              container = "navidrome";
              siteMonitor = "http://127.0.0.1:4533";
            };
          }
        ];
      }
      {
        "misc" = [
          {
            home-assistant = {
              icon = "home-assistant.png";
              href = "https://hass.peeraten.net";
              server = "highwind";
              container = "home-assistant";
              siteMonitor = "http://127.0.0.1:8123";
            };
          }
          {
            headscale = {
              icon = "headscale.png";
              href = "https://headscale.peeraten.net/admin";
              siteMonitor = "https://headscale.peeraten.net/admin";
            };
          }
          {
            adguard-home = {
              icon = "adguard-home.png";
              href = "https://adguard.port.peeraten.net";
              siteMonitor = "https://adguard.port.peeraten.net";
              widget = {
                type = "adguard";
                url = "https://adguard.port.peeraten.net";
              };
            };
          }
          {
            ai = {
              icon = "open-webui.png";
              href = "https://ai.lab.keyruu.de";
              siteMonitor = "http://127.0.0.1:8081";
            };
          }
          {
            search = {
              icon = "searxng.png";
              href = "https://search.lab.keyruu.de";
              server = "highwind";
              container = "searxng-server";
              siteMonitor = "http://127.0.0.1:4899";
            };
          }
          {
            traccar = {
              icon = "traccar.png";
              href = "https://traccar.peeraten.net";
              server = "highwind";
              container = "traccar";
              siteMonitor = "http://127.0.0.1:5785";
            };
          }
          {
            mealie = {
              icon = "mealie.png";
              href = "https://mealie.zimtix.de";
              siteMonitor = "https://mealie.zimtix.de";
            };
          }
        ];
      }
      {
        "monitoring" = [
          {
            grafana = {
              icon = "grafana.png";
              href = "https://monitoring.lab.keyruu.de";
              siteMonitor = "http://127.0.0.1:3010";
            };
          }
          {
            prometheus = {
              icon = "prometheus.png";
              href = "https://monitoring.lab.keyruu.de/prometheus";
              siteMonitor = "http://127.0.0.1:3020/prometheus";
              widget = {
                type = "prometheus";
                url = "http://127.0.0.1:3020/prometheus";
              };
            };
          }
          {
            cockpit = {
              icon = "cockpit.png";
              href = "https://highwind.lab.keyruu.de";
              siteMonitor = "http://127.0.0.1:9090";
            };
          }
          {
            scrutiny = {
              icon = "scrutiny.png";
              href = "https://scrutiny.lab.keyruu.de";
              server = "highwind";
              container = "scrutiny";
              siteMonitor = "http://127.0.0.1:6333";
              widget = {
                type = "scrutiny";
                url = "http://127.0.0.1:6333";
              };
            };
          }
          {
            beszel = {
              icon = "beszel.png";
              href = "https://beszel.lab.keyruu.de";
              siteMonitor = "http://127.0.0.1:7220";
              widget = {
                type = "beszel";
                url = "http://127.0.0.1:7220";
                username = "{{HOMEPAGE_VAR_BESZEL_USERNAME}}";
                password = "{{HOMEPAGE_VAR_BESZEL_PASSWORD}}";
                version = 2;
              };
            };
          }
        ];
      }
    ];
  };

  services.nginx.virtualHosts."home.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.homepage-dashboard.listenPort}";
      proxyWebsockets = true;
    };
  };
}
