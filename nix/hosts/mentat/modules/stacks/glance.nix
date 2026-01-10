{ config, ... }:
let
  subreddits = [
    "selfhosted"
    "homelab"
    "homeassistant"
    "jellyfin"
    "linux"
    "ProgrammerHumor"
    "Steam"
    "Programming"
    "BuyFromEU"
    "LocalLLaMA"
    "niri"
    "ObsidianMD"
    "rust"
    "go"
    "neovim"
    "dumbphones"
    "Piracy"
    "Hetzner"
    "devops"
    "attackontitan"
    "immich"
    "unixporn"
    "NixOS"
    "commandline"
  ];
in
{
  services.glance = {
    enable = true;
    settings = {
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
                      limit = 4;
                    }
                    {
                      url = "https://ciechanow.ski/atom.xml";
                    }
                    {
                      url = "https://www.joshwcomeau.com/rss.xml";
                      title = "Josh Comeau";
                    }
                    {
                      url = "https://samwho.dev/rss.xml";
                    }
                    {
                      url = "https://ishadeed.com/feed.xml";
                      title = "Ahmad Shadeed";
                    }
                  ];
                }
                {
                  type = "twitch-channels";
                  channels = [
                    "theprimeagen"
                    "j_blow"
                    "piratesoftware"
                    "cohhcarnage"
                    "christitustech"
                    "EJ_SA"
                  ];
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "group";
                  widgets = map (subreddit: {
                    type = "reddit";
                    inherit subreddit;
                    show-thumbnails = true;
                  }) subreddits;
                }
                {
                  type = "videos";
                  channels = [
                    "UCXuqSBlHAE6Xw-yeJA0Tunw"
                    "UCR-DXc1voovS8nhAvccRZhg"
                    "UCsBjURrPoezykLs9EqgamOA"
                    "UCBJycsmduvYEL83R_U4JriQ"
                    "UCHnyfMqiRRG1u-2MsSQLbXA"
                  ];
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
}
