{
  config,
  pkgs,
  lib,
  perSystem,
  ...
}:
let
  my = config.services.my.mentat-cockpit;
in
{
  services = {
    my.mentat-cockpit = {
      enable = true;
      port = 9090;
      domain = "mentat.lab.keyruu.de";
      proxy.enable = true;
    };
    cockpit = {
      inherit (my) enable;
      inherit (my) port;
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
    nginx.virtualHosts."${my.domain}" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString my.port}";
        proxyWebsockets = true;
      };
    };
  };
}
