{
  config,
  pkgs,
  lib,
  ...
}:
let
  my = config.services.my.mentat-cockpit;
in
{
  networking.firewall.interfaces.mesh0.allowedTCPPorts = [ my.port ];

  services = {
    my.mentat-cockpit = {
      enable = true;
      port = 9090;
      domain = "prime.keyruu.de";
    };
    cockpit = {
      inherit (my) enable;
      inherit (my) port;
      plugins = with pkgs; [
        cockpit-zfs
        cockpit-podman
      ];
      settings = {
        WebService = {
          Origins = lib.mkForce "http://100.67.0.1 ws://100.67.0.1";
          ProtocolHeader = "X-Forwarded-Proto";
          ForwardedForHeader = "X-Forwarded-For";
          # Allow HTTP connections from nginx reverse proxy
          AllowUnencrypted = true;
        };
      };
    };
  };
}
