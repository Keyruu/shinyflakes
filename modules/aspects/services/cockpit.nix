{ inputs, ... }:
{
  den.aspects.services.cockpit = {
    nixos =
      { config, pkgs, lib, ... }:
      let
        my = config.services.my.cockpit;
        cockpitPkgs = import inputs.nixpkgs-cockpit-zfs { inherit (pkgs.stdenv.hostPlatform) system; };
      in
      {
        services.my.cockpit = {
          enable = true;
          port = 9090;
          domain = "mentat.lab.keyruu.de";
          proxy.enable = true;
          dashboard = {
            enable = true;
            title = "Cockpit";
            icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/cockpit.svg";
          };
        };

        services.cockpit = {
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
  };
}
