{ config, ... }:
let
  stackPath = "/etc/stacks/pinchflat";
  my = config.services.my.pinchflat;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 root root"
  ];

  services.my.pinchflat = {
    port = 8945;
    domain = "pinchflat.lab.keyruu.de";
    proxy.enable = true;
  };

  virtualisation.quadlet = {
    containers = {
      pinchflat = {
        containerConfig = {
          image = "ghcr.io/kieraneglin/pinchflat:latest";
          publishPorts = [ "127.0.0.1:${toString my.port}:8945" ];
          volumes = [
            "${stackPath}/config:/config"
            "/main/media/YouTube:/downloads"
          ];
          environments = {
            TZ = "Europe/Berlin";
          };
          labels = [
            "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
          ];
        };
        serviceConfig = {
          Restart = "unless-stopped";
        };
      };
    };
  };
}
