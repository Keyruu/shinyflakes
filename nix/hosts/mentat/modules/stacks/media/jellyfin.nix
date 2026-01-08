{ config, ... }:
let
  cfg = config.services.my.jellyfin;
  jellyfinPath = "/etc/stacks/jellyfin";
in
{
  services.my.jellyfin = {
    enable = true;
    port = 8096;
    domain = "jellyfin.lab.keyruu.de";
    access = [ "lucas" ];
  };

  systemd.tmpfiles.rules = [
    "d ${jellyfinPath}/config 0770 root root"
    "d ${jellyfinPath}/cache 0770 root root"
  ];

  virtualisation.quadlet.containers.jellyfin = {
    containerConfig = {
      image = "ghcr.io/jellyfin/jellyfin:10.11.5";
      environments = {
      };
      volumes = [
        "${jellyfinPath}/config:/config"
        "${jellyfinPath}/cache:/cache"
        "/main/media:/media"
      ];
      publishPorts = [
        "127.0.0.1:${cfg.port}:${cfg.port}"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts."${cfg.domain}" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${cfg.port}";
      proxyWebsockets = true;
    };
  };
}
