# Mesh firewall aspect — nftables forward rules per device.
#
# Consumer of `den.people.<name>.devices` + `.service-access`. Generates
# nftables rules that:
#   - ACCEPT traffic from each person's device to CIDRs they're
#     explicitly granted via `service-access` + the service's
#     `networks` (mesh networks like "home" / "nas")
#   - DROP the rest of the LAN for that device
#
# Today's equivalent lives in nix/hosts/mentat/modules/mesh.nix and
# reads `services.mesh.people` × `services.mesh.networks` directly.
# That code stays for now (transitional) and will be replaced by this
# consumer once mesh.nix moves to modules/hosts/mentat/mesh.nix.
#
# ponytail: per-device rule generation is O(devices × grants). Fine
# for ~30 devices. If the mesh grows, aggregate by subnet first.
{ config, ... }:
let
  topLevelConfig = config;
in
{
  den.aspects.server.mesh-firewall = {
    nixos =
      { lib, ... }:
      let
        lanSubnet = "192.168.100.0/24";

        # Flatten all persons' service-access into tagged list.
        allAccess = lib.concatLists (
          lib.mapAttrsToList (
            person: p:
            map (svc: {
              inherit person;
              service = svc;
            }) p.service-access
          ) topLevelConfig.den.people
        );

        # For each person × device, decide which CIDRs they can reach.
        # Currently: full LAN access for everyone (placeholder). Tighten
        # when service-access grows network-grant entries.
        rulesForDevice =
          personName: deviceName: device:
          let
            cidrs = [ lanSubnet ]; # ponytail: derive from grants
            acceptLines = lib.concatMapStrings (cidr: ''
              ip saddr ${device.ip} ip daddr ${cidr} accept comment "${personName}-${deviceName} -> ${cidr}"
            '') cidrs;
            dropLine = ''
              ip saddr ${device.ip} ip daddr ${lanSubnet} drop comment "${personName}-${deviceName}: default deny LAN"
            '';
          in
          acceptLines + dropLine;

        allDevices = lib.concatLists (
          lib.mapAttrsToList (
            personName: person:
            lib.mapAttrsToList (deviceName: device: rulesForDevice personName deviceName device) person.devices
          ) topLevelConfig.den.people
        );
      in
      {
        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = 1;
          "net.ipv6.conf.all.forwarding" = 1;
        };

        networking.nftables.tables.wireguard-forward = {
          family = "ip";
          content = ''
            chain forward {
              type filter hook forward priority filter; policy accept;
              ${lib.concatStrings allDevices}
            }
          '';
        };
      };
  };
}
