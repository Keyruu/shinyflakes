_:
{
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  services.nginx.virtualHosts."highwind.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:9090";
      proxyWebsockets = true;
    };
  };
}
