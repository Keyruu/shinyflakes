# Cockpit admin UI — host-agnostic aspect. Each host including this
# aspect supplies its own `services.my.cockpit` config (domain, origins,
# proxy/dashboard/monitor toggles). The aspect handles the shared module
# wiring: firewall, port, plugins, WebService header config.
#
# `services.my.cockpit.origins` defaults to https/wss of `domain` when
# not set — so the common case (cockpit behind a TLS-terminating reverse
# proxy) needs only `domain`. Mesh-direct or other non-HTTPS hosts must
# set `origins` explicitly.
{ inputs, ... }:
{
  den.aspects.services.cockpit = {
    nixos =
      { config, pkgs, lib, ... }:
      let
        my = config.services.my.cockpit;
        cockpitPkgs = import inputs.nixpkgs-cockpit-zfs { inherit (pkgs.stdenv.hostPlatform) system; };

        originsList =
          if my.origins != null then
            my.origins
          else if my.domain != null then
            [
              "https://${my.domain}"
              "wss://${my.domain}"
            ]
          else
            [ ];
      in
      {
        assertions = [
          {
            assertion = my.enable -> originsList != [ ];
            message = "services.my.cockpit: `domain` or `origins` must be set when cockpit is enabled.";
          }
        ];

        networking.firewall.interfaces.${config.services.mesh.interface}.allowedTCPPorts = [ my.port ];

        services.my.cockpit = {
          enable = true;
          port = 9090;
        };

        services.cockpit = {
          inherit (my) enable port;
          plugins = [
            cockpitPkgs.cockpit-zfs
            pkgs.cockpit-podman
          ];
          settings = {
            WebService = {
              Origins = lib.mkForce (lib.concatStringsSep " " originsList);
              ProtocolHeader = "X-Forwarded-Proto";
              ForwardedForHeader = "X-Forwarded-For";
              # Allow HTTP connections from reverse proxy
              AllowUnencrypted = true;
            };
          };
        };
      };
  };
}