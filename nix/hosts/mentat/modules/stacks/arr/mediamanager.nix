{ config, ... }:
let
  stackPath = "/etc/stacks/mediamanager";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
    "d ${stackPath}/config 0755 root root"
    "d ${stackPath}/postgres 0770 999 999"
  ];

  sops = {
    secrets = {
      sabnzbdKey = { };
      prowlarrKey = { };
      mediamanagerDbPassword = { };
      mediamanagerTokenSecret = { };
    };

    templates."mediamanager.toml" = {
      restartUnits = [ "mediamanager.service" ];
      content = # ini
        ''
          [misc]
          frontend_url = "https://mediamanager.lab.keyruu.de" # note the lack of a trailing slash
          cors_urls = ["https://mediamanager.lab.keyruu.de"] # note the lack of a trailing slash

          image_directory = "/data/images"
          tv_directory = "/data/Series"
          movie_directory = "/data/Movies"
          torrent_directory = "/data/downloads" # this is where MediaManager will search for the downloaded torrents and usenet files

          [[misc.tv_libraries]]
          name = "Anime"
          path = "/data/Anime"

          [database]
          host = "localhost"
          port = 5432
          user = "MediaManager"
          password = "${config.sops.placeholder.mediamanagerDbPassword}"
          dbname = "MediaManager"

          [auth]
          email_password_resets = false

          token_secret = "${config.sops.placeholder.mediamanagerTokenSecret}"
          session_lifetime = 86400

          admin_emails = ["me@keyruu.de"]


          [torrents]
          [torrents.sabnzbd]
          enabled = true
          host = "http://localhost"
          port = 8085
          api_key = "${config.sops.placeholder.sabnzbdKey}"
          base_path = "/api"

          [indexers]
          [indexers.prowlarr]
          enabled = true
          url = "http://localhost:9696"
          api_key = "${config.sops.placeholder.prowlarrKey}"
          reject_torrents_on_url_error = true
          timeout_seconds = 60
          follow_redirects = false
        '';
    };
    templates."mediamanagerDb.env" = {
      restartUnits = [ "mediamanager-db.service" ];
      content = # env
        ''
          POSTGRES_USER=MediaManager
          POSTGRES_DB=MediaManager
          POSTGRES_PASSWORD=${config.sops.placeholder.mediamanagerDbPassword}
        '';
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        mediamanager-db = {
          containerConfig = {
            image = "docker.io/library/postgres:17";
            volumes = [ "${stackPath}/postgres:/var/lib/postgresql/data" ];
            environmentFiles = [ config.sops.templates."mediamanagerDb.env".path ];
            healthCmd = "pg_isready -d MediaManager -U MediaManager";
            healthInterval = "10s";
            healthTimeout = "5s";
            healthRetries = 5;
            networks = [
              "torrent-gluetun.container"
            ];
          };
          serviceConfig = {
            Restart = "unless-stopped";
          };
        };

        mediamanager-server = {
          containerConfig = {
            image = "ghcr.io/maxdorninger/mediamanager/mediamanager:1.11.1";
            volumes = [
              "/main/media:/data"
              "${stackPath}/config:/app/config"
              "${config.sops.templates."mediamanager.toml".path}:/app/config/config.toml:ro"
            ];
            environments = {
              CONFIG_DIR = "/app/config";
              PORT = "8001";
            };
            networks = [
              "torrent-gluetun.container"
            ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [ "mediamanager-db.service" ];
            Requires = [ "mediamanager-db.service" ];
          };
        };
        torrent-gluetun.containerConfig.publishPorts = [
          "127.0.0.1:8001:8001"
        ];
      };
    };

  services.nginx.virtualHosts."mediamanager.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8001";
      proxyWebsockets = true;
    };
  };
}
