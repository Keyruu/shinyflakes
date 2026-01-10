{ config, ... }:
let
  subscriptions = [
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
  sops.templates."redlib.env" = {
    restartUnits = [ "redlib.service" ];
    content = ''
      REDLIB_SFW_ONLY=on
      REDLIB_ROBOTS_DISABLE_INDEXING=off
      REDLIB_PUSHSHIFT_FRONTEND=undelete.pullpush.io

      REDLIB_DEFAULT_THEME=dark
      REDLIB_DEFAULT_FRONT_PAGE=default
      REDLIB_DEFAULT_LAYOUT=card
      REDLIB_DEFAULT_WIDE=off
      REDLIB_DEFAULT_POST_SORT=hot
      REDLIB_DEFAULT_COMMENT_SORT=confidence
      REDLIB_DEFAULT_BLUR_SPOILER=on
      REDLIB_DEFAULT_SHOW_NSFW=off
      REDLIB_DEFAULT_BLUR_NSFW=on
      REDLIB_DEFAULT_AUTOPLAY_VIDEOS=off
      REDLIB_DEFAULT_SUBSCRIPTIONS=${builtins.concatStringsSep "+" subscriptions}
      REDLIB_DEFAULT_FILTERS=
      REDLIB_DEFAULT_HIDE_AWARDS=on
      REDLIB_DEFAULT_HIDE_SIDEBAR_AND_SUMMARY=off
      REDLIB_DEFAULT_DISABLE_VISIT_REDDIT_CONFIRMATION=off
      REDLIB_DEFAULT_HIDE_SCORE=off
      REDLIB_DEFAULT_FIXED_NAVBAR=on
    '';
  };

  # 4. Quadlet configuration for redlib
  virtualisation.quadlet = {
    containers = {
      redlib = {
        containerConfig = {
          image = "quay.io/redlib/redlib:latest";
          publishPorts = [ "127.0.0.1:8033:8080" ];
          user = "65534"; # nobody user
          environmentFiles = [ config.sops.templates."redlib.env".path ];
          noNewPrivileges = true;
          readOnly = true;
          healthCmd = "wget --no-verbose --tries=1 --spider --quiet http://localhost:8080/settings";
          healthInterval = "5m";
          healthTimeout = "3s";
          healthRetries = 3;
          healthStartPeriod = "30s";
        };

        serviceConfig = {
          Restart = "always";
        };
      };
    };
  };

  services.nginx.virtualHosts."redlib.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8033";
      proxyWebsockets = true;
    };
  };
}
