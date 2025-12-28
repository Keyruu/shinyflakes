{ pkgs, ... }:
{
  services.cockpit = {
    enable = true;
    port = 9090;
    plugins = with pkgs; [
      cockpit-zfs
    ];
    settings = {
      WebService = {
        ProtocolHeader = "X-Forwarded-Proto";
        ForwardedForHeader = "X-Forwarded-For";
        # Allow HTTP connections from nginx reverse proxy
        AllowUnencrypted = true;
      };
    };
  };

  services.nginx.virtualHosts."mentat.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:9090";
      proxyWebsockets = true;
    };
  };
}
