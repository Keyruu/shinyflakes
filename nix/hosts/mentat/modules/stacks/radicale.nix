{ config, pkgs, ... }:
let
  stackPath = "/etc/stacks/radicale";
  my = config.services.my.radicale;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0750 2999 2999"
    "d ${stackPath}/config 0750 2999 2999"
  ];

  users.groups.radicale.gid = 2999;
  users.users.radicale = {
    uid = 2999;
    isSystemUser = true;
    group = "radicale";
  };

  sops.secrets.radicaleUsers = {
    mode = "0440";
    owner = "radicale";
    group = "radicale";
  };

  services.my.radicale =
    let
      domain = "calendar.peeraten.net";
    in
    {
      enable = true;
      port = 5232;
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

  environment.etc."stacks/radicale/config/config".text = ''
    [server]
    hosts = 0.0.0.0:${toString my.port}

    [auth]
    type = htpasswd
    htpasswd_filename = /config/users
    htpasswd_encryption = bcrypt

    [storage]
    filesystem_folder = /data/collections
  '';

  virtualisation.quadlet.containers = {
    radicale = {
      containerConfig = {
        image = "tomsquest/docker-radicale:3.6.1.0";
        publishPorts = [
          "127.0.0.1:${toString my.port}:5232"
          "${config.services.mesh.ip}:${toString my.port}:5232"
        ];
        volumes = [
          "${stackPath}/data:/data"
          "${stackPath}/config/config:/config/config:ro"
          "${config.sops.secrets.radicaleUsers.path}:/config/users:ro"
        ];
        labels = [
          "wud.tag.include=^\\d+\\.\\d+\\.\\d+\\.\\d+$"
        ];
      };
      serviceConfig = {
        Restart = "always";
      };
      unitConfig = {
        X-RestartTrigger = [
          "${config.environment.etc."stacks/radicale/config/config".source}"
        ];
      };
    };
  };
}
