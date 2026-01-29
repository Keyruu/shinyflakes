{ config, ... }:
let
  stackPath = "/etc/stacks/forgejo";
  my = config.services.my.forgejo;
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

  virtualisation.quadlet = {
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
        };
        serviceConfig = {
          Restart = "always";
        };
      };
    };
  };
}

