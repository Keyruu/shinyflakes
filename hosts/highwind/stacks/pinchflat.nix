{ config, ... }:
let
  stackPath = "/etc/stacks/pinchflat";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 root root"
  ];

  virtualisation.quadlet = {
    containers = {
      pinchflat = {
        containerConfig = {
          image = "ghcr.io/kieraneglin/pinchflat:latest";
          publishPorts = [ "127.0.0.1:8945:8945" ];
          volumes = [
            "${stackPath}/config:/config"
            "/main/media/YouTube:/downloads"
          ];
          environments = {
            TZ = "America/New_York";
          };
          labels = [
            "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
          ];
          networks = [ networks.pinchflat.ref ];
        };
        serviceConfig = {
          Restart = "unless-stopped";
        };
      };
    };
  };

  services.nginx.virtualHosts."pinchflat.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8945";
      proxyWebsockets = true;
    };
  };
}
