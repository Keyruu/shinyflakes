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
          {
            name = "Home";
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
        ];
      };
    };
  };
}
