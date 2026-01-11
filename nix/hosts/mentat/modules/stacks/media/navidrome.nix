{ config, ... }:
let
  navidromePath = "/etc/stacks/navidrome/data";
  my = config.services.my.navidrome;
in
{
  systemd.tmpfiles.rules = [
    "d ${navidromePath} 0755 root root"
  ];

  services.my.navidrome = {
    port = 4533;
    domain = "navidrome.lab.keyruu.de";
  };

  virtualisation.quadlet.containers.navidrome = {
    containerConfig = {
      image = "deluan/navidrome:0.59.0";
      environments = {
        ND_LOGLEVEL = "info";
        ND_BASEURL = "https://navidrome.lab.keyruu.de";
      };
      volumes = [
        "${navidromePath}:/data"
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

  services.nginx.virtualHosts."${my.domain}" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString my.port}";
      proxyWebsockets = true;
    };
  };
}
