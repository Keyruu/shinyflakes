{ pkgs, lib, perSystem, ... }:
{
  services.cockpit = {
    enable = true;
    port = 9090;
    plugins = with pkgs; [
      cockpit-zfs
      perSystem.self.cockpit-podman
    ];
    settings = {
      WebService = {
        Origins = lib.mkForce "https://mentat.lab.keyruu.de wss://mentat.lab.keyruu.de";
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
