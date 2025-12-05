{ config, ... }:
let
  stackPath = "/etc/stacks/radicale";
in
{
  # Directory creation
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

  environment.etc."stacks/radicale/config/config".text = ''
    [server]
    hosts = 0.0.0.0:5232

    [auth]
    type = htpasswd
    htpasswd_filename = /config/users
    htpasswd_encryption = bcrypt

    [storage]
    filesystem_folder = /data/collections
  '';

  # Quadlet configuration
  virtualisation.quadlet.containers = {
    radicale = {
      containerConfig = {
        image = "tomsquest/docker-radicale:3.5.9.0";
        publishPorts = [
          "127.0.0.1:5232:5232"
          "100.64.0.1:5232:5232"
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

  # Nginx reverse proxy
  services.nginx.virtualHosts."calendar.peeraten.net" = {
    useACMEHost = "calendar.peeraten.net";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:5232";
      proxyWebsockets = true;
    };
  };
}
