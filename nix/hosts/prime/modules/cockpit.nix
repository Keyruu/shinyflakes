{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  my = config.services.my.mentat-cockpit;
  cockpitPkgs = import inputs.nixpkgs-cockpit-zfs { inherit (pkgs.stdenv.hostPlatform) system; };
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
      plugins = [
        cockpitPkgs.cockpit-zfs
        pkgs.cockpit-podman
      ];
      settings = {
        WebService = {
          Origins = lib.mkForce "http://100.67.0.1:9090 ws://100.67.0.1:9090";
          ProtocolHeader = "X-Forwarded-Proto";
          ForwardedForHeader = "X-Forwarded-For";
          # Allow HTTP connections from nginx reverse proxy
          AllowUnencrypted = true;
        };
      };
    };
  };
}
