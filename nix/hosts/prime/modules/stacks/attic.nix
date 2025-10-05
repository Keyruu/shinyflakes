{ config, ... }:
let
  stackPath = "/etc/stacks/attic";
in
{
  sops.secrets = {
    atticCredentials = { };
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
  ];

  sops.templates."attic.env" = {
    restartUnits = [ "attic.service" ];
    content = ''
      ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64=${config.sops.placeholder.atticCredentials}
    '';
  };

  virtualisation.quadlet.containers = {
    attic = {
      containerConfig = {
        image = "ghcr.io/zhaofengli/attic:latest";
        publishPorts = [ "127.0.0.1:8080:8080" ];
        volumes = [
          "${stackPath}/data:/data"
          "/nix/store:/nix/store:ro"
        ];
        environments = {
          ATTIC_SERVER_LISTEN = "[::]:8080";
          ATTIC_SERVER_DATABASE_URL = "sqlite:///data/attic.db";
        };
        environmentFiles = [ config.sops.templates."attic.env".path ];
        labels = [
          "wud.tag.include=^latest$"
        ];
      };
      serviceConfig = {
        Restart = "always";
      };
    };
  };

  services.nginx.virtualHosts."cache.keyruu.de" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      proxyWebsockets = true;
      extraConfig = ''
        client_max_body_size 1G;
      '';
    };
  };
}
