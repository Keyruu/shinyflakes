{ config, flake, ... }:
let
  my = config.services.my.paperless;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    paperlessSecretKey = { };
  };

  sops.templates."paperless.env" = {
    restartUnits = [ (quadlet.service containers.paperless-webserver) ];
    content = # sh
      ''
        PAPERLESS_SECRET_KEY=${config.sops.placeholder.paperlessSecretKey}
      '';
  };

  services.my.paperless = {
    port = 8000;
    domain = "paperless.lab.keyruu.de";
    proxy = {
      enable = true;
      whitelist.enable = true;
    };
    backup.enable = true;
    stack = {
      enable = true;
      user = {
        enable = true;
        name = "paperless";
        uid = 1006;
        group = "paperless";
        gid = 1006;
      };
      directories = [
        "data"
        "media"
        "export"
        "consume"
        {
          path = "redisdata";
          mode = "0750";
          owner = "999";
          group = "999";
        }
      ];
      network.enable = true;
      security.enable = true;

      containers = {
        broker = {
          containerConfig = {
            image = "docker.io/library/redis:8";
            volumes = [
              "${my.stack.path}/redisdata:/data"
            ];
            networkAliases = [ "broker" ];
          };
          security = {
            readOnlyRootFilesystem = false;
            dropAllCapabilities = false;
          };
        };

        webserver = {
          containerConfig = {
            image = "ghcr.io/paperless-ngx/paperless-ngx:2.20.13";
            publishPorts = [ "127.0.0.1:${toString my.port}:8000" ];
            volumes = [
              "${my.stack.path}/data:/usr/src/paperless/data"
              "${my.stack.path}/media:/usr/src/paperless/media"
              "${my.stack.path}/export:/usr/src/paperless/export"
              "${my.stack.path}/consume:/usr/src/paperless/consume"
            ];
            environments = {
              PAPERLESS_REDIS = "redis://${quadlet.alias containers.paperless-broker}:6379";
              USERMAP_UID = toString my.stack.user.uid;
              USERMAP_GID = toString my.stack.user.gid;
            };
            environmentFiles = [ config.sops.templates."paperless.env".path ];
            networkAliases = [ "webserver" ];
          };
          dependsOn = [ "broker" ];
        };
      };
    };
  };
}
