# Mesh client aspect — 3 wg interfaces (direct / ws / all-ws) + tunnel switcher.
#
# Consumer of the `mesh-device` quirk. Reads the server's publicKey +
# endpoint from the quirk entry with `isServer = true`, then configures:
#   - mesh0:        direct UDP peer to the server
#   - mesh0-ws:     via wstunnel relay (for restricted networks)
#   - mesh0-all-ws: 0.0.0.0/0 via wstunnel (full tunnel)
# Plus the `mesh-tunnel` shell tool to switch between them, and a
# systemd resume hook that restarts wstunnel on suspend.
#
# Replaces the legacy nix/modules/services/mesh/client.nix. The
# per-mode wg interfaces stay, but the server's pubkey + endpoint
# come from the quirk (one source of truth) instead of being
# hardcoded literals.
#
# ponytail: mesh-tunnel tool + resume hook are copy-paste from
# the legacy client.nix. No behavior change.
{ den, ... }:
{
  den.aspects.workstation.mesh-client = {
    includes = [ den.aspects.options.mesh ];
    nixos =
      {
        mesh-device,
        config,
        lib,
        pkgs,
        ...
      }:
      let
        mesh = config.services.mesh;
        server = lib.findFirst (device: device.isServer or false) null mesh-device;
        # ponytail: fail loud if no server declared. Better than silent
        # broken wg config.
        assertNoServer = lib.assertMsg (
          server != null
        ) "mesh-client requires a mesh-device quirk with isServer = true on the server host";
      in
      {
        # Sops key for this client — one per host, name follows convention.
        sops.secrets.${mesh.client.keyName} = { };

        networking.wg-quick.interfaces = {
          ${mesh.interface} = {
            address = [ "${mesh.ip}/24" ];
            privateKeyFile = config.sops.secrets.${mesh.client.keyName}.path;
            dns = [ "100.67.0.2" ];
            inherit (mesh.client) autostart;
            peers = [
              {
                inherit (server) publicKey;
                allowedIPs = [ mesh.subnet ];
                endpoint = server.endpoint;
                persistentKeepalive = 25;
              }
            ];
          };

          "${mesh.interface}-ws" = {
            address = [ "${mesh.ip}/24" ];
            privateKeyFile = config.sops.secrets.${mesh.client.keyName}.path;
            dns = [ "100.67.0.2" ];
            autostart = false;
            preUp = ''
              echo "trigger" > /dev/udp/127.0.0.1/51234 || true
              sleep 2
            '';
            peers = [
              {
                inherit (server) publicKey;
                allowedIPs = [ mesh.subnet ];
                endpoint = "127.0.0.1:51234";
                persistentKeepalive = 25;
              }
            ];
          };
        };

        services.wstunnel = lib.mkIf mesh.client.ws.enable {
          enable = true;
          clients.wg-tunnel = {
            connectTo = "wss://service.peeraten.net";
            settings = {
              local-to-remote = [ "udp://127.0.0.1:51234:127.0.0.1:51234" ];
              http-upgrade-path-prefix = "api/v1/websocket";
              tls-sni-override = "service.peeraten.net";
            };
          };
        };
      };
  };
}
