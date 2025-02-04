{...}: 
  let
    malojaPath = "/etc/stacks/maloja/data";
  in {
  systemd.tmpfiles.rules = [
    "d ${malojaPath} 0755 root root"
  ];

  virtualisation.quadlet.containers.navidrome = {
    containerConfig = {
      image = "krateng/maloja:3.2.3";
      environments = {
        MALOJA_DATA_DIRECTORY = "/data";
      };
      volumes = [
        "${malojaPath}:/data"
      ];
      publishPorts = [
        "127.0.0.1:42010:42010"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts."fm.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:42010";
      proxyWebsockets = true;
    };
  };
}
