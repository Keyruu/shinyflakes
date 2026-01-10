{ config, ... }:
let
  stackPath = "/etc/stacks/radicale";
  inherit (config.services) mesh;
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

  services.my.radicale = {
    enable = true;
    port = 5232;
  };

  networking.firewall.interfaces = {
    "${mesh.interface}".allowedTCPPorts = [ my.port ];
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
        image = "tomsquest/docker-radicale:3.5.10.0";
        publishPorts = [
          "127.0.0.1:${toString my.port}:${toString my.port}"
          "${config.services.mesh.ip}:${toString my.port}:${toString my.port}"
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

  security.acme = {
    certs."calendar.peeraten.net" = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  services.nginx.virtualHosts."calendar.peeraten.net" = {
    useACMEHost = "calendar.peeraten.net";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString my.port}";
      proxyWebsockets = true;
    };
  };
}
