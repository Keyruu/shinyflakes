{ config, lib, ... }:
let
  my = config.services.my.glance;

  subreddits = {
    self-hosted = [
      "selfhosted"
      "homelab"
      "homeassistant"
      "immich"
      "NixOS"
    ];
    linux = [
      "linux"
      "niri"
      "unixporn"
      "commandline"
    ];
    coding = [
      "neovim"
      "Programming"
      "ProgrammerHumor"
      "rust"
      "go"
    ];
    tech = [
      "Piracy"
      "dumbphones"
      "Steam"
    ];
  };

  youtubers = {
    theprimetime = "UCUyeluBRhGPCW4rPe_UvBZQ";
    primeagen = "UC8ENHE5xdFSwx71u3fDH5Xw";
    tom-delalande = "UCYuQjtwffrSIzfswH3V24mQ";
    spielundzeug = "UCM1jNA8DM90LE4ywxBe8RmA";
    ben-davis = "UCFvPgPdb_emE_bpMZq6hmJQ";
    fireship = "UCsBjURrPoezykLs9EqgamOA";
    ct3003 = "UC1t9VFj-O6YUDPQxaVg-NkQ";
    jeff-geerling = "UCR-DXc1voovS8nhAvccRZhg";
    everthing-smart-home = "UCrVLgIniVg6jW38uVqDRIiQ";
    hardware-haven = "UCgdTVe88YVSrOZ9qKumhULQ";
  };

  # dynamic bookmarks: all enabled services with proxy
  all_services = lib.listToAttrs (
    lib.sort (a: b: a.title < b.title) (
      lib.map (bm: { name = bm.title; value = bm; }) (
        builtins.mapAttrsToList (name: cfg: {
          title = name;
          url = "https://${cfg.domain}";
          same-tab = false;
        }) (lib.filterAttrs (_: cfg: cfg.enable && cfg.proxy.enable) config.services.my)
      )
    )
  );
in
{
  services = {
    my.glance = {
      enable = true;
      port = 5678;
      domain = "glance.lab.keyruu.de";
      proxy.enable = true;
    };
    glance = {
      inherit (my) enable;
      settings = {
        server = {
          host = "127.0.0.1";
          inherit (my) port;
        };
        pages = [
          # page 1 — all services
          {
            name = "Services";
            slug = "services";
            columns = [
              {
                size = "full";
                widgets = [
                  {
                    type = "bookmarks";
                    groups = [
                      {
                        title = "Services";
                        links = lib.mapAttrsToList (_: link: link) all_services;
                      }
                    ];
                  }
                ];
              }
            ];
          }
          # page 2 — social (reddit, youtube, hackernews, etc.)
          {
            name = "Social";
            slug = "social";
            columns = [
              {
                size = "small";
                widgets = [
                  {
                    type = "calendar";
                    first-day-of-week = "monday";
                  }
                  {
                    type = "rss";
                    limit = 10;
                    collapse-after = 3;
                    cache = "12h";
                    feeds = [
                      {
                        url = "https://selfh.st/rss/";
                        title = "selfh.st";
                      }
                      {
                        url = "https://console.dev/rss.xml";
                        title = "console.dev";
                      }
                      {
                        url = "https://joinemm.dev/rss.xml";
                        title = "Joinemm";
                      }
                    ];
                  }
                ];
              }
              {
                size = "full";
                widgets = [
                  {
                    type = "group";
                    widgets = lib.mapAttrsToList (category: subreddits: {
                      type = "reddit";
                      title = category;
                      subreddit = builtins.concatStringsSep "+" subreddits;
                      show-thumbnails = true;
                    }) subreddits;
                  }
                  {
                    type = "videos";
                    channels = builtins.attrValues youtubers;
                  }
                  {
                    type = "group";
                    widgets = [
                      {
                        type = "hacker-news";
                      }
                      {
                        type = "lobsters";
                      }
                    ];
                  }
                ];
              }
              {
                size = "small";
                widgets = [
                  {
                    type = "weather";
                    location = "Munich, Germany";
                    units = "metric";
                    hour-format = "24h";
                  }
                  {
                    type = "releases";
                    cache = "1d";
                    repositories = [
                      "glanceapp/glance"
                      "go-gitea/gitea"
                      "immich-app/immich"
                      "syncthing/syncthing"
                    ];
                  }
                ];
              }
            ];
          }
          # page 3 — infrastructure (server stats, monitoring, admin links)
          {
            name = "Infrastructure";
            slug = "infra";
            columns = [
              {
                size = "full";
                widgets = [
                  {
                    type = "server-stats";
                    servers = [
                      {
                        type = "local";
                        name = "Mentat";
                        hide-swap = false;
                        hide-mountpoints-by-default = false;
                        mountpoints = {
                          "/" = {
                            name = "Root";
                            hide = false;
                          };
                        };
                      }
                    ];
                  }
                  {
                    type = "monitor";
                    cache = "1m";
                    title = "Monitoring";
                    sites = [
                      {
                        title = "Cockpit";
                        url = "https://mentat.lab.keyruu.de";
                        icon = "si:red-hat";
                      }
                      {
                        title = "Grafana";
                        url = "https://monitoring.lab.keyruu.de";
                        icon = "si:grafana";
                      }
                      {
                        title = "Prometheus";
                        url = "https://monitoring.lab.keyruu.de/prometheus/";
                        icon = "si:prometheus";
                      }
                    ];
                  }
                  {
                    type = "bookmarks";
                    groups = [
                      {
                        title = "Admin";
                        links = [
                          {
                            title = "Cockpit";
                            url = "https://mentat.lab.keyruu.de";
                            icon = "si:red-hat";
                            same-tab = false;
                          }
                          {
                            title = "Grafana";
                            url = "https://monitoring.lab.keyruu.de";
                            icon = "si:grafana";
                            same-tab = false;
                          }
                          {
                            title = "Prometheus";
                            url = "https://monitoring.lab.keyruu.de/prometheus/";
                            icon = "si:prometheus";
                            same-tab = false;
                          }
                        ];
                      }
                    ];
                  }
                ];
              }
            ];
          }
        ];
      };
    };
  };
}
