# Pipe policies for the people + mesh + services data flow.
#
# Cross-entity aggregation that lets one consumer (e.g. authelia on prime)
# see facts emitted by many producers (e.g. every person's service-access
# quirk, every host's mesh-device quirk).
#
# Three quirks (currently mesh-device + principal only — service-access
# moved to entity data on den.people.<name>.service-access since it's
# static registry info, not cross-entity flow):
#   - mesh-device:  per-host (each NixOS host declares its own wg peer
#                   facts). Consumed by mesh-server (peer list) and
#                   mesh-client (server entry).
#   - principal:    per-person (identity + devices). Consumed by
#                   mesh-firewall (per-device nftables rules) and
#                   nginx-whitelist (per-device allow rules).
#
# ponytail: collection is global (`pipe.collect` with `true` predicate).
# Tighten predicates when the fleet grows (e.g. only collect from hosts
# that are mesh peers, not from servers/clouds).
{ den, ... }:
let
  inherit (den.lib.policy) pipe;
in
{
  # Quirk declarations — registers keys as pipe data, not class modules.
  # Pipeline asserts these names don't collide with den.classes.
  den.quirks.mesh-device = {
    description = "Per-host mesh peer identity (ip, publicKey, allowedIPs, isServer)";
  };
  den.quirks.principal = {
    description = "Per-person identity + devices";
  };

  # Lateral: collect mesh-device across every host.
  den.policies.collect-mesh-devices = { host, ... }: [
    (pipe.from "mesh-device" [
      (pipe.collect ({ host, ... }: true))
    ])
  ];

  # Lateral: collect principal from every people scope.
  # (service-access moved to entity data — no quirk needed)
  den.policies.collect-people-facts = { host, ... }: [
    (pipe.from "principal" [
      (pipe.collect ({ people, ... }: true))
    ])
  ];

  # Synthetic: append the mesh server's mesh-device entry. The server
  # runs on a Hetzner VPS, outside the den-managed fleet, so no host
  # emits its mesh-device quirk. Inject it here — single source of truth
  # for server pubkey + endpoint, used by all mesh-client consumers.
  den.policies.append-mesh-server = { host, ... }: [
    (pipe.from "mesh-device" [
      (pipe.append {
        name = "mesh-server";
        ip = "100.67.0.1";
        publicKey = "ctHXSXda0q3R/NjILCPkWzlJzMc9ekKKpNHpe2Avyh8=";
        endpoint = "mesh.peeraten.net:51234";
        isServer = true;
      })
    ])
  ];

  # Activate for every host — every host sees the full pool, consumers
  # filter/transform what they need.
  den.schema.host.includes = [
    den.policies.collect-mesh-devices
    den.policies.collect-people-facts
    den.policies.append-mesh-server
  ];
}
