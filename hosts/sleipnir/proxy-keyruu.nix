{config, ...}: {
  services.nginx.virtualHosts."immich.keyruu.de" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://hati:2283";
      proxyWebsockets = true;
    };
  };
}

