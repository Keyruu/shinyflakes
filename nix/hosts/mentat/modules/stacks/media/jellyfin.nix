{ config, ... }:
let
  my = config.services.my.jellyfin;
  jellyfinPath = "/etc/stacks/jellyfin";
in
{
  services.my.jellyfin = {
    port = 8096;
    domain = "jellyfin.lab.keyruu.de";
    proxy.enable = true;
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
        "127.0.0.1:${toString my.port}:${toString my.port}"
        "${config.services.mesh.ip}:${toString my.port}:${toString my.port}"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
