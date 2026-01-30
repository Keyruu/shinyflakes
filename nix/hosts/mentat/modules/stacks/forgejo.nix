{ config, ... }:
let
  stackPath = "/etc/stacks/forgejo";
  my = config.services.my.forgejo;
  inherit (config.services) mesh;
in
{
  users = {
    groups.git.gid = 1004;
    users = {
      git = {
        isSystemUser = true;
        uid = 1004;
        group = "git";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 1000 1000"
  ];

  services.my.forgejo =
    let
      domain = "git.keyruu.de";
    in
    {
      port = 3004;
      inherit domain;
      proxy = {
        enable = true;
        cert = {
          provided = false;
          host = domain;
        };
      };
      backup = {
        enable = true;
        paths = [ stackPath ];
      };
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.forgejo.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=forgejo" ];
      };
      containers = {
        forgejo = {
          containerConfig = {
            image = "codeberg.org/forgejo/forgejo:14.0.2";
            publishPorts = [
              "127.0.0.1:${toString my.port}:3000"
              "127.0.0.1:222:22"
            ];
            volumes = [
              "${stackPath}/data:/data"
              "/etc/localtime:/etc/localtime:ro"
            ];
            environments = {
              USER_UID = "1004";
              USER_GID = "1004";
            };
            networks = [ networks.rybbit.ref ];
            networkAliases = [ "forgejo" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };
        anubis = {
          image = "ghcr.io/techarohq/anubis:v1.24.0";
          publishPorts = [
            "${mesh.ip}:${toString my.port}:3000"
          ];
          environments = {
            BIND = ":3000";
            TARGET = "http://forgejo:3000";
          };
        };
      };
    };

  services.nginx.virtualHosts = {
    "git.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;
      inherit (config.services.nginx.virtualHosts."${my.domain}") locations;
    };
  };
}

