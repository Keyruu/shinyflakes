{ config, pkgs, ... }:
let
  stackPath = "/etc/stacks/karakeep";
  my = config.services.my.karakeep;
in
{
  sops.secrets = {
    karakeepNextauthSecret = { };
    karakeepMeiliMasterKey = { };
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
    "d ${stackPath}/meilisearch 0755 root root"
  ];

  sops.templates."karakeep.env" = {
    restartUnits = [
      "karakeep-web.service"
      "karakeep-meilisearch.service"
    ];
    content = # sh
      ''
        NEXTAUTH_SECRET=${config.sops.placeholder.karakeepNextauthSecret}
        MEILI_MASTER_KEY=${config.sops.placeholder.karakeepMeiliMasterKey}
        NEXTAUTH_URL=https://karakeep.lab.keyruu.de
        DISABLE_SIGNUPS=true
        OPENAI_API_KEY=${config.sops.placeholder.openaiKey}
      '';
  };

  services.my.karakeep = {
    port = 3000;
    domain = "karakeep.lab.keyruu.de";
    proxy = {
      enable = true;
      whitelist = {
        enable = true;
        people = [ "lucas" ];
      };
    };
    backup = {
      enable = true;
      paths = [ stackPath ];
      systemd.unit = "karakeep-*";
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.karakeep.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=karakeep" ];
      };

      containers = {
        karakeep-web = {
          containerConfig = {
            image = "ghcr.io/karakeep-app/karakeep:0.30.0";
            publishPorts = [ "127.0.0.1:${toString my.port}:3000" ];
            volumes = [
              "${stackPath}/data:/data"
            ];
            environments = {
              MEILI_ADDR = "http://meilisearch:7700";
              BROWSER_WEB_URL = "http://chrome:9222";
              DATA_DIR = "/data";
            };
            environmentFiles = [ config.sops.templates."karakeep.env".path ];
            labels = [
              "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
            ];
            networks = [ networks.karakeep.ref ];
          };
          serviceConfig = {
            Restart = "unless-stopped";
          };
          unitConfig = {
            After = [
              "karakeep-meilisearch.service"
              "karakeep-chrome.service"
            ];
            Requires = [
              "karakeep-meilisearch.service"
              "karakeep-chrome.service"
            ];
          };
        };

        karakeep-chrome = {
          containerConfig = {
            # renovate: ignore
            image = "gcr.io/zenika-hub/alpine-chrome:124";
            exec = "--no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-address=0.0.0.0 --remote-debugging-port=9222 --enable-features=ConversionMeasurement,AttributionReportingCrossAppWeb --hide-scrollbars";
            networks = [ networks.karakeep.ref ];
            networkAliases = [ "chrome" ];
            labels = [ "wud.watch=false" ];
          };
          serviceConfig = {
            Restart = "unless-stopped";
          };
        };

        karakeep-meilisearch = {
          containerConfig = {
            # renovate: ignore
            image = "getmeili/meilisearch:v1.13.3";
            environments = {
              MEILI_NO_ANALYTICS = "true";
            };
            environmentFiles = [ config.sops.templates."karakeep.env".path ];
            volumes = [
              "${stackPath}/meilisearch:/meili_data"
            ];
            networks = [ networks.karakeep.ref ];
            networkAliases = [ "meilisearch" ];
            labels = [ "wud.watch=false" ];
          };
          serviceConfig = {
            Restart = "unless-stopped";
          };
        };
      };
    };
}
