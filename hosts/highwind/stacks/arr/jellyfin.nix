{ ... }:
let
  jellyfinPath = "/etc/stacks/jellyfin";
in
{
  systemd.tmpfiles.rules = [
    "d ${jellyfinPath}/config 0770 root root"
    "d ${jellyfinPath}/cache 0770 root root"
  ];

  virtualisation.quadlet.containers.jellyfin = {
    containerConfig = {
      image = "ghcr.io/jellyfin/jellyfin:10.10.7";
      environments = {
      };
      volumes = [
        "${jellyfinPath}/config:/config"
        "${jellyfinPath}/cache:/cache"
        "/main/media:/media"
      ];
      publishPorts = [
        "127.0.0.1:8096:8096"
      ];
      labels = [
        "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts."jellyfin.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8096";
      proxyWebsockets = true;
    };
  };
}
