{ config, ... }:
{
  services.atuin = {
    enable = true;
    port = 8888;
    host = "127.0.0.1";
    openRegistration = false;
    database = {
      createLocally = true;
      uri = "postgresql:///atuin?host=/run/postgresql";
    };
  };

  services.nginx.virtualHosts."atuin.keyruu.de" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.atuin.port}";
      proxyWebsockets = true;
    };
  };
}
