{...}:
  let
    navidromePath = "/etc/stacks/navidrome/data";
  in {
  systemd.tmpfiles.rules = [
    "d ${navidromePath} 0755 root root"
  ];

  virtualisation.quadlet.containers.navidrome = {
    containerConfig = {
      image = "deluan/navidrome:0.55.2";
      environments = {
        ND_LOGLEVEL = "info";
        ND_BASEURL = "https://navidrome.lab.keyruu.de";
      };
      volumes = [
        "${navidromePath}:/data"
        "/main/media/Music/library:/music:ro"
      ];
      publishPorts = [
        "127.0.0.1:4533:4533"
      ];
      labels = [
        "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts."navidrome.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:4533";
      proxyWebsockets = true;
    };
  };
}
