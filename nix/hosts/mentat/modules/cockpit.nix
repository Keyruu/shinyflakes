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
      plugins = [
        cockpitPkgs.cockpit-zfs
        pkgs.cockpit-podman
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
  };
}
