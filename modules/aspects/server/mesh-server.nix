# Mesh server aspect — wg interface + wstunnel relay + caddy vhost.
#
# Consumer of the `mesh-device` quirk. Each NixOS host that includes this
# aspect (or rather, the host aspect that includes this) emits a
# `mesh-device` quirk. This consumer builds the wg peer list from the
# collected quirk data, plus the unmanaged devices from den.people.*
# (simon/nadine guests don't have NixOS host entities).
#
# One host runs the server. Decide which via:
#   den.aspects.<server-host>.includes = [ den.aspects.server.mesh-server ];
# All other mesh-capable hosts use den.aspects.workstation.mesh-client.
#
# ponytail: caddy vhost + wstunnel config is copy-paste from the legacy
# nix/modules/services/mesh/server.nix. Replace once the wg key path
# (sops.placeholder.meshServerKey) is wired in the host's secrets.
{
  ...
}:
let

  # All devices to peer with: managed hosts (from mesh-device quirk) +
  # unmanaged guest devices (from den.people.*.devices, minus any that
  # overlap with managed hosts).
  peerFromQuirk = device: {
    publicKey = device.publicKey;
    allowedIPs = [ "${device.ip}/32" ] ++ (device.allowedIPs or [ ]);
    persistentKeepalive = 25;
  };
in
{
  den.aspects.server.mesh-server = {
    nixos =
      {
        mesh-device,
        config,
        lib,
        ...
      }:
      let
        mesh = config.services.mesh;
        managedPeers = lib.filter (device: !(device.isServer or false)) mesh-device;
        # Unmanaged guest devices — simon, nadine. Lucas's managed hosts
        # are already in mesh-devices. ponytail: filter overlaps by IP.
        guestPeers = lib.concatMap (
          person:
          lib.mapAttrsToList (
            _name: dev:
            peerFromQuirk {
              inherit (dev) publicKey ip allowedIPs;
            }
          ) person.devices
        ) (lib.attrValues (lib.filterAttrs (name: _: name != "lucas") config.den.people));
        allPeers = map peerFromQuirk managedPeers ++ guestPeers;

        ownKeyFile = config.sops.secrets.meshServerKey.path;
      in
      {
        sops.secrets.meshServerKey = {
          mode = "0600";
        };

        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = 1;
          "net.ipv6.conf.all.forwarding" = 1;
        };

        networking.firewall.allowedUDPPorts = [ 51234 ];
        networking.nat = {
          enable = true;
          internalInterfaces = [ mesh.interface ];
          externalInterface = "eth0";
        };

        networking.wg-quick.interfaces.${mesh.interface} = {
          address = [ "${mesh.ip}/24" ];
          listenPort = 51234;
          privateKeyFile = ownKeyFile;
          peers = allPeers;
        };

        services.wstunnel = {
          enable = true;
          servers.wg-tunnel = {
            listen = {
              enableHTTPS = false;
              host = "127.0.0.1";
              port = 51233;
            };
            settings = {
              restrict-to = [
                {
                  host = "127.0.0.1";
                  port = 51234;
                }
              ];
            };
          };
        };

        services.caddy.virtualHosts = {
          "service.peeraten.net".extraConfig = "reverse_proxy 127.0.0.1:51233";
          "mesh.peeraten.net".extraConfig = "reverse_proxy 127.0.0.1:51233";
        };
      };
  };
}
