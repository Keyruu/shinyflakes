{ config, flake, ... }:
let
  my = config.services.my.karakeep;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    karakeepNextauthSecret = { };
    karakeepMeiliMasterKey = { };
  };

  sops.templates."karakeep.env" = {
    restartUnits = map quadlet.service [
      containers.karakeep-web
      containers.karakeep-meilisearch
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
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        "data"
        "meilisearch"
      ];
      network.enable = true;
      containers = with containers; {
        members = [
          karakeep-web
          karakeep-chrome
          karakeep-meilisearch
        ];
        main = karakeep-web;
        internalPort = 3000;
        security.enable = true;
      };
    };
  };

  virtualisation.quadlet.containers = {
    karakeep-web = {
      containerConfig = {
        image = "ghcr.io/karakeep-app/karakeep:0.31.0";
        volumes = [
          "${my.stack.path}/data:/data"
        ];
        environments = {
          MEILI_ADDR = "http://${quadlet.alias containers.karakeep-meilisearch}:7700";
          BROWSER_WEB_URL = "http://${quadlet.alias containers.karakeep-chrome}:9222";
          DATA_DIR = "/data";
        };
        environmentFiles = [ config.sops.templates."karakeep.env".path ];
      };
      unitConfig = {
        After = [
          containers.karakeep-meilisearch.ref
          containers.karakeep-chrome.ref
        ];
        Requires = [
          containers.karakeep-meilisearch.ref
          containers.karakeep-chrome.ref
        ];
      };
    };

    karakeep-chrome = {
      containerConfig = {
        image = "gcr.io/zenika-hub/alpine-chrome:124";
        exec = "--no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-address=0.0.0.0 --remote-debugging-port=9222 --enable-features=ConversionMeasurement,AttributionReportingCrossAppWeb --hide-scrollbars";
        networkAliases = [ "chrome" ];
      };
    };

    karakeep-meilisearch = {
      containerConfig = {
        image = "getmeili/meilisearch:v1.13.3";
        environments = {
          MEILI_NO_ANALYTICS = "true";
        };
        environmentFiles = [ config.sops.templates."karakeep.env".path ];
        volumes = [
          "${my.stack.path}/meilisearch:/meili_data"
        ];
        networkAliases = [ "meilisearch" ];
      };
    };
  };
}
