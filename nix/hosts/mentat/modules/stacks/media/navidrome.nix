{ config, ... }:
let
  stackPath = "/etc/stacks/navidrome/data";
  my = config.services.my.navidrome;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath} 0755 root root"
  ];

  services.my.navidrome = {
    port = 4533;
    domain = "navidrome.lab.keyruu.de";
    proxy.enable = true;
    backup = {
      enable = true;
      paths = [ stackPath ];
    };
  };

  virtualisation.quadlet.containers.navidrome = {
    containerConfig = {
      image = "deluan/navidrome:0.59.0";
      environments = {
        ND_LOGLEVEL = "info";
        ND_BASEURL = "https://navidrome.lab.keyruu.de";
      };
      volumes = [
        "${stackPath}:/data"
        "/main/media/Music/library:/music:ro"
      ];
      publishPorts = [
        "127.0.0.1:${toString my.port}:4533"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
